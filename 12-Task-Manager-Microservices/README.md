# Task Manager — Microservices Demo

A 3-microservice application demonstrating **asynchronous, event-driven
communication** between services — a different pattern from the direct
request/response style used in the voting app project. Deployed to AKS
with three independent CI/CD pipelines (one per service), and proven
locally end-to-end before ever touching Kubernetes.

## Architecture

![Task Manager architecture diagram](docs/architecture-diagram.svg)

```
Browser
   │
   ▼
[NGINX Ingress Controller]  ← single public IP for the cluster
   │  path / host routing
   ▼
[frontend]  (nginx, ClusterIP)
   │  reverse-proxies /api-service/ and /notification-service/
   ▼
[api-service] (Express, ClusterIP - internal only)
   │  publishes events on task creation/completion
   ▼
[Redis]  (pub/sub channel: "task-events")
   │
   ▼
[notification-service] (Express, ClusterIP - internal only)
   subscribes to task-events, logs a "notification" per event
```

**Why this pattern is worth knowing:** the `api-service` never calls
`notification-service` directly. It just publishes an event and moves on.
This means:
- If `notification-service` is down or slow, task creation still works instantly
- You could add a third, fourth, fifth subscriber (e.g. an email service,
  an audit-log service) without ever touching `api-service`'s code
- This is the same underlying idea behind real message queues (RabbitMQ, Kafka,
  Azure Service Bus) — Redis pub/sub here is a lightweight stand-in for learning
  the pattern before using a heavier, more durable message broker

**Why Ingress instead of per-service LoadBalancers:**  
Early versions exposed services with LoadBalancers and hit Azure's public-IP
quota (3 IPs per subscription/region). The final design routes everything
through a shared **NGINX Ingress Controller** so multiple apps on the same
cluster share one external IP. All three services are `ClusterIP`; the
Ingress is the only public entry point.

Ingress manifests live in [`13-Kubernetes-Ingress/`](../13-Kubernetes-Ingress/):
- `task-manager-ingress.yml` — path-based routing
- `task-manager-ingress-host.yml` — host-based routing

## Local testing (before deploying to AKS)

You'll need Redis running locally, or just deploy straight to AKS (below) —
that's simpler than setting up local Redis for a two-service test.

## Build and push each image

```bash
az acr login --name <your-acr-name>

docker build -t <your-acr-name>.azurecr.io/task-manager-api:latest ./api-service
docker push <your-acr-name>.azurecr.io/task-manager-api:latest

docker build -t <your-acr-name>.azurecr.io/task-manager-notification:latest ./notification-service
docker push <your-acr-name>.azurecr.io/task-manager-notification:latest

docker build -t <your-acr-name>.azurecr.io/task-manager-frontend:latest ./frontend
docker push <your-acr-name>.azurecr.io/task-manager-frontend:latest
```

## Update image references

In each `k8s/*.yaml` file, replace `ACR_LOGIN_SERVER` / placeholder image tags
with your actual ACR login server (e.g. `asadulcicdacr.azurecr.io`).

## Deploy to your existing AKS cluster

Reuses the same cluster from `10-Terraform-AKS-CICD` — no new Terraform
needed unless you want a dedicated cluster.

```bash
# 1. Namespace + workloads
kubectl create namespace task-manager
kubectl apply -f k8s/redis.yaml -n task-manager
kubectl apply -f k8s/api-service.yaml -n task-manager
kubectl apply -f k8s/notification-service.yaml -n task-manager
kubectl apply -f k8s/frontend.yaml -n task-manager

# 2. Ensure NGINX Ingress Controller is installed (once per cluster)
# helm install ingress-nginx ingress-nginx/ingress-nginx \
#   --namespace ingress-nginx --create-namespace

# 3. Route traffic via Ingress (path-based or host-based)
kubectl apply -f ../13-Kubernetes-Ingress/task-manager-ingress.yml
# or: kubectl apply -f ../13-Kubernetes-Ingress/task-manager-ingress-host.yml
```

## Verify

```bash
kubectl get pods -n task-manager
kubectl get svc -n task-manager
kubectl get ingress -n task-manager
kubectl get svc -n ingress-nginx   # EXTERNAL-IP of the Ingress Controller
```

Open the Ingress Controller's external IP (or configured host) and hit the
Task Manager path/host. Add a task, mark it complete, and watch the
Notifications panel update within a few seconds — that's the pub/sub message
travelling from `api-service` → Redis → `notification-service` → back to the
browser via polling.

## CI/CD

Three independent Azure DevOps pipelines, one per microservice, each
triggered only by changes to its own folder — matching the same
per-service pattern used in the voting app project:

```
pipelines/api-service-pipeline.yml           → triggers on api-service/*
pipelines/notification-service-pipeline.yml  → triggers on notification-service/*
pipelines/frontend-pipeline.yml              → triggers on frontend/*
```

Each pipeline: builds and pushes its image to ACR, then deploys via
`KubernetesManifest@0` to the `task-manager` namespace using an
environment-linked Kubernetes service connection. Redis has no pipeline —
it's applied once manually, since it's an off-the-shelf image with no
source code to build.

## Real problems solved

**nginx couldn't resolve sibling containers by name.** Testing the full
stack locally in Docker, `frontend`'s nginx failed at startup with
`host not found in upstream "api-service"`. Root cause: containers on
Docker's default bridge network can only reach each other by IP, not by
name — there's no automatic name resolution. Fixed by creating a custom
Docker network (`docker network create`) and running all containers on
it, which gives each container name-based DNS automatically — the same
mechanism Kubernetes Services provide cluster-wide, for free. Catching
this locally, in minutes, avoided a much harder debugging session inside
Kubernetes later.

**Public IP quota exhausted.** Early deployments used per-service
LoadBalancers. `frontend-service` stayed `<pending>` after the quota
(3 public IPs per subscription/region) was exhausted by other workloads on
the same cluster. Traced with `az network public-ip list`. Fixed by:
1. Freeing unused LoadBalancer services from earlier projects
2. Migrating Task Manager to a **shared NGINX Ingress Controller** so all
   services are ClusterIP and only the Ingress holds a public IP

**`KubernetesManifest@0` needed explicit service connection.** The pipeline
task failed with `Input required: kubernetesServiceConnection` on both
the secret-creation and deploy steps — the `environment:` field alone
does not automatically supply this to either task, contrary to
expectation. Fixed by adding `kubernetesServiceConnection:` explicitly to
both `KubernetesManifest@0` steps in all three pipelines.

## Runbook

If notifications stop appearing after adding a task:
1. `kubectl logs deployment/notification-service -n task-manager` — check
   for connection errors to Redis
2. Confirm Redis itself is healthy: `kubectl get pods -n task-manager`,
   then `kubectl exec -it <redis-pod> -n task-manager -- redis-cli ping`
   (should return `PONG`)
3. If api-service's task creation still works but no notification appears,
   check `kubectl logs deployment/api-service -n task-manager` for a
   failed Redis publish

If the app is unreachable externally:
1. `kubectl get ingress -n task-manager` and `kubectl describe ingress -n task-manager`
2. Confirm the Ingress Controller has an EXTERNAL-IP: `kubectl get svc -n ingress-nginx`
3. Confirm all three services are ClusterIP and healthy: `kubectl get svc,pods -n task-manager`

## Next steps (optional extensions)

- Add a database (Postgres) so tasks persist across pod restarts, instead
  of the current in-memory array
- Swap Redis pub/sub for Azure Service Bus or RabbitMQ, to see the same
  pattern with a production-grade message broker
- TLS termination on the Ingress (cert-manager + Let's Encrypt)
