# Troubleshooting Notes – CI/CD Pipeline Debugging

Real errors I encountered while building these Azure DevOps pipelines, and exactly how I fixed them.

---

## Error 1: `dotnet restore` — Invalid option `-a`

### What happened
While running the worker pipeline (.NET service), the build stage failed with:

```
error: Invalid option -a
```

### Root cause
The Dockerfile for the worker service contained:

```dockerfile
RUN dotnet restore -a $TARGETARCH
```

The `-a` flag (architecture) is only valid when using `docker buildx` with cross-platform builds where `$TARGETARCH` is automatically set by the build environment. When building without proper buildx multi-platform context, `$TARGETARCH` is empty and the flag is unrecognised by `dotnet restore`.

### Fix
Removed the `-a $TARGETARCH` flag entirely from the Dockerfile:

```dockerfile
# Before (broken)
RUN dotnet restore -a $TARGETARCH

# After (fixed)
RUN dotnet restore
```

This works because the agent VM was building for its native architecture (linux/amd64) — no cross-compilation was needed.

---

## Error 2: `--platform` flag not supported by standard `docker build`

### What happened
Adding `--platform linux/amd64` to the standard `docker build` command in the pipeline caused:

```
unknown flag: --platform
```

or the build silently ignored it.

### Root cause
The `--platform` flag requires **BuildKit** to be enabled. Standard `docker build` without BuildKit does not support `--platform`.

### Fix
Switched to `docker buildx build` and enabled BuildKit explicitly:

```yaml
- task: Bash@3
  displayName: 'Set up Docker buildx'
  inputs:
    targetType: inline
    script: |
      docker buildx create --use --name mybuilder || true
      docker buildx inspect --bootstrap

- task: Bash@3
  displayName: 'Build with buildx'
  inputs:
    targetType: inline
    script: |
      export DOCKER_BUILDKIT=1
      docker buildx build \
        --platform linux/amd64 \
        -f Dockerfile \
        -t myimage:latest \
        --load \
        .
```

**Important:** `--load` is required when using `buildx` on a single-node build so the image is exported to the local Docker daemon. Without it, the image is built and immediately discarded — it won't be available to push in the next pipeline stage.

---

## Error 3: Agent Timeout

### What happened
The pipeline hung for a long time and eventually timed out with no clear error message. The self-hosted agent stopped responding mid-build.

### Root cause
The agent VM's Docker daemon was pulling a large base image (e.g. `mcr.microsoft.com/dotnet/sdk`) for the first time over a slow connection, causing the build step to exceed the default job timeout.

### Fix
Two-part fix:

1. **Pre-pulled the base image on the agent VM** to warm up the local Docker cache:
   ```bash
   docker pull mcr.microsoft.com/dotnet/sdk:8.0
   docker pull mcr.microsoft.com/dotnet/aspnet:8.0
   ```

2. **Increased the pipeline job timeout** in the YAML:
   ```yaml
   jobs:
   - job: BuildImage
     timeoutInMinutes: 60   # Increased from default 60 — can go higher if needed
   ```

After pre-pulling, subsequent pipeline runs completed much faster as images were already cached on the agent.

---

## General Debugging Tips

| Symptom | First thing to check |
|---|---|
| Pipeline hangs silently | Agent VM disk space (`df -h`) or Docker daemon status (`systemctl status docker`) |
| `Permission denied` on Docker | Agent user not in `docker` group — run `sudo usermod -aG docker <agent-user>` |
| Image built but not found in Push stage | Missing `--load` flag on `docker buildx build` |
| ACR push fails with 401 | Service connection not authorised — check ACR role assignment (AcrPush) |
| `$TARGETARCH` is empty | Not using buildx multi-platform mode — remove the flag or switch to buildx |

---

*These are real issues I debugged hands-on while running pipelines on a self-hosted Azure DevOps agent.*
