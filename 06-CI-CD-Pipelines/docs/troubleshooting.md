# Real Errors I Hit and How I Fixed Them

## 1. Docker Permission Denied
**Error:** `permission denied while trying to connect to docker.sock`
**Cause:** Agent user not in docker group
**Fix:** `sudo usermod -aG docker azureuser` + restart agent

## 2. CRLF Line Endings
**Error:** `$'\r': command not found` on every line
**Cause:** Script saved on Windows with \r\n endings
**Fix:** Rewrote script using heredoc on Linux agent

## 3. ImagePullBackOff
**Error:** `failed to pull image "newcicd1/votingapp:19"`
**Cause:** Missing `.azurecr.io` prefix — Kubernetes tried Docker Hub
**Fix:** Updated sed command to write `newcicd1.azurecr.io/$2:$3`

## 4. Stale Kubeconfig
**Error:** `dial tcp: lookup azurek8s-dns...austriaeast: no such host`
**Cause:** Cluster recreated in spaincentral, kubeconfig still had old region
**Fix:** `az aks get-credentials --overwrite-existing` + copy to WSL

## 5. BuildKit TARGETARCH Error
**Error:** `Required argument missing for option: -a`
**Cause:** `ARG TARGETARCH` only works with BuildKit, not legacy builder
**Fix:** Removed `-a $TARGETARCH` flags from dotnet commands

## 6. AKS Can't Pull from ACR
**Error:** `pull access denied, insufficient_scope`
**Cause:** AKS had no role assignment to pull from ACR
**Fix:** `az aks update --attach-acr newcicd1`

## 7. Too Many Pods / Node Full
**Error:** `0/1 nodes available: Too many pods`
**Cause:** Failed pods not terminating, filling the single node
**Fix:** Deleted stuck pods manually; rolling update self-managed after

## 8. Malformed Git URL
**Error:** `URL rejected: Malformed input to a URL function`
**Cause:** PAT variable had `\r` appended due to CRLF
**Fix:** Fixed CRLF issue — PAT passed cleanly after
