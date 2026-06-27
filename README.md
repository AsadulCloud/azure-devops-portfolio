# Terraform on Azure — VM Deployment with Remote Backend

Built and debugged from scratch. No shortcuts.

---

## What This Project Does

Deploys a full Azure infrastructure using Terraform:

- Resource Group
- Virtual Network + Subnet
- Network Interface
- Ubuntu 22.04 VM (Spain Central)
- Storage Account

Terraform state is stored remotely in Azure Blob Storage — not locally.

---

## Folder Structure

```
terraform/
├── main.tf            ← all Azure resources
├── variables.tf       ← variable definitions
├── backend.tf         ← terraform block, backend, provider
├── setup-backend.sh   ← bash script to create backend storage
└── README.md
```

---

## Step by Step — Run This Project

### Step 1 — Login to Azure

```bash
az login
```

---

### Step 2 — Create a Service Principal

Terraform needs a Service Principal to authenticate with Azure.

```bash
az ad sp create-for-rbac \
  --name "terraform-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

You will get output like this:

```json
{
  "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "displayName": "terraform-sp",
  "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

Save these values — you need them in the next step.

---

### Step 3 — Export SP Credentials

```bash
export ARM_CLIENT_ID="your appId"
export ARM_CLIENT_SECRET="your password"
export ARM_TENANT_ID="your tenant"
export ARM_SUBSCRIPTION_ID="your subscription id"
```

To make these permanent so you don't have to run them every time:

```bash
echo 'export ARM_CLIENT_ID="your appId"' >> ~/.bashrc
echo 'export ARM_CLIENT_SECRET="your password"' >> ~/.bashrc
echo 'export ARM_TENANT_ID="your tenant"' >> ~/.bashrc
echo 'export ARM_SUBSCRIPTION_ID="your subscription id"' >> ~/.bashrc
source ~/.bashrc
```

---

### Step 4 — Create Backend Storage

Backend storage must exist before running `terraform init`.
Run the bash script to create it automatically:

```bash
bash setup-backend.sh
```

The script will print the storage account name at the end:

```
Done! Add this to your backend block:
storage_account_name = "newsta3071"
```

---

### Step 5 — Update backend.tf

Open `backend.tf` and update the storage account name with the value printed above:

```hcl
backend "azurerm" {
  resource_group_name  = "tfstate-backup-rg"
  storage_account_name = "newsta3071"    ← paste your value here
  container_name       = "tfstate"
  key                  = "dev.terraform.tfstate"
}
```

---

### Step 6 — Initialize Terraform

```bash
terraform init
```

This connects Terraform to the remote backend and downloads the Azure provider.

---

### Step 7 — Deploy

```bash
terraform apply
```

Type `yes` when prompted. You should see:

```
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

---

### Step 8 — Verify in Azure Portal

Go to [portal.azure.com](https://portal.azure.com) → Resource Groups → `demo-resources`

You should see all resources created.

---

### Step 9 — Clean Up

Always destroy when done to avoid charges:

```bash
terraform destroy
```

Type `yes` when prompted.

---

## Errors I Hit and Fixed

| Error | Cause | Fix |
|---|---|---|
| Subnet outside VNet range | VNet was `/32` — only 1 IP | Changed to `10.0.0.0/8` |
| `RedundancyConfigurationNotAvailableInRegion` | GRS not supported in Spain Central | Changed to `LRS` |
| `OperationNotAllowed` quota error | AKS already using 4/4 CPU cores | Switched to `Standard_B1s` |
| Only 2 resources in plan | VS Code saving to wrong folder | Opened correct folder with `File → Open Folder` |
| Backend error on `terraform init` | Storage account didn't exist yet | Run `setup-backend.sh` first |
| State missing VNet/Subnet/NIC/VM | Applied before saving full config | Ran `terraform destroy` then `terraform apply` |

---

## Two Ways to Create Azure Resources

| Method | Used For | Tool |
|---|---|---|
| Terraform | VM, VNet, Subnet, NIC, Storage Account | `main.tf` |
| Azure CLI bash script | Backend storage for tfstate | `setup-backend.sh` |

Backend storage is created with CLI because it must exist before Terraform runs.
Everything else is managed by Terraform.

---

## Prerequisites

- Azure CLI installed and logged in
- Terraform >= 1.9.0
- Active Azure subscription

---

## Stack

![Terraform](https://img.shields.io/badge/Terraform-1.9+-623CE4?style=flat&logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=flat&logo=microsoftazure)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat&logo=gnubash)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=flat&logo=ubuntu)

---

## Author

**Md Asadul Howlader**
Junior Azure DevOps Engineer (in progress)
[GitHub](https://github.com/AsadulCloud) • [LinkedIn](https://www.linkedin.com/in/asadul-howlader)
