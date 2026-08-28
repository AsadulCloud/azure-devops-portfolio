# Kubernetes Ingress

Ingress manifests used to route external traffic to applications running on AKS.
All demo apps prefer a **shared NGINX Ingress Controller** over per-service
LoadBalancers so multiple projects can share one public IP (avoids Azure
public-IP quota limits).

## Prerequisites

Install the NGINX Ingress Controller once per cluster:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

## Files

| File | Project | Routing style |
|------|---------|---------------|
| `task-manager-ingress.yml` | Task Manager microservices | Path-based (`/task-manager`, `/api-service`, …) |
| `task-manager-ingress-host.yml` | Task Manager microservices | Host-based (`task-manager.example.com`, …) |
| `task-ingress.yml` | Task Manager (simpler variant) | Path-based |
| `voting-app-ingress.yml` | Multi-service voting app (GitOps) | Path / multi-service |
| `aks-cicd-app-ingress.yaml` | Terraform-AKS-CICD demo app | Path-based |
| `argocd-nginx-ingress.yml` | ArgoCD UI exposure | Path / host |

## Usage

```bash
# Example: path-based routing for Task Manager
kubectl apply -f task-manager-ingress.yml

# Check status
kubectl get ingress -A
kubectl describe ingress task-manager-ingress -n task-manager

# External IP lives on the Ingress Controller service
kubectl get svc -n ingress-nginx
```

## Notes

- These manifests are intended for **demo / portfolio** environments. Review
  hostnames, paths, and annotations before applying to a shared or production cluster.
- Backend services should be `ClusterIP`. The Ingress Controller is the only
  component that needs a public IP (LoadBalancer type on its own Service).
- For host-based rules, point DNS (or `/etc/hosts` for local tests) at the
  Ingress Controller EXTERNAL-IP.
- Debug with: `kubectl describe ingress <name> -n <namespace>` and controller logs:
  `kubectl logs -n ingress-nginx deploy/ingress-nginx-controller`
