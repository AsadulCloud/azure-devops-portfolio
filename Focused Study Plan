# Focused Study Plan — 2-3 hrs/day

**Approach:** One topic per block, minimal context-switching. Each block ends with something concrete added to your portfolio. Small daily review (15 min) of the previous block keeps it from decaying.

---

## Block 1: Ansible (Days 1-4)

**Goal:** Go from "I made it work once" to "I understand the structure well enough to explain it in an interview."

- **Day 1 — Inventory & ad-hoc commands**
  - Static inventory files (`/etc/ansible/hosts` or a project-local `inventory.ini`)
  - Groups and host variables
  - Ad-hoc commands: `ansible all -m ping`, `ansible webservers -m shell -a "uptime"`
  - Practice: run 5-6 ad-hoc commands against your existing Azure VMs

- **Day 2 — Playbooks & modules**
  - Playbook YAML structure: `hosts`, `tasks`, `become`
  - Common modules: `apt`, `copy`, `template`, `service`, `user`
  - Idempotency — why running a playbook twice shouldn't break anything
  - Practice: rewrite your existing nginx/apache2 playbook from scratch, without looking at the old one first

- **Day 3 — Roles**
  - Why roles exist (reusability, organization) — directory structure: `tasks/`, `handlers/`, `templates/`, `vars/`, `defaults/`
  - `ansible-galaxy init <role-name>` to scaffold one
  - Converting your existing playbook into a role
  - Practice: turn your apache2 playbook into a proper role

- **Day 4 — Variables, handlers, and vault**
  - `vars/`, `group_vars/`, `host_vars/` — variable precedence
  - Handlers (`notify:` + `handlers:` — e.g., restart nginx only if config changed)
  - `ansible-vault` for encrypting secrets (passwords, API keys) — critical for real-world use
  - Practice: add a handler to your role, encrypt one variable with vault

**Portfolio output:** A role-based Ansible project (not just flat playbooks) with at least one vaulted variable — commit to `07-Ansible/` with a short README explaining the role structure.

---

## Block 2: CI/CD (Days 5-11) — finishing your current project

Since you're already mid-project on `10-Terraform-AKS-CICD`, this block is about **finishing it properly** and understanding every piece, not starting over.

- **Day 5 — Finish the current pipeline**
  - Fix the remaining Dockerfile path issue we just found
  - Get a full green run: Build → Push → Deploy
  - Verify the app is live via the LoadBalancer IP

- **Day 6 — Understand what you built (review, no new code)**
  - Re-read `azure-pipelines.yml` top to bottom, out loud, explaining each line to yourself
  - Draw (on paper or in an artifact) the flow: Git push → trigger → Build stage → artifact → Deploy stage → AKS
  - Identify: where do secrets live? Where does the image tag come from? What triggers a re-run?

- **Day 7 — Pipeline variables & secrets properly**
  - Difference between pipeline variables, variable groups, and secret variables
  - Azure DevOps **Library** → variable groups (shared across pipelines)
  - Practice: move your ACR/AKS names into a variable group instead of hardcoding them in YAML

- **Day 8 — Multi-stage pipelines & approvals**
  - Environments in Azure DevOps (the `environment:` field you already used)
  - Manual approval gates before deploying to production (even if you don't set one up for real, understand why they exist)
  - Practice: add an environment approval check on your Deploy stage (can remove after testing)

- **Day 9 — Build once, deploy many (the core CI/CD principle)**
  - Why you tag images with `$(Build.BuildId)` instead of always `latest`
  - Rollback strategy: redeploying a previous image tag
  - Practice: manually redeploy an older build's image tag via `kubectl set image` — see it work without rebuilding

- **Day 10 — Path filtering & multi-project repos** (directly relevant to your portfolio repo structure)
  - Review the `paths: include:` fix we made today
  - Why this matters when one repo holds many unrelated projects
  - Practice: add path filtering to your Docker learning project's pipeline too if it has one

- **Day 11 — Write it up**
  - Full README for `10-Terraform-AKS-CICD/` — architecture diagram (even simple ASCII/boxes), the errors you hit and how you solved them, before/after
  - This becomes your strongest portfolio piece and interview talking point

**Portfolio output:** A fully working, documented CI/CD project with a README that tells the debugging story — this is your headline project.

---

## Block 3: Monitoring & Troubleshooting (Days 12-14) — your one real gap

This is new territory, so keep it lightweight and practical, not deep.

- **Day 12 — Azure Monitor basics**
  - What Azure Monitor collects by default for VMs and AKS (metrics, logs)
  - Enable **Container Insights** on your AKS cluster
  - Look at CPU/memory graphs for your running pods

- **Day 13 — Logging fundamentals**
  - `kubectl logs <pod>`, `kubectl logs -f` (follow mode), `kubectl describe pod` (you already use this well)
  - Centralized logging concept: why you'd ship logs somewhere instead of just `kubectl logs`
  - Practice: intentionally break something (bad env var, wrong image tag) and diagnose it using only logs + describe, timing yourself

- **Day 14 — Alerts & health checks (tie back to what you know)**
  - Revisit your `readinessProbe`/`livenessProbe` from the AKS project — explain in your own words why each exists
  - Set up one simple Azure Monitor alert rule (e.g., CPU > 80%) on your AKS cluster or VM
  - Practice: write a one-paragraph explanation of "how would I know if my app went down at 3am" — this is exactly the kind of question interviewers ask

**Portfolio output:** A short note in your README or a new `11-Monitoring/` folder showing you understand observability basics, even at an intro level.

---

## Daily rhythm suggestion

- **First 10 min:** Quick review of yesterday's concept (flashcard-style, just recall out loud)
- **Core 2-2.5 hrs:** New material for the day, hands-on
- **Last 10-15 min:** Write one sentence in a running log — "today I learned X, got stuck on Y, fixed it by Z." This becomes free interview prep later.

## After Day 14

You'll have directly covered every bullet point in the CloudFide posting except nothing — Linux, Docker, CI/CD, Ansible, monitoring/troubleshooting, cloud environments. At that point, revisit AZ-900 for a few days to close that out, since it's likely still your biggest resume-visible gap.
