# 06 – CI/CD Pipelines (Azure DevOps + ArgoCD + AKS)

This section documents the full CI/CD pipelines I built for the [voting-app](https://github.com/dockersamples/example-voting-app) project — a multi-service application with three services written in different languages, deployed to Kubernetes via GitOps.

---

## 🏗️ Full Pipeline Architecture

```
Developer changes app.py (or any service file)
                │
                │ git push to main
                ▼
    ┌───────────────────────────────┐
    │     Azure DevOps Pipeline     │
    │                               │
    │  Stage 1: Build               │
    │    └── docker build image     │
    │                               │
    │  Stage 2: Push                │
    │    └── push image to ACR      │
    │                               │
    │  Stage 3: Update Manifest     │
    │    └── update-manifest.sh     │
    │         └── updates image tag │
    │              in k8s YAML      │
    │              commits & pushes │
    └───────────────────────────────┘
                │
                │ manifest change detected
                ▼
         ┌─────────────┐
         │   ArgoCD    │  watches Azure Repos for manifest changes
         │  (GitOps)   │  auto-syncs when tag is updated
         └─────────────┘
                │
                │ deploy
                ▼
    ┌───────────────────────────────┐
    │       AKS Cluster             │
    │                               │
    │  vote    result    worker     │
    │  postgres          redis      │
    │                               │
    │  pods pull new image from ACR │
    └───────────────────────────────┘
```

---

## 📦 Services & Pipelines

| Service | Language | Pipeline File | Manifest File |
|---------|----------|---------------|---------------|
| vote | Python / Flask | `pipelines/vote-pipeline.yml` | `k8s/vote-deployment.yaml` |
| result | Node.js | `pipelines/result-pipeline.yml` | `k8s/result-deployment.yaml` |
| worker | .NET (C#) | `pipelines/worker-pipeline.yml` | `k8s/worker-deployment.yaml` |

---

## 🔄 How It Works – Step by Step

1. **Developer pushes a code change** (e.g. edits `vote/app.py`) to the `main` branch
2. **Azure DevOps detects the change** via the `paths` trigger in the pipeline YAML
3. **Stage 1 – Build**: Docker builds a new image with the updated code
4. **Stage 2 – Push**: The new image is pushed to Azure Container Registry (ACR) tagged with the Build ID
5. **Stage 3 – Update Manifest**: `update-manifest.sh` runs — it updates the image tag in the Kubernetes deployment YAML and pushes the change to Azure Repos
6. **ArgoCD detects the manifest change** in Azure Repos and automatically syncs
7. **AKS pulls the new image** from ACR and rolls out the updated pod

---

## 📁 Folder Structure

```
06-CI-CD-Pipelines/
├── README.md                        ← You are here
├── update-manifest.sh               ← Shell script used in Stage 3 to update k8s manifest
├── pipelines/
│   ├── vote-pipeline.yml            ← Python/Flask — 3 stages: Build, Push, Update Manifest
│   ├── result-pipeline.yml          ← Node.js — 3 stages: Build, Push, Update Manifest
│   └── worker-pipeline.yml          ← .NET — 3 stages: Build, Push, Update Manifest
└── docs/
    └── troubleshooting.md           ← Real errors I hit and how I fixed them
```

---

## ⚙️ Pipeline Trigger

Each pipeline only triggers when files in its own service folder change:

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - vote/**      # Only triggers vote-pipeline when vote/ changes
```

This means changing `result/server.js` will NOT trigger the vote pipeline — only the result pipeline.

---

## 🛠️ Infrastructure

- **Agent**: Self-hosted Azure DevOps agent on Ubuntu 24.04 Azure VM
- **Registry**: Azure Container Registry (ACR)
- **Source**: Azure Repos (Git)
- **GitOps**: ArgoCD watching the k8s manifests repo
- **Deployment**: Azure Kubernetes Service (AKS)
- **Build Engine**: Docker with BuildKit + `docker buildx` (for .NET)

---

## 🔐 Security

- ACR credentials managed via Azure DevOps service connections — never hardcoded
- Manifest repo access uses `$(System.AccessToken)` — built-in pipeline token
- No secrets in Dockerfiles, shell scripts, or YAML files

---

## 📸 Result

The app runs live on AKS — vote and result services accessible via NodePort:

- Vote app: `http://<node-ip>:31000`
- Result app: `http://<node-ip>:31001`

*Part of my Azure DevOps learning portfolio — see the root README for the full picture.*
