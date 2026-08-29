# Azure DevOps Portfolio — Md Asadul Howlader

Hands-on Azure DevOps & cloud engineering projects. Work is organised by numbered folders (each a small project or lab).

## Skills demonstrated

- **Azure** — AKS, ACR, VNet, NSG, Bastion, Firewall, ARM Templates, Managed Identity
- **Infrastructure as Code** — Terraform (remote state, OIDC / Workload Identity)
- **CI/CD & GitOps** — Azure Pipelines (YAML), ArgoCD
- **Containers & Kubernetes** — Docker, AKS, manifests, NGINX Ingress, Helm, Kustomize
- **Observability** — Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics, PromQL
- **Configuration management** — Ansible
- **Scripting** — Bash, Shell
- **IAM / Identity** — Azure AD, Managed Identity

## Projects

| # | Project | Tools |
|---|---|---|
| 01 | [Networking](01-Networking/) | Azure, ARM |
| 02 | [Virtual Machines](02-Virtual-Machines/) | Azure, ARM |
| 03 | [ARM Templates](03-ARM-Templates/) | ARM, Azure CLI |
| 04 | [Shell Scripting](04-Shell-Scripting/) | Bash |
| 05 | [IAM](05-IAM/) | Azure AD, Managed Identity |
| 06 | [CI/CD Pipelines](06-CI-CD-Pipelines/) | Azure DevOps, Docker, AKS |
| 07 | [Terraform](07-Terraform/) | Terraform, Azure |
| 08 | [Terraform AKS](08-Terraform-AKS/) | Terraform, AKS |
| 09 | [Docker](09-Docker/) | Docker |
| 10 | [Terraform-AKS-CICD](10-Terraform-AKS-CICD/) | Terraform, AKS, Azure Pipelines |
| 11 | [Ansible](11-Ansible/) | Ansible, Azure |
| 12 | [Task Manager Microservices](12-Task-Manager-Microservices/) | AKS, Redis, Azure Pipelines, NGINX Ingress |
| 13 | [Kubernetes Ingress](13-Kubernetes-Ingress/) | Kubernetes, NGINX Ingress |
| 14 | [Terraform + Ansible Capstone](14-Terraform-Ansible-Capstone/) | Terraform, Ansible, Azure Pipelines, OIDC |
| 15 | [Three-Tier Architecture Demo](15-Three-Tier-Architecture-Demo-Project/) | Terraform, Azure |
| 16 | [Observability](16-Observability/Project-1/) | Prometheus, Grafana, Alertmanager, AKS, Kustomize |

### Highlighted projects

- **[16 — Observability](16-Observability/Project-1/)** — Production-style monitoring on AKS (Prometheus, Grafana, Alertmanager, Node Exporter, kube-state-metrics); custom app metrics; cross-namespace alerting fix; dashboard-as-code.
- **[14 — Terraform + Ansible Capstone](14-Terraform-Ansible-Capstone/)** — One pipeline: Terraform provisions VM + key, dynamic Ansible inventory, nginx config; OIDC auth; debug log of real issues.
- **[12 — Task Manager Microservices](12-Task-Manager-Microservices/)** — Multi-service app on AKS with Redis pub/sub; LoadBalancer → shared NGINX Ingress migration.
- **[10 — Terraform AKS CI/CD](10-Terraform-AKS-CICD/)** — Infra as code + pipeline build/push/deploy with managed identity / AcrPull.

## Related / reference material

| Path | Notes |
|---|---|
| [docs/Focused-Study-Plan.md](docs/Focused-Study-Plan.md) | Study plan |
| `example-voting-app` | Git submodule — voting app / GitOps lab |
| `observability-zero-to-hero` | Git submodule — learning notes (days 1–7) |
| `three-tier-architecture-demo` | Git submodule — related three-tier demo |

## Notes

- `azure-pipelines-demo.yml` and `updateK8sManifests.sh` live under `06-CI-CD-Pipelines/`.
- Terraform provider / variable samples live under `07-Terraform/`.
- Submodules need `git submodule update --init` after clone if you want those trees locally.

## Connect

- GitHub: [github.com/AsadulCloud](https://github.com/AsadulCloud)
- Portfolio repo: [azure-devops-portfolio](https://github.com/AsadulCloud/azure-devops-portfolio)
- LinkedIn: [linkedin.com/in/asadul-howlader](https://www.linkedin.com/in/asadul-howlader)
