# 08 — AKS + ACR + CI/CD Infrastructure via Terraform

Full cloud-native CI/CD infrastructure deployed using Terraform. No manual clicks. Everything as code.

---

## What This Project Does

Deploys a complete Azure Kubernetes Service (AKS) infrastructure including:

- **AKS Cluster** — Kubernetes cluster in Spain Central
- **Azure Container Registry (ACR)** — Stores Docker images
- **Agent VM** — Self-hosted Azure DevOps agent for CI/CD
- **Networking** — VNet, subnets, NSG, public IPs
- **RBAC** — AKS pulling images from ACR via Managed Identity

---

## Architecture

```
Developer pushes code
        ↓
Azure DevOps Pipeline (self-hosted agent on VM)
        ↓
Build Docker image → Push to ACR (votingappacr0001)
        ↓
Update Kubernetes manifest (update-manifest.sh)
        ↓
ArgoCD detects change → Syncs to AKS
        ↓
Vote app running at http://EXTERNAL-IP:8080
```

---

## Infrastructure Diagram

```
Resource Group: votingapp-rg
│
├── VNet (10.0.0.0/16)
│   ├── Agent Subnet (10.0.1.0/24)
│   │   ├── Network Interface
│   │   ├── NSG (allow SSH 22, HTTP 80, HTTPS 443)
│   │   └── Azure VM (votingapp-vm) ← Azure DevOps Agent
│   │       └── Public IP (68.221.68.166)
│   │
│   └── AKS Subnet (10.0.2.0/24)
│       └── AKS Cluster (votingapp-aks)
│           ├── vote service     → LoadBalancer (public IP)
│           ├── result service   → LoadBalancer
│           ├── worker service   → ClusterIP
│           ├── db (postgres)    → ClusterIP
│           ├── redis            → ClusterIP
│           └── ArgoCD           → LoadBalancer
│
└── Azure Container Registry (votingappacr0001)
    ├── votingapp     (vote image)
    └── workerservice (worker image)

Remote Backend: tfstate-backup-rg → newsta8996 → tfstate container
```

---

## File Structure

```
08-Terraform-AKS/
├── backend.tf       ← Terraform providers + remote state backend
├── variables.tf     ← All variable definitions with types
├── terraform.tfvars ← Variable values (not committed to git)
├── locals.tf        ← Resource names built from prefix
├── main.tf          ← All Azure resources
├── outputs.tf       ← Outputs: public IPs, ACR URL, kubeconfig
└── README.md
```

---

## Resources Created by Terraform

| Resource | Name | Purpose |
|---|---|---|
| Resource Group | `votingapp-rg` | Container for all resources |
| Virtual Network | `votingapp-vnet` | Network for AKS and VM |
| Agent Subnet | `votingapp-agent-subnet` | Subnet for DevOps agent VM |
| AKS Subnet | `votingapp-aks-subnet` | Subnet for AKS nodes |
| Public IP | `votingapp-public-ip` | Public IP for agent VM |
| NSG | `votingapp-nsg` | Firewall rules (SSH, HTTP, HTTPS) |
| Network Interface | `votingapp-nic` | NIC for agent VM |
| Linux VM | `votingapp-vm` | Self-hosted Azure DevOps agent |
| Container Registry | `votingappacr0001` | Stores Docker images |
| AKS Cluster | `votingapp-aks` | Kubernetes cluster |
| Role Assignment | AcrPull | AKS can pull images from ACR |

---

## Step by Step — Deploy This Infrastructure

### Prerequisites
- Azure CLI installed and logged in (`az login`)
- Terraform >= 1.9.0
- Active Azure subscription
- Azure DevOps organization

---

### Step 1 — Login to Azure

```bash
az login
```

---

### Step 2 — Create Service Principal

```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

Save the output — you need `appId`, `password`, and `tenant`.

---

### Step 3 — Export Credentials

```bash
export ARM_CLIENT_ID="your appId"
export ARM_CLIENT_SECRET="your password"
export ARM_TENANT_ID="your tenant"
export ARM_SUBSCRIPTION_ID="your subscription id"
```

To make permanent:
```bash
echo 'export ARM_CLIENT_ID="your appId"' >> ~/.bashrc
echo 'export ARM_CLIENT_SECRET="your password"' >> ~/.bashrc
echo 'export ARM_TENANT_ID="your tenant"' >> ~/.bashrc
echo 'export ARM_SUBSCRIPTION_ID="your subscription id"' >> ~/.bashrc
source ~/.bashrc
```

---

### Step 4 — Create Backend Storage

```bash
bash setup-backend.sh
```

Copy the printed storage account name into `backend.tf`.

---

### Step 5 — Create `terraform.tfvars`

```hcl
prefix                       = "votingapp"
location                     = "Spain Central"
vnet_address_space           = ["10.0.0.0/16"]
subnet_address_space         = ["10.0.1.0/24"]
aks_subnet_address_space     = ["10.0.2.0/24"]
admin_username               = "azureuser"
admin_password               = "YourSecurePassword!"
vm_size                      = "Standard_B1s"
acr_sku                      = "Basic"
aks_node_count               = 1
aks_node_vm_size             = "Standard_B2s_v2"
os_disk_caching              = "ReadWrite"
os_disk_storage_account_type = "Standard_LRS"

tags = {
  Environment = "Staging"
  Owner       = "Asadul"
  Project     = "AKS-CICD"
}
```

---

### Step 6 — Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

This takes **8-12 minutes** — AKS cluster creation takes the longest.

---

### Step 7 — Connect kubectl to AKS

```bash
az aks get-credentials \
  --resource-group votingapp-rg \
  --name votingapp-aks

kubectl get nodes
```

---

### Step 8 — Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD
kubectl patch svc argocd-server \
  -n argocd \
  -p '{"spec": {"type": "LoadBalancer"}}'

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

---

### Step 9 — Set Up Azure DevOps Agent on VM

SSH into the VM:
```bash
ssh azureuser@VM_PUBLIC_IP
```

Install agent:
```bash
mkdir myagent && cd myagent
wget https://vstsagentpackage.azureedge.net/agent/3.x.x/vsts-agent-linux-x64-3.x.x.tar.gz
tar zxvf vsts-agent-linux-x64-3.x.x.tar.gz
./config.sh
./run.sh
```

---

### Step 10 — Assign AcrPull Role to AKS

```bash
KUBELET_ID=$(az aks show \
  --name votingapp-aks \
  --resource-group votingapp-rg \
  --query identityProfile.kubeletidentity.objectId -o tsv)

ACR_ID=$(az acr show \
  --name votingappacr0001 \
  --query id -o tsv)

az role assignment create \
  --assignee $KUBELET_ID \
  --role AcrPull \
  --scope $ACR_ID
```

---

### Step 11 — Clean Up

```bash
terraform destroy
```

---

## Errors I Hit and Fixed

| Error | Cause | Fix |
|---|---|---|
| `Standard_DS2_v2 not allowed` | VM size not available in Spain Central | Changed to `Standard_B2s_v2` |
| `ServiceCidrOverlapExistingSubnetsCidr` | Service CIDR overlapped with VNet | Added `service_cidr = "10.2.0.0/16"` |
| `PublicIPCountLimitReached` | Free tier limit of 3 public IPs | Removed ArgoCD public IP temporarily |
| `ImagePullBackOff` | AcrPull role on wrong identity | Assigned role to kubelet identity |
| CRLF line endings in shell script | Windows line endings in `.sh` file | Added `.gitattributes` with `*.sh eol=lf` |
| ACR name taken | `votingappacr` already exists globally | Added `0001` suffix |

---

## Production Improvements

For a production deployment the following would be added:

- **NGINX Ingress Controller** — single LoadBalancer for all services (cost efficient)
- **cert-manager** — automatic TLS/HTTPS certificates
- **Private AKS nodes** — no public IPs on nodes (more secure)
- **Azure Key Vault** — secrets management instead of environment variables
- **Horizontal Pod Autoscaler** — auto-scale pods based on load
- **Multiple node pools** — separate pools for different workloads

---

## Key Learnings

- AKS nodes should always be private in production — use NGINX Ingress for external access
- AcrPull role must be assigned to `kubelet_identity` not `cluster identity`
- Service CIDR must not overlap with VNet address space
- Remote backend state must use a different `key` for each Terraform project
- `terraform.tfvars` must never be committed to Git

---

## Stack

![Terraform](https://img.shields.io/badge/Terraform-1.9+-623CE4?style=flat&logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=flat&logo=microsoftazure)
![Kubernetes](https://img.shields.io/badge/Kubernetes-AKS-326CE5?style=flat&logo=kubernetes)
![Docker](https://img.shields.io/badge/Docker-Container-2496ED?style=flat&logo=docker)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?style=flat&logo=argo)
![Azure DevOps](https://img.shields.io/badge/Azure_DevOps-CI/CD-0078D7?style=flat&logo=azuredevops)

---

## Author

**Md Asadul Howlader**
Junior Azure DevOps Engineer (in progress)
[GitHub](https://github.com/AsadulCloud) • [LinkedIn](https://www.linkedin.com/in/asadul-howlader)
