# From Idea to Production — A-Z Workflow

How a real DevOps/engineering team would actually take this Task Manager
project from nothing to a live, monitored, documented system. Each phase
maps to real tools and real roles — follow this order, not just the code.

---

## Phase 1 — Planning (before writing any code)

**In a real org, this happens in Jira/Azure Boards, not in a text editor.**

1. **Ticket/Epic created:** "Build Task Manager MVP — microservices architecture"
2. **Requirements defined:**
   - What does the app do? (create tasks, mark complete, notify on events)
   - Which services are needed, and why? (frontend, api-service, notification-service, Redis)
   - What's explicitly OUT of scope for v1? (no persistent DB yet, no auth yet — write this down, it prevents scope creep)
3. **Architecture decision recorded** (real teams call this an ADR — Architecture Decision Record):
   - "We will use Redis pub/sub instead of direct service calls, because it decouples notification logic from the API and allows adding more subscribers later without touching api-service."
   - This one paragraph is worth writing down now — it's exactly what you'd say in a design review meeting or interview.
4. **Repo created**, folder structure agreed (`api-service/`, `notification-service/`, `frontend/`, `k8s/`)

**Your action:** write a one-paragraph ADR into your README before writing code. You already have the reasoning — it's in the README I gave you. Real teams do this first, not as an afterthought.

---

## Phase 2 — Local development (the "inner loop")

This is where developers (or you, wearing that hat) actually write and test code.

1. Write `api-service`, test it in isolation — run it locally, hit its endpoints with `curl`
2. Write `notification-service`, test that it correctly receives events (run both against a local Redis, or a temporary `docker run redis`)
3. Write `frontend`, test that it correctly calls both services
4. **Code review** — in a real team, this is a Pull Request, reviewed by a teammate before merging to `main`. Even solo, get in the habit: write a PR description explaining *why*, not just *what*.

**Your action:** actually run each service locally first (even with a throwaway `docker run -p 6379:6379 redis` for testing) before jumping straight to Kubernetes. Debugging in K8s is slower — catch basic bugs locally first.

---

## Phase 3 — Containerization

1. Write Dockerfiles for each service (done — provided)
2. Build and test each image **locally** first:
   ```bash
   docker build -t task-manager-api ./api-service
   docker run -p 4000:4000 -e REDIS_URL=redis://host.docker.internal:6379 task-manager-api
   ```
3. Confirm each container runs correctly in isolation before pushing anywhere

**Real org practice:** this step usually has its own CI check — "build succeeds" — before merging any PR, even before deployment is considered.

---

## Phase 4 — Infrastructure provisioning (Terraform)

You already have a working AKS + ACR setup from `10-Terraform-AKS-CICD` — real teams reuse infrastructure across projects rather than re-provisioning per-app. This is actually the realistic path:

1. **Decide:** new dedicated cluster, or reuse existing one with a new namespace? (For a portfolio/small team, reuse — that's the pragmatic real answer, and what your README recommends)
2. Create the namespace as part of your deployment process (see Phase 6), not manually ad-hoc
3. If a new project genuinely needs new infrastructure, that's a new Terraform module/workspace — not copy-pasted files

**Your action:** none needed here — you're correctly reusing existing infra, which is the mature choice.

---

## Phase 5 — Registry (push images to ACR)

```bash
az acr login --name <your-acr-name>

docker tag task-manager-api <your-acr-name>.azurecr.io/task-manager-api:v1
docker push <your-acr-name>.azurecr.io/task-manager-api:v1
```

**Real org practice — version tags, not just `latest`:** notice `v1` here instead of `latest`. In production, image tags are typically the Git commit SHA or a semantic version, so you always know *exactly* which code is running, and can roll back precisely. This matters more once you automate this in Phase 7.

---

## Phase 6 — Manual deployment (prove it works before automating)

**Real teams always do one manual/manual-ish deployment before fully automating** — you don't want your first-ever deployment attempt to be inside an untested pipeline.

```bash
kubectl create namespace task-manager

kubectl apply -f k8s/redis.yaml -n task-manager
kubectl apply -f k8s/api-service.yaml -n task-manager
kubectl apply -f k8s/notification-service.yaml -n task-manager
kubectl apply -f k8s/frontend.yaml -n task-manager
```

**Verify each layer, don't just check "is it running":**
```bash
kubectl get pods -n task-manager
kubectl logs deployment/notification-service -n task-manager   # confirm it's actually receiving events
kubectl get service frontend-service -n task-manager           # get the external IP
```

Open the external IP, add a task, confirm the notification shows up. **This is your "it works" milestone — the thing you'd demo to a manager or stakeholder.**

---

## Phase 7 — Automate it (CI/CD pipeline)

Now that you've proven it works manually, automate the exact same steps — reusing the pattern from `10-Terraform-AKS-CICD`.

**Pipeline stages, mapped to what you already know:**
```
Stage 1: Build
  - docker build + push for all THREE images (api-service, notification-service, frontend)

Stage 2: Deploy
  - kubectl apply for all FOUR manifests (redis, api-service, notification-service, frontend)
  - to the task-manager namespace
```

**Key difference from your last project:** this pipeline builds **three** images in one Build stage instead of one — a real multi-service pipeline. You'll need three `Docker@2` tasks (or a loop, if you want to get fancier later) instead of one.

**Trigger scoping** (same lesson as before — apply it from day one this time):
```yaml
trigger:
  branches:
    include: [main]
  paths:
    include:
      - task-manager-microservices/*
```

---

## Phase 8 — Monitoring & observability

This is the piece most portfolio projects skip — and exactly the gap you identified earlier in your study plan.

1. Enable **Container Insights** on your AKS cluster (if not already on from the last project)
2. Check basic health: `kubectl get pods -n task-manager` should show `Running`, `1/1` or `2/2` consistently
3. **Set up one simple alert** — e.g., "notification-service pod restarts more than 3 times in 10 minutes" — this is the kind of thing that separates "I deployed it once" from "I run this like production"

---

## Phase 9 — Documentation & handoff

**In a real org, a project isn't "done" until someone else could pick it up without asking you questions.**

1. README — architecture diagram, setup steps, **the ADR from Phase 1** (already drafted)
2. Runbook — "if X breaks, here's how to check it" (e.g., "if notifications stop appearing, check `kubectl logs deployment/notification-service` first, then confirm Redis is reachable")
3. Clean commit history — meaningful commit messages, not "fix" "fix2" "final fix"

---

## Phase 10 — Showcase (turning finished work into career value)

This is the step that's easy to skip but matters most for your job search.

1. **GitHub** — pin the repo, make sure the README is the first thing someone sees, lead with the architecture diagram and the *why* (event-driven pattern), not just install steps
2. **LinkedIn post** — announce it, name the specific technical decision (pub/sub vs direct calls) and one real problem you solved during the build
3. **CV bullet** — one line, specific: *"Designed and deployed an event-driven microservices system (Node.js, Redis pub/sub, Kubernetes) demonstrating decoupled service communication, with automated CI/CD via Azure DevOps."*
4. **Interview story ready** — be able to explain, in under 2 minutes: what problem pub/sub solves here, what you'd add next (persistent DB, real message broker), and one specific bug you hit and fixed

---

## The one-sentence version of this whole guide

**Plan → build small → containerize → provision infra (reuse if possible) → deploy manually once → automate it → watch it → document it → tell people about it.**

That order matters — skipping straight to "automate the pipeline" before a working manual deployment is the single most common mistake, and it's exactly why debugging pipelines is so much harder than debugging a manual `kubectl apply`.
