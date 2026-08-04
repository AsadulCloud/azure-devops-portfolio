# Debugging Log: Terraform + Ansible Capstone

This is a real record of every issue hit while building and running this pipeline, in the order they occurred, with root cause and fix for each. Nothing here is a contrived teaching example — every issue below actually broke a real pipeline run and had to be diagnosed from actual error output.

---

## 1. Bash line-continuation bug breaking `terraform init`

**Symptom:**
```
Error: Too many command line arguments. Did you mean to use -chdir?
```

**Root cause:** A stray trailing backslash after `terraform init \` caused bash to treat `terraform init` and `terraform apply -auto-approve` as one single command, with `terraform`, `apply`, and `-auto-approve` all being passed as unexpected positional arguments to `init`.

**Fix:** Removed the backslash so each command runs as its own line:
```yaml
terraform init
terraform apply -auto-approve
```

---

## 2. Terraform Marketplace extension dependency risk

**Symptom (anticipated, not yet hit):** `TerraformInstaller@1` and `TerraformTaskV4@4` require the "Terraform" extension by Microsoft DevLabs to be installed at the Azure DevOps organization level — something not guaranteed to exist, and requiring Organization Admin rights to install.

**Fix:** Replaced both tasks with a plain script (`curl`/`unzip` to install Terraform directly) and the built-in `AzureCLI@2` task to run `terraform init`/`apply` as CLI commands. Removed an entire category of "will this even be installed" risk, and made the pipeline portable to any CI system, not just Azure DevOps with a specific extension.

---

## 3. First OIDC/service-principal auth mismatch

**Symptom:**
```
Error: Error building ARM Config: Authenticating using the Azure CLI is only 
supported as a User (not a Service Principal).
```

**Root cause:** `main.tf`'s provider block had `use_cli = true`, which only works when `az` is logged in as a human user account. The Azure DevOps service connection authenticates as a **service principal** via Workload Identity Federation (confirmed by `az login --service-principal ... --federated-token` in the logs) — `use_cli` explicitly refuses to work with service principals.

**Fix:** Changed the provider to `use_oidc = true`, and updated the pipeline to explicitly export the OIDC credentials:
```bash
export ARM_CLIENT_ID=$servicePrincipalId
export ARM_TENANT_ID=$tenantId
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
export ARM_USE_OIDC=true
export ARM_OIDC_TOKEN=$idToken
```

---

## 4. Remote backend container not found

**Symptom:**
```
Error: Failed to get existing workspaces: ... Status=404 Code="ContainerNotFound"
```

**Root cause:** Auth was now working correctly, but the blob container referenced in the backend config didn't actually exist yet in the storage account — it has to be created manually, once, before Terraform's first run (Terraform can't create its own home before it starts).

**Fix:**
```bash
az storage container create --name tfstatecapstone --account-name <account> --auth-mode login
```

---

## 5. Public IP quota limit hit across regions

**Symptom:**
```
Error: ... PublicIPCountLimitReached: Cannot create more than 3 public IP 
addresses for this subscription in this region.
```

**Root cause:** The subscription had a hard cap of 3 public IPs per region, and `spaincentral` (the target region) already had 3 in use from other projects (a leftover demo VM and two AKS LoadBalancer Services).

**Fix:** Since the Resource Group's own location and the Terraform state storage account's location don't need to match the VM's networking region, the simplest fix was switching `var.location` to a region with spare IP quota (`polandcentral`), rather than deleting existing resources.

**Lesson:** Only VNet, Subnet, NIC, Public IP, and VM need to share the same region as each other. The Resource Group and the remote state storage account can be in any region independently.

---

## 6. Terraform state/replacement-detection gap after region change

**Symptom:**
```
Error: creating Network Interface ... InvalidResourceReference: Resource 
.../virtualNetworks/capstone-vnet/subnets/capstone-subnet ... was not found.
```

**Root cause:** After changing the VM's region, Terraform destroyed and recreated the VNet (since `location` changed), but the subnet resource referenced the VNet by its **name** (a string that didn't change), so Terraform's plan didn't detect that the subnet's real parent had actually been replaced. The subnet was destroyed along with the old VNet in Azure, but Terraform's state still believed it existed.

**Fix:** Forced explicit recreation of the affected resource:
```bash
terraform apply -auto-approve -replace="azurerm_subnet.subnet"
```

**Lesson:** This is a known AzureRM provider quirk with resources that reference parents by name rather than ID. For actively-iterated infrastructure, a full `terraform destroy` + `apply` is often simpler than chasing individual `-replace` fixes.

---

## 7. Git credential chaos: embedded token in remote URL

**Symptom:** `git push` failed with `Invalid username or token` even after generating fresh Personal Access Tokens and correctly configuring `credential.helper store`.

**Root cause:** A diagnostic command from earlier in the session (`git push https://<TOKEN>@github.com/...`) had the side effect of Git permanently saving that full URL — **including the token** — as the `origin` remote. Once a remote URL contains embedded credentials, Git always uses them first and never consults the credential helper at all. Every subsequent fix attempt was correctly configuring a credential store that Git was never actually checking.

**Fix:**
```bash
git remote set-url origin https://github.com/<user>/<repo>.git
```
This stripped the embedded token, forcing Git to fall back to the properly configured `store` helper.

**Lesson:** Never leave a token embedded in a remote URL, even temporarily for diagnostics — always reset the URL immediately afterward. Also: immediately revoke any token that gets pasted in plain text anywhere, including chat logs.

---

## 8. Expired subscription requiring migration

**Symptom:**
```
(SubscriptionNotFound) Subscription '...' was not found.
```

**Root cause:** The original Azure subscription genuinely expired mid-project. `az account list` continued to show it as "Enabled" due to local CLI caching, even though Azure's actual backend rejected every request against it.

**Fix:** Logged into a new/reactivated subscription, updated the Terraform backend configuration and Azure DevOps service connection to point at the new subscription ID and tenant.

**Lesson:** When the Portal and CLI disagree about a subscription's state, the Portal is authoritative — check it directly rather than trusting cached CLI output.

---

## 9. Resource provider not registered on new subscription

**Symptom:** Same `SubscriptionNotFound`-style rejection persisted even after confirming the subscription showed "Active" in the Portal.

**Root cause:**
```bash
az provider show --namespace Microsoft.Storage --query "registrationState" -o tsv
# → NotRegistered
```
Brand-new subscriptions don't automatically have all resource providers registered — `Microsoft.Storage` (and by extension `Microsoft.Compute`, `Microsoft.Network`) needed explicit registration before any resources in those categories could be created.

**Fix:**
```bash
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Resources
```

---

## 10. Microsoft Entra Security Defaults blocking device-code login

**Symptom:**
```
AADSTS530035: Access has been blocked by security defaults.
```

**Root cause:** Every new Microsoft Entra ID tenant has "Security Defaults" enabled automatically, which blocks certain legacy/risky authentication flows — including the device-code flow used by `az login` in a browser-less terminal environment.

**Fix:** Portal → Microsoft Entra ID → Properties → Manage security defaults → set to Disabled (acceptable for a personal learning subscription; not recommended for real organizational tenants).

---

## 11. WSL/Windows filesystem SSH key permission bug

**Symptom:**
```
Permissions 0777 for 'capstone_key.pem' are too open.
This private key will be ignored.
Permission denied (publickey).
```

**Root cause:** The key file lived on a Windows-mounted path inside WSL (`/mnt/d/...`). NTFS mounts don't support real Unix file permission bits, so `chmod 600` silently had no effect — the file remained effectively world-readable, and SSH refused to use it as a security precaution.

**Fix:** Copied the key into WSL's native Linux filesystem (`~/.ssh/`) before running `chmod`, where permission bits actually apply.

---

## 12. Silent no-op Ansible run from a one-character typo

**Symptom:** The "Configure VM with Ansible" pipeline step showed **green/succeeded**, but nginx was never actually installed on the VM.

**Root cause:**
```
[WARNING]: Could not match supplied host pattern, ignoring: webserver
skipping: no hosts matched
```
The playbook's `hosts:` value was `webserver` (singular), but the generated inventory's group was `[webservers]` (plural). Ansible silently skips the entire play when no hosts match a pattern — and exits with code 0 (success), so the pipeline reported a false positive.

**Fix:** Corrected `hosts: webserver` → `hosts: webservers` in `site.yml` to exactly match the inventory group name.

**Lesson:** A "successful" pipeline step doesn't guarantee the intended work actually happened — always verify against real evidence (in this case, actually checking whether nginx was installed on the VM), not just the pipeline's green checkmark.

---

## 13. UFW blocking port 80 despite correct NSG rules

**Symptom:**
```
curl: (7) Failed to connect to <ip> port 80 after 21 ms: Couldn't connect to server
```
...even though the Azure NSG rule for port 80 was confirmed correctly configured and attached.

**Root cause:** Two separate firewall layers exist: Azure's Network Security Group (cloud-level) and Ubuntu's own UFW (VM-level). Both have to allow a port for traffic to actually get through. The NSG was correct, but nothing had explicitly opened port 80 in UFW on the VM itself.

**Fix:** Added explicit UFW rules to the Ansible playbook itself, so this is handled automatically on every run rather than requiring manual SSH intervention:
```yaml
- name: Ensure UFW allows HTTP
  ufw:
    rule: allow
    port: '80'
    proto: tcp
```

---

## Summary: the shape of these bugs

Almost none of these were "the code is wrong" bugs in the traditional sense. They were, in order: a syntax slip, a dependency risk, two auth-model mismatches, a missing manual setup step, a quota limit, a state-tracking edge case, a credential-hygiene mistake, an expired external resource, a provider-registration gap, a security policy default, a filesystem quirk, a naming mismatch that failed silently, and a two-layer firewall gap.

This is genuinely representative of real infrastructure engineering — most production incidents aren't algorithm bugs, they're environment, configuration, timing, and assumption mismatches. Debugging this capstone end-to-end is a legitimate demonstration of that skill.
