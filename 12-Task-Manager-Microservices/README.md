# Task Manager — Microservices Demo

A 3-microservice application demonstrating **asynchronous, event-driven
communication** between services — a different pattern from the direct
request/response style used in the voting app project.

## Architecture

```
Browser
   │
   ▼
[frontend]  (nginx, LoadBalancer - only service with a public IP)
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

**Why only the frontend gets a public IP:** `api-service` and
`notification-service` are `ClusterIP` (internal-only) — this also sidesteps
the public IP quota problem from the previous project, since only one
`LoadBalancer` service exists here instead of three.

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

In each `k8s/*.yaml` file, replace `ACR_LOGIN_SERVER` with your actual ACR
login server (e.g. `asadulcicdacr.azurecr.io`).

## Deploy to your existing AKS cluster

Reuses the same cluster from `10-Terraform-AKS-CICD` — no new Terraform
needed unless you want a dedicated cluster.

```bash
kubectl create namespace task-manager
kubectl apply -f k8s/redis.yaml -n task-manager
kubectl apply -f k8s/api-service.yaml -n task-manager
kubectl apply -f k8s/notification-service.yaml -n task-manager
kubectl apply -f k8s/frontend.yaml -n task-manager
```

## Verify

```bash
kubectl get pods -n task-manager
kubectl get service frontend-service -n task-manager
```

Once `frontend-service` has an `EXTERNAL-IP`, open `http://<that-ip>` in a
browser. Add a task, mark it complete, and watch the Notifications panel
update within a few seconds — that's the pub/sub message actually
travelling from `api-service` → Redis → `notification-service` → back to
the browser via polling.

## Next steps (optional extensions)

- Wire this into a CI/CD pipeline, reusing the pattern from
  `10-Terraform-AKS-CICD` — one pipeline building and pushing all three
  images, then applying all four manifests
- Add a database (Postgres) so tasks persist across pod restarts, instead
  of the current in-memory array
- Swap Redis pub/sub for Azure Service Bus or RabbitMQ, to see the same
  pattern with a production-grade message broker
