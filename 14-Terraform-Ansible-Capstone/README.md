# Terraform + Ansible Capstone: Automated VM Provisioning and Configuration

A single Azure DevOps pipeline that provisions a Linux VM with Terraform, then automatically configures it with Ansible — with zero manual steps, zero copy-pasted IP addresses, and zero hardcoded credentials.

---

## What this project demonstrates

The core technical challenge: **Terraform** creates infrastructure and only knows a VM's IP address *after* it's created. **Ansible** configures software on a machine and needs that IP address *before* it can connect. This project bridges that gap entirely inside one automated pipeline run.

```
Terraform provisions VM  →  pipeline captures IP + SSH key
    →  SSH-ready retry loop confirms VM is reachable
    →  dynamic Ansible inventory generated automatically
    →  Ansible installs and configures nginx
    →  pipeline curls the VM externally to prove it worked
```

No human ever touches or copies an IP address between these steps.

---

## Architecture

### Pipeline flow

```
GitHub push (main branch)
        │
        ▼
Terraform init + apply  ──────►  provisions Azure VM + networking
        │
        ▼
Capture outputs  ─────────────►  VM_IP + SSH private key
        │
        ▼
SSH-ready retry loop  ─────────►  waits for port 22, not a blind sleep
        │
        ▼
Generate dynamic inventory  ───►  writes inventory.ini with real IP
        │
        ▼
Ansible playbook  ─────────────►  installs nginx, opens firewall port 80
        │
        ▼
Curl verification  ────────────►  confirms nginx reachable from outside
```

### Azure infrastructure created

```
Resource Group: capstone-rg
│
├── Virtual Network (10.0.0.0/16)
│   └── Subnet (10.0.1.0/24)
│
├── Network Security Group
│   ├── Allow inbound 22 (SSH)
│   └── Allow inbound 80 (HTTP)
│
├── Network Interface + Static Public IP
│
└── Linux VM (capstone-vm)
    └── Ubuntu 22.04, nginx installed by Ansible

Remote state (separate, outside capstone-rg):
Resource Group: tfstate-rg
└── Storage Account → Container → dev.terraform.tfstate
```

State is stored remotely (not locally on the pipeline agent) because Microsoft-hosted agents are disposable — they're wiped after every run. A local state file would vanish along with the agent, causing Terraform to "forget" the VM ever existed on the next run and attempt to create a duplicate.

---

## Project structure

```
14-Terraform-Ansible-Capstone/
├── azure-pipelines-capstone.yml   # the pipeline tying everything together
├── terraform/
│   ├── main.tf                    # VM, networking, NSG, SSH key generation
│   ├── variables.tf                # configurable values (region, VM size, etc.)
│   ├── outputs.tf                  # exposes vm_public_ip and ssh_private_key
│   └── backend.tf                  # remote state configuration (empty block -
│                                    #   values injected by the pipeline at init time)
├── ansible/
│   ├── site.yml                    # installs nginx, opens firewall ports
│   └── ansible.cfg                 # disables host-key checking for automation
├── README.md                       # this file
└── DEBUGGING.md                    # the real troubleshooting journey
```

---

## Key design decisions

**Terraform generates its own SSH key pair.** Using the `tls_private_key` resource means no manual key management — a fresh key pair is minted on every `apply`, and the private key is exposed as a sensitive Terraform output for the pipeline to capture.

**No Terraform Marketplace extension dependency.** Rather than relying on `TerraformInstaller@1`/`TerraformTaskV4@4` (which require an organization admin to install a separate extension), Terraform is installed via a plain `curl`/`unzip` script and run through the built-in `AzureCLI@2` task. This removes an entire category of "will this even be installed" risk.

**OIDC / Workload Identity Federation authentication**, not a stored client secret. The service connection uses federated, short-lived tokens rather than a long-lived password — more secure, and the modern recommended approach for CI/CD-to-Azure authentication.

**A real SSH-readiness check, not a fixed sleep.** Instead of guessing "the VM is probably ready after 45 seconds," the pipeline actually attempts a TCP connection to port 22 in a retry loop — moving on the instant the VM responds, and failing loudly (not silently) if it never comes up within a sane timeout.

**Firewall rules opened at two layers, both automated.** The Azure Network Security Group (cloud-level firewall) allows ports 22 and 80, and the Ansible playbook also explicitly opens the same ports in the VM's own UFW firewall — both layers have to agree for traffic to actually get through, and both are handled automatically now, not manually.

---

## Prerequisites before running this pipeline

1. **An Azure subscription** with these resource providers registered: `Microsoft.Storage`, `Microsoft.Compute`, `Microsoft.Network`, `Microsoft.Resources`.
2. **A remote state storage account created manually, once** (Terraform can't create its own home before it starts):
   ```bash
   az group create --name tfstate-rg --location eastus
   az storage account create --name <your-unique-name> --resource-group tfstate-rg --sku Standard_LRS --encryption-services blob
   az storage container create --name tfstatecapstone --account-name <your-unique-name> --auth-mode login
   ```
3. **An Azure DevOps service connection** (Azure Resource Manager type, Workload Identity Federation) pointing at that subscription.
4. **`main.tf`'s `backend "azurerm" {}` block** filled in with your actual resource group / storage account / container / key names (or left empty and passed via `-backend-config` flags in the pipeline).
5. Update `azureServiceConnection` in `azure-pipelines-capstone.yml` to match your service connection's exact name.

---

## Running it

Push this folder to a repo connected to Azure DevOps, create a new pipeline pointing at `azure-pipelines-capstone.yml`, and run it. Expect roughly 3-5 minutes end to end. The final step's output should show nginx's default HTML welcome page, confirming the entire chain worked.

---

## What broke and how it was fixed

See **[DEBUGGING.md](./DEBUGGING.md)** for the complete, real troubleshooting journey — every error message hit, why it happened, and exactly how it was diagnosed and resolved. It's a genuinely useful read for anyone doing similar Terraform + Ansible + Azure DevOps work, since none of these were contrived teaching examples — they were real production-style bugs.
