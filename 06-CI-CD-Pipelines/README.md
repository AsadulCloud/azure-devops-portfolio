# 06 – CI/CD Pipelines (Azure DevOps)

This section documents the CI/CD pipelines I built in **Azure DevOps** for the classic [voting-app](https://github.com/dockersamples/example-voting-app) project — a multi-service application made up of three services written in different languages.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure DevOps Project                     │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ vote-pipeline│  │result-pipeline│  │ worker-pipeline  │  │
│  │  (Python)    │  │  (Node.js)   │  │    (.NET)        │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │             │
│         └─────────────────┴────────────────────┘            │
│                           │                                 │
│                    ┌──────▼───────┐                         │
│                    │  Self-Hosted │                         │
│                    │  Agent (VM)  │                         │
│                    └──────┬───────┘                         │
│                           │                                 │
│                    ┌──────▼───────┐                         │
│                    │    Azure     │                         │
│                    │  Container   │                         │
│                    │  Registry    │                         │
│                    └──────────────┘                         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 Services & Pipelines

| Service | Language | Pipeline File | Image Tag |
|---------|----------|---------------|-----------|
| vote | Python / Flask | `pipelines/vote-pipeline.yml` | `vote:latest` |
| result | Node.js | `pipelines/result-pipeline.yml` | `result:latest` |
| worker | .NET (C#) | `pipelines/worker-pipeline.yml` | `worker:latest` |

---

## 🔄 Pipeline Structure

Each pipeline follows a **two-stage pattern**:

```
Stage 1: Build
  └── Build Docker image using Dockerfile in the service folder
  └── Tag image with build ID for traceability

Stage 2: Push
  └── Log in to Azure Container Registry (ACR)
  └── Push tagged image to ACR
```

---

## 🛠️ Infrastructure

- **Agent**: Self-hosted Azure DevOps agent running on an Ubuntu 24.04 Azure VM
- **Registry**: Azure Container Registry (ACR)
- **Source**: Azure Repos (Git)
- **Build Engine**: Docker with BuildKit enabled (`DOCKER_BUILDKIT=1`)

---

## ⚙️ Prerequisites

1. Azure DevOps project and repository set up
2. Self-hosted agent configured and running on a Linux VM
3. Azure Container Registry created
4. ACR service connection added in Azure DevOps
5. Docker installed on the agent VM

---

## 📁 Folder Structure

```
06-CI-CD-Pipelines/
├── README.md                   ← You are here
├── pipelines/
│   ├── vote-pipeline.yml       ← Python/Flask service pipeline
│   ├── result-pipeline.yml     ← Node.js service pipeline
│   └── worker-pipeline.yml     ← .NET service pipeline
└── docs/
    └── troubleshooting.md      ← Real errors I hit and how I fixed them
```

---

## 🔐 Secrets & Best Practices

- ACR credentials are **never hardcoded** — stored as Azure DevOps service connections
- No secrets in Dockerfiles or YAML files
- Images tagged with `$(Build.BuildId)` for auditability alongside `latest`

---

## 📸 Key Learning Outcomes

- Writing multi-stage Azure DevOps YAML pipelines from scratch
- Configuring and troubleshooting a self-hosted Linux agent
- Using `docker buildx` and BuildKit for cross-platform image builds
- Debugging real pipeline failures (agent timeouts, platform flags, .NET restore flags)
- Pushing images to ACR using service connections

---

*Part of my Azure DevOps learning portfolio — see the root README for the full picture.*
