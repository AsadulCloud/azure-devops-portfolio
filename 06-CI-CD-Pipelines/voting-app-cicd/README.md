# Voting App — Full Azure DevOps CI/CD Pipeline

## What This Project Demonstrates
End-to-end CI/CD pipeline for a microservices voting application
using Azure DevOps, ACR, AKS, and ArgoCD GitOps.

## Pipeline Architecture
Developer pushes code

↓

Azure DevOps triggers pipeline

↓

Docker builds image (self-hosted agent)

↓

Image pushed to Azure Container Registry (newcicd1.azurecr.io)

↓

updateK8sManifests.sh updates k8s-specifications/*.yaml

↓

ArgoCD detects Git change → syncs to AKS cluster

↓

Pods rolling updated on AKS (azurek8s, spaincentral)
## Infrastructure
| Resource | Name | Details |
|----------|------|---------|
| AKS Cluster | azurek8s | spaincentral, v1.34.8 |
| ACR | newcicd1.azurecr.io | attached to AKS |
| Agent Pool | azureagent | self-hosted Ubuntu VM |
| GitOps | ArgoCD v3.4.4 | auto-sync enabled |

## Services Deployed
| Service | Image | Language |
|---------|-------|----------|
| vote | newcicd1.azurecr.io/votingapp | Python |
| result | newcicd1.azurecr.io/resultservice | Node.js |
| worker | newcicd1.azurecr.io/votingapp | .NET 7 |
| redis | redis:alpine | Cache |
| db | postgres:15-alpine | Database |

## Real Problems Solved
| Problem | Root Cause | Fix |
|---------|-----------|-----|
| Docker permission denied | Agent not in docker group | usermod -aG docker + restart |
| CRLF errors in shell script | Windows line endings | Rewrote script with LF via heredoc |
| ImagePullBackOff | Missing .azurecr.io prefix in sed command | Fixed ACR URL in updateK8sManifests.sh |
| kubectl no such host | Stale kubeconfig pointing to old region | az aks get-credentials --overwrite-existing |
| BuildKit TARGETARCH error | Legacy builder doesn't support ARG TARGETARCH | Removed -a $TARGETARCH from Dockerfile |
| AKS can't pull from ACR | No role assignment | az aks update --attach-acr |

## Key Files
- `vote-pipeline.yml` — Vote service pipeline (build/push/update)
- `result-pipeline.yml` — Result service pipeline
- `updateK8sManifests.sh` — Shell script for GitOps manifest update
- `k8s-specifications/` — Kubernetes deployment and service YAMLs
