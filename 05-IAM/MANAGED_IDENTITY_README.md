# Azure VM + Managed Identity + Blob Storage

Access Azure Blob Storage from a VM using Managed Identity — no passwords, no keys, no secrets.

---

## What This Project Does

- Deploys an Azure VM with a **Public IP** so you can SSH into it
- Enables **System-Assigned Managed Identity** on the VM
- Stores an HTML file in **Azure Blob Storage**
- VM reads the HTML file using its identity — **zero credentials needed**

---

## Architecture

```
Resource Group: demo-resources
│
├── VNet (10.0.0.0/8)
│   └── Subnet (10.0.2.0/24)
│       ├── NIC (Private IP + Public IP)
│       ├── NSG (Allow SSH port 22)
│       └── VM (Standard_B1s · Ubuntu 22.04)
│           └── System-Assigned Managed Identity
│
├── Storage Account (lisbonbdstorage · LRS)
│   └── Container: portfolio
│       └── index.html
│
└── Remote Backend Storage (newsta3071)
    └── Container: tfstate
        └── dev.terraform.tfstate

Azure Active Directory
└── RBAC: Storage Blob Data Reader → VM Identity
```

---

## Files

```
07-Terraform/
├── main.tf          ← all Azure resources + public IP + managed identity
├── variables.tf     ← variable definitions
├── backend.tf       ← remote state config
├── outputs.tf       ← prints public IP after apply
├── setup-backend.sh ← creates backend storage via Azure CLI
├── index.html       ← HTML file to upload to blob storage
└── README.md
```

---

## Step by Step

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

### Step 5 — Initialize and Deploy

```bash
terraform init
terraform apply
```

After apply you will see:

```
Outputs:
public_ip      = "20.x.x.x"
vm_name        = "demo-vm"
resource_group = "demo-resources"
storage_account = "lisbonbdstorage"
```

---

### Step 6 — Create Blob Container

```bash
az storage container create \
  --name portfolio \
  --account-name lisbonbdstorage \
  --auth-mode login
```

---

### Step 7 — Upload HTML File

```bash
az storage blob upload \
  --account-name lisbonbdstorage \
  --container-name portfolio \
  --name index.html \
  --file index.html \
  --auth-mode login
```

---

### Step 8 — Assign Managed Identity Role

```bash
# Get VM identity principal ID
PRINCIPAL_ID=$(az vm show \
  --name demo-vm \
  --resource-group demo-resources \
  --query identity.principalId -o tsv)

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign Storage Blob Data Reader role
az role assignment create \
  --assignee $PRINCIPAL_ID \
  --role "Storage Blob Data Reader" \
  --scope /subscriptions/$SUBSCRIPTION_ID
```

---

### Step 9 — SSH into VM

```bash
ssh testadmin@YOUR_PUBLIC_IP
```

Use the IP from Step 5 output.

---

### Step 10 — Access Blob from VM Using Managed Identity

Run these commands **inside the VM** after SSH:

```bash
# Get access token using Managed Identity
TOKEN=$(curl -s \
  "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" \
  -H "Metadata:true" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

# Fetch the HTML file from blob storage
curl -s \
  -H "Authorization: Bearer $TOKEN" \
  -H "x-ms-version: 2020-04-08" \
  "https://lisbonbdstorage.blob.core.windows.net/portfolio/index.html"
```

You will see the HTML content printed in your terminal — **accessed with zero passwords or keys**.

---

### Step 11 — Clean Up

```bash
terraform destroy
```

---

## Why Managed Identity?

| Method | Secret needed? | Risk |
|---|---|---|
| Storage Account Key | Yes | Key can be leaked |
| SAS Token | Yes | Token can expire or be stolen |
| Managed Identity | ❌ No | No secret exists to steal |

Managed Identity is the **most secure** way to access Azure resources from a VM. Azure handles the token automatically — you never see or store a credential.

---

## Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `AuthorizationFailed` | Role not assigned yet | Run Step 8 |
| `BlobNotFound` | File not uploaded | Run Step 7 |
| `invalid_resource` | Wrong resource URL in token request | Use `https://storage.azure.com/` |
| SSH timeout | NSG missing | Check NSG allows port 22 |
| No public IP in output | Missing `outputs.tf` | Add outputs.tf and re-apply |

---

## Stack

![Terraform](https://img.shields.io/badge/Terraform-1.9+-623CE4?style=flat&logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?style=flat&logo=microsoftazure)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?style=flat&logo=ubuntu)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat&logo=gnubash)

---

## Author

**Md Asadul Howlader**
Junior Azure DevOps Engineer (in progress)
[GitHub](https://github.com/AsadulCloud) • [LinkedIn](https://www.linkedin.com/in/asadul-howlader)
