# Task Manager Microservices — What I Did, A-Z, With Commands

## A — Planned the architecture
Decided on event-driven pub/sub (Redis) instead of direct service-to-service
calls, so notification-service reacts independently without api-service
knowing it exists.

## B — Read the code first
Looked at each service's routes and dependencies before running anything.
```bash
ls -la api-service notification-service frontend k8s
cat api-service/package.json
cat notification-service/package.json
```

## C — Built each Docker image separately
```bash
cd api-service
docker build -t task-manager-api .

cd ../notification-service
docker build -t task-manager-notification .

cd ../frontend
docker build -t task-manager-frontend .
```

## D — Ran each service alone locally (first pass, before the network fix)
```bash
docker run -d --name test-redis -p 6379:6379 redis:7-alpine

docker run -d --name test-api -p 4000:4000 \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  --add-host=host.docker.internal:host-gateway \
  task-manager-api

docker logs test-api

curl http://localhost:4000/api/health
curl -X POST http://localhost:4000/api/tasks -H "Content-Type: application/json" -d '{"title":"Test task"}'
curl http://localhost:4000/api/tasks
```

Same pattern repeated for notification-service:
```bash
docker run -d --name test-notification -p 5000:5000 \
  -e REDIS_URL=redis://host.docker.internal:6379 \
  --add-host=host.docker.internal:host-gateway \
  task-manager-notification

docker logs test-notification
```

## E — Hit and fixed a real networking bug
Frontend's nginx couldn't resolve `api-service`/`notification-service` by
name on Docker's default network. Fixed with a custom network:
```bash
docker stop test-api test-notification test-redis
docker rm test-api test-notification test-redis

docker network create task-manager-net

docker run -d --name redis --network task-manager-net redis:7-alpine

docker run -d --name api-service --network task-manager-net \
  -e REDIS_URL=redis://redis:6379 \
  task-manager-api

docker run -d --name notification-service --network task-manager-net \
  -e REDIS_URL=redis://redis:6379 \
  task-manager-notification

docker run -d --name frontend --network task-manager-net -p 8080:80 \
  task-manager-frontend

docker logs frontend
```

## F — Proved the full local chain works
```bash
curl http://localhost:8080
curl http://localhost:8080/api-service/api/health
curl http://localhost:8080/notification-service/api/notifications

curl -X POST http://localhost:8080/api-service/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Full stack test"}'

curl http://localhost:8080/notification-service/api/notifications
```
Confirmed the notification appeared after creating a task through the
frontend's own proxy path — proof the whole chain works, not just direct
backend calls.

Cleanup:
```bash
docker stop redis api-service notification-service frontend
docker rm redis api-service notification-service frontend
docker network rm task-manager-net
```

## G — Wrote and reviewed the Kubernetes manifests
`k8s/redis.yaml`, `k8s/api-service.yaml`, `k8s/notification-service.yaml`,
`k8s/frontend.yaml` — Deployment + Service per microservice.
`frontend` = `LoadBalancer`, others = `ClusterIP`.

## H — Understood readiness probes
`readinessProbe.httpGet.path: /api/health` — Kubernetes checks this
repeatedly before routing real traffic to a new pod.

## I — Pushed all three images to ACR
```bash
az acr login --name asadulcicdacr

docker build -t asadulcicdacr.azurecr.io/task-manager-api:latest ./api-service
docker push asadulcicdacr.azurecr.io/task-manager-api:latest

docker build -t asadulcicdacr.azurecr.io/task-manager-notification:latest ./notification-service
docker push asadulcicdacr.azurecr.io/task-manager-notification:latest

docker build -t asadulcicdacr.azurecr.io/task-manager-frontend:latest ./frontend
docker push asadulcicdacr.azurecr.io/task-manager-frontend:latest
```

## J — Deployed manually to AKS first
```bash
ssh azureuser@158.158.0.234
cd ~/azure-devops-portfolio
git pull origin main
cd 12-Task-Manager-Microservices

kubectl create namespace task-manager

kubectl apply -f k8s/redis.yaml -n task-manager
kubectl apply -f k8s/api-service.yaml -n task-manager
kubectl apply -f k8s/notification-service.yaml -n task-manager
kubectl apply -f k8s/frontend.yaml -n task-manager

kubectl get pods -n task-manager
kubectl get service frontend-service -n task-manager
```

## K — Hit the public IP quota limit again
```bash
az network public-ip list --output table
kubectl get services --all-namespaces

# Found the old project's service still holding an IP:
kubectl delete service aks-cicd-app-service -n aks-cicd-app

# Rechecked after freeing it:
kubectl get service frontend-service -n task-manager
```

## L — Verified the live deployment
```bash
curl http://<external-ip>
curl http://<external-ip>/api-service/api/health

curl -X POST http://<external-ip>/api-service/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Production test"}'

curl http://<external-ip>/notification-service/api/notifications
```

## M — Built three separate CI/CD pipelines
One per microservice, each triggered only by changes to its own folder:
```
pipelines/api-service-pipeline.yml
pipelines/notification-service-pipeline.yml
pipelines/frontend-pipeline.yml
```
Each: `Docker@2 buildAndPush` → upload manifests as artifact → 
`KubernetesManifest@0` (createSecret, then deploy) via an Environment
(`task-manager`) linked to a Kubernetes service connection.

```bash
git add 12-Task-Manager-Microservices/pipelines/
git commit -m "Add three CI/CD pipelines, one per microservice"
git push origin main
```

## N — Fixed real pipeline auth issues
Both `KubernetesManifest@0` tasks (createSecret AND deploy) needed
`kubernetesServiceConnection` set explicitly — added:
```yaml
kubernetesServiceConnection: 'task-manager-asadulcicd-aks-task-manager-1784884434412'
```
to both steps in all three pipeline files.

## O — Got all three pipelines green
Confirmed via Azure DevOps → Pipelines: api-service, notification-service,
and frontend pipelines all passing on `main`.

## P — Compared architectural choices honestly
Discussed why this project uses direct `kubectl apply` via pipeline instead
of ArgoCD (used in the voting app) — simpler, appropriate for 3 services,
no GitOps complexity needed at this scale.

## Q — Documented the reasoning, not just the steps
README includes the architecture diagram and the *why* behind pub/sub.

---

## The one real skill this project proved

**Local-first debugging.** The nginx networking bug (Step E) got caught and
fixed in minutes with `docker logs` and a `docker network create` — instead
of surfacing later inside Kubernetes or a pipeline, where it would have
taken much longer to diagnose. That discipline is the actual takeaway, more
than any single tool used.
