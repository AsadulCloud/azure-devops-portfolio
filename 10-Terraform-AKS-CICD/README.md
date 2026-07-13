# AKS CI/CD Portfolio Project (10-Terraform-AKS-CICD)

A Node.js app, provisioned entirely with Terraform (VNet, AKS, ACR, RBAC),
deployed automatically via an Azure DevOps CI/CD pipeline.

> **Builds on earlier work in this portfolio:**
> - `06-CI-CD-Pipelines` — first hands-on Azure DevOps pipeline (manually created AKS/ACR)
> - `08-Terraform-AKS` — Terraform used to provision AKS + ACR for the first time
> - `09-Docker` — Dockerfile fundamentals, single-stage vs multi-stage builds
>
> This project combines all three: **Terraform-managed infrastructure** (not manual portal clicks)
> feeding into a **fully automated CI/CD pipeline**, rather than provisioning infra once and
> deploying manually.

## Project structure

```
aks-cicd-project/
├── terraform/          # Infrastructure as Code - provisions everything
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── app/                 # The Node.js application + its Dockerfile
│   ├── app.js
│   ├── package.json
│   ├── Dockerfile
│   └── .dockerignore
├── k8s/                 # Kubernetes manifests (deployment + service)
│   ├── deployment.yaml
│   └── service.yaml
└── azure-pipelines.yml  # CI/CD pipeline definition
```

---

## Step 1 — Create a storage account for Terraform remote state

Terraform needs somewhere to store its state file. Do this once, manually,
before running `terraform init`:

```bash
az group create --name tfstate-rg --location "West Europe"

az storage account create \
  --name tfstateasadul001 \
  --resource-group tfstate-rg \
  --sku Standard_LRS \
  --encryption-services blob

az storage container create \
  --name tfstate \
  --account-name tfstateasadul001
```

> Storage account names must be globally unique. If `tfstateasadul001` is
> taken, change it here AND in `terraform/providers.tf`.

---

## Step 2 — Provision infrastructure with Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars if you want to change names/sizes

terraform init
terraform plan
terraform apply
```

This creates:
- A resource group
- A VNet + subnet
- An Azure Container Registry (ACR)
- An AKS cluster
- A role assignment granting AKS permission to pull images from ACR

When it finishes, note the outputs:
```bash
terraform output acr_login_server
terraform output aks_cluster_name
```

---

## Step 3 — Set up Azure DevOps

1. **Create a new Azure DevOps project** and push this repo to it.
2. **Create an Azure Resource Manager service connection**
   (Project Settings → Service connections → New → Azure Resource Manager)
   — this lets the pipeline authenticate to your subscription.
3. **Create a Docker Registry service connection** pointing at your ACR
   (Project Settings → Service connections → New → Docker Registry → Azure Container Registry).
4. **Update `azure-pipelines.yml`** — fill in the real names for:
   - `azureSubscription`
   - `acrName`
   - `acrLoginServer`
   - `aksClusterName`
   - `aksResourceGroup`
   (these should match your Terraform outputs)
5. **Create a new pipeline** in Azure DevOps pointing at `azure-pipelines.yml`.

---

## Step 4 — Push to `main` and watch it deploy

Every push to `main` will:
1. **Build stage** — build the Docker image from `app/Dockerfile` and push it to ACR, tagged with the pipeline's build ID and `latest`.
2. **Deploy stage** — fetch AKS credentials, replace the placeholder image tag in `k8s/deployment.yaml` with the real ACR image, then apply both manifests to the cluster.

Check rollout status:
```bash
kubectl get pods
kubectl get service aks-cicd-app-service
```

The `EXTERNAL-IP` shown for the service is where your app is publicly reachable.

---

## Why these design choices (talking points for interviews)

- **`admin_enabled = false` on ACR** — access is via AKS's managed identity + RBAC role assignment, not a shared username/password. More secure, no credentials to leak or rotate.
- **Remote Terraform state in Azure Storage** — enables team collaboration and prevents state loss/corruption from working only on a local machine.
- **Image tagged with `$(Build.BuildId)`, not just `latest`** — every deployment is traceable to an exact pipeline run, and rollbacks are possible by redeploying a specific prior tag.
- **Readiness/liveness probes** — Kubernetes only routes traffic to pods once they're actually ready, and restarts pods that become unhealthy.
- **Two-stage pipeline (Build → Deploy)** — mirrors real CI/CD separation of concerns; the Build stage produces an artifact (the image), the Deploy stage consumes it.

---

## Cleanup (avoid ongoing Azure costs)

```bash
cd terraform
terraform destroy
```
