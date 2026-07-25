# My Deployment Checklist — every time I get new source code

Follow this exact order, every project, no skipping ahead. Each step only
starts once the previous one is proven working — not "probably fine."

---

## 1. READ — understand before touching anything

- [ ] Open every folder, look at the structure — how many services? What are they called?
- [ ] Open each `package.json` — what does each service actually depend on?
- [ ] Find the entry point of each service (usually `app.js` or similar) — read it top to bottom once, no editing
- [ ] Ask: what does each service DO, in one sentence?

**Don't run anything yet. Just understand what you're looking at.**

---

## 2. BUILD — turn code into images, one at a time

For each service that has its own Dockerfile (my own code):
- [ ] `docker build -t <name> .`
- [ ] Confirm it finishes with no errors

For anything that's NOT my code (Redis, Postgres, etc.):
- [ ] Skip building — just note the image name I'll `docker run` later (e.g. `redis:7-alpine`)

---

## 3. RUN EACH SERVICE ALONE — prove each piece works in isolation

Start with anything OTHER services depend on first (e.g. Redis before api-service).

For each service:
- [ ] `docker run` it, with whatever env vars it needs
- [ ] `docker logs <container>` — confirm no crash, no error
- [ ] If it exposes an HTTP endpoint, `curl` its health check first

**Rule: don't move to the next service until this one's logs are clean.**

---

## 4. CONNECT THEM — prove they can talk to each other

- [ ] Run all services together locally (manually, or eventually with docker-compose)
- [ ] Trigger the actual feature end-to-end (e.g. create a task → check it appears in the notification log)
- [ ] If something doesn't connect, fix it HERE — not later in Kubernetes, where it's harder to see what's wrong

---

## 5. WRITE/REVIEW KUBERNETES MANIFESTS

- [ ] One Deployment + Service per microservice
- [ ] Decide: does this service need a public IP (`LoadBalancer`), or is it internal-only (`ClusterIP`)?
- [ ] Double check image names match exactly what I'll push to ACR
- [ ] Double check env vars match what each service actually needs (from Step 1's reading)

---

## 6. MANUAL DEPLOY TO KUBERNETES — prove it works by hand first

- [ ] Create the namespace
- [ ] `kubectl apply -f` each manifest, in dependency order (Redis before api-service, etc.)
- [ ] `kubectl get pods` — wait for all `Running`, `1/1`
- [ ] `kubectl logs` on anything that looks wrong
- [ ] Test the actual feature through the real public IP

**Do not move to Step 7 until this manual deployment genuinely works.**

---

## 7. AUTOMATE IT — build the CI/CD pipeline

- [ ] Write pipeline stages that do EXACTLY what I just did by hand in Steps 2, 3, 6 — nothing new, just automated
- [ ] Scope the trigger (`paths: include:`) to this project's folder only
- [ ] Push and watch the first run closely, fix any path/naming issues

---

## 8. VERIFY IN PRODUCTION

- [ ] Hit the live public endpoint
- [ ] Confirm the full feature works end-to-end, same as Step 4, but now through the real pipeline-deployed version

---

## 9. DOCUMENT & SHOWCASE

- [ ] README: architecture, how to run it, what I'd add next
- [ ] One real problem I hit + how I solved it (this is gold for interviews)
- [ ] LinkedIn post / CV bullet if it's portfolio-worthy

---

## The one rule that matters most

**Never skip a step to "save time."** Every skipped step just moves the
debugging to a harder place later — local `docker logs` is always easier
to read than pipeline logs, and pipeline logs are always easier than
production incident debugging. Fix things as early in this list as possible.
