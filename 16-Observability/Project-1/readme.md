# 🔭 Kubernetes Observability & Monitoring — Production-Style Implementation on AKS

> Built independently on Azure Kubernetes Service (AKS) as part of a hands-on DevOps portfolio.  
> Demonstrates real-world monitoring, alerting, and debugging skills using industry-standard tools.

---

## 🙋 Why I Built This

I built this project to demonstrate that I can **set up, configure, debug, and fix** a production-style observability stack on Kubernetes — not just deploy tools, but understand why things work, adapt to real problems, and solve them independently.

---

## 📚 Core Concepts Applied

> A quick reference to the key concepts this project puts into practice.

| Concept | What It Means | How I Used It |
|---|---|---|
| **Monitoring** | Tracking *what* is happening — CPU, memory, restarts via predefined metrics and thresholds | Configured Prometheus to scrape metrics and trigger alerts when CPU > 50% or pod restarts > 2 |
| **Observability** | Understanding *why* it's happening by correlating logs, metrics, and traces | Implemented the metrics pillar; EFK (logs) and Jaeger (traces) are next steps |
| **Instrumentation** | Adding code or exporters to expose internal system data as metrics | Used `prom-client` library in Node.js apps to expose custom HTTP metrics |
| **Service Discovery** | Automatically finding and scraping new targets without manual config | Configured `ServiceMonitor` CR so Prometheus auto-discovers app pods in `dev` namespace |
| **Exporters** | Agents that collect metrics from systems that don't natively support Prometheus | kube-prometheus-stack includes Node Exporter (hardware) and kube-state-metrics (K8s objects) |
| **PromQL** | Prometheus query language to filter, aggregate, and analyze time-series metrics | Wrote queries for CPU usage, restart counts, request rates, and 95th percentile latency |
| **Alertmanager** | Handles deduplication, grouping, and routing of alerts to receivers like email or Slack | Configured routing rules, inhibition rules, and Gmail SMTP delivery |

---

## 🛠️ Skills Demonstrated

| Skill | Evidence in This Project |
|---|---|
| Kubernetes | Deployed and managed multi-namespace workloads on AKS |
| Helm | Installed kube-prometheus-stack, managed releases |
| Kustomize | Managed all manifests with Kustomize overlays |
| Prometheus | Configured scraping, wrote PromQL queries, defined alert rules |
| Alertmanager | Configured routing, receivers, inhibition rules, email delivery |
| Debugging | Diagnosed and fixed a real cross-namespace alerting bug |
| NGINX Ingress | Exposed services via Ingress instead of port-forwarding |
| Azure AKS | Built and managed the full stack on Azure |
| Security | Stored all credentials as Kubernetes Secrets, never hardcoded |

---

## 🏗️ Stack Used

| Tool | Purpose |
|---|---|
| **Azure AKS** | Kubernetes cluster |
| **Prometheus** | Metrics collection & alerting rules |
| **Grafana** | Metrics visualization & dashboards |
| **Alertmanager** | Alert routing & email notification |
| **NGINX Ingress** | URL-based access to all UIs |
| **Kustomize** | Manifest management |
| **Helm** | kube-prometheus-stack installation |
| **Node.js (prom-client)** | Custom application metrics |
| **Gmail SMTP** | Alert email delivery |

---

## 🏠 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      AKS Cluster                         │
│                                                          │
│   ┌──────────────┐      ┌────────────────────────────┐  │
│   │   dev ns      │      │       monitoring ns         │  │
│   │              │      │                            │  │
│   │  service-a ──┼──────┼──► ServiceMonitor          │  │
│   │  service-b   │      │         │                  │  │
│   └──────────────┘      │         ▼                  │  │
│                         │    Prometheus               │  │
│                         │         │                  │  │
│                         │    ┌────┴─────┐            │  │
│                         │    ▼          ▼            │  │
│                         │  Grafana  Alertmanager      │  │
│                         │               │            │  │
│                         └───────────────┼────────────┘  │
│                                         ▼               │
│   ┌─────────────────────────────────┐  Gmail            │
│   │  NGINX Ingress Controller        │                   │
│   │  /grafana /prometheus            │                   │
│   │  /alertmanager                   │                   │
│   └─────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
Project-1/
├── application/
│   ├── service-a/               # Node.js app with custom Prometheus metrics
│   └── service-b/               # Downstream microservice
├── kubernetes-manifest/
│   └── kustomization.yml        # App deployment via Kustomize
├── alerts-alertmanager-servicemonitor-manifest/
│   ├── alerts.yml               # PrometheusRule — HighCpuUsage & PodRestart
│   ├── email-secrets.yml        # Gmail credentials as K8s Secret
│   ├── alertmanager-secret.yml  # Direct Alertmanager config
│   ├── serviceMonitor.yml       # Scrape config for dev namespace apps
│   └── kustomization.yml
└── README.md
```

---

## 🚀 Installation

### Step 1 — Install kube-prometheus-stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create ns monitoring

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring
```

### Step 2 — Deploy Applications

```bash
kubectl create ns dev
kubectl apply -k kubernetes-manifest/
```

### Step 3 — Set Up NGINX Ingress

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Step 4 — Deploy Alerting Stack

```bash
kubectl apply -k alerts-alertmanager-servicemonitor-manifest/
```

### Step 5 — Verify Everything

```bash
kubectl get all -n monitoring
kubectl get prometheusrule -n monitoring
kubectl get servicemonitor -n monitoring
```

---

## 📈 Custom Application Metrics

Instrumented Node.js apps with `prom-client` to expose:

| Metric | Type | What It Measures |
|---|---|---|
| `http_requests_total` | Counter | Total requests per endpoint |
| `http_request_duration_seconds` | Histogram | Request latency buckets |
| `http_request_duration_summary_seconds` | Summary | 95th percentile latency |
| `node_gauge_example` | Gauge | Async task duration |

---

## 🔍 PromQL Queries

```bash
# CPU usage across all nodes
100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100)

# Pod restart count
kube_pod_container_status_restarts_total > 2

# HTTP request rate per service
rate(http_requests_total[5m])

# 95th percentile request duration
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
)
```

---

## 🚨 Alert Rules Configured

| Alert | Expression | Severity | Trigger |
|---|---|---|---|
| `HighCpuUsage` | `100 - (avg by(instance)(rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 50` | warning | CPU > 50% for 5 min |
| `PodRestart` | `kube_pod_container_status_restarts_total > 2` | critical | Instantly on 3rd restart |

---

## 🐛 Real Problem I Found & Fixed

> This section shows I can debug production issues, not just deploy tools.

### Problem
Alert emails stopped arriving after `service-a` (running in `dev` namespace) restarted — even though Alertmanager logs showed no errors and the config looked correct.

### How I Debugged It

```bash
# Step 1 — Checked Alertmanager logs — no errors found
kubectl logs -n monitoring alertmanager-...-0 -c alertmanager --tail=50

# Step 2 — Read the live rendered config (not the source file)
kubectl exec -n monitoring alertmanager-...-0 \
  -c alertmanager -- cat /etc/alertmanager/config_out/alertmanager.env.yaml

# Step 3 — Opened Alertmanager UI — saw ALL alerts going to null receiver

# Step 4 — Confirmed pod had 8 restarts with zero emails sent
kubectl get pod -n dev
# service-a   Running   8 (40m ago)   ← 8 restarts, no email!
```

### Root Cause
`AlertmanagerConfig` CR automatically injects `namespace="monitoring"` into every route. Since `service-a` runs in the `dev` namespace, its alerts carried `namespace="dev"` label and never matched any route — silently dropped to null.

```yaml
# What I configured:
- matchers:
  - alertname="PodRestart"

# What the operator actually applied:
- matchers:
  - alertname="PodRestart"
  - namespace="monitoring"  ← auto-injected, blocked dev namespace alerts
```

### Fix
Replaced `AlertmanagerConfig` CR with a direct Kubernetes Secret that the operator cannot override — routes now match alerts from any namespace:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-monitoring-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    route:
      routes:
      - matchers:
        - alertname="PodRestart"  # no namespace restriction — catches all namespaces
        receiver: 'send-email'
        repeat_interval: 5m
```

**Result**: Email delivered within 35 seconds. ✅

---

## 🎓 Key Things I Learned

- `AlertmanagerConfig` CR is **namespace-scoped by design** — cross-namespace alerting requires a direct Kubernetes Secret, not a CR
- Always verify the **live rendered config** (`alertmanager.env.yaml`), not just source manifests — the operator silently transforms what you wrote
- Kustomize keeps related manifests clean and manageable without Helm values complexity
- NGINX Ingress is more realistic for production than port-forwarding — services are accessible without CLI access
- Debugging order that works: logs → rendered config → UI → metric labels → routing rules

---

## 📸 Proof of Work

> Screenshots and evidence that this stack was fully deployed and working end-to-end.

### ✅ Alert Email Received
![Alert Email](proof/alert-email.png)
> Real email received in Gmail when service-a exceeded 2 restarts in the dev namespace.

### 📊 Grafana Dashboard
![Grafana Dashboard](proof/grafana-dashboard.png)
> Live metrics visualized in Grafana — CPU usage, memory, pod status across namespaces.

### 🔍 Prometheus Query Page
![Prometheus Queries](proof/prometheus-queries.png)
> Custom PromQL queries running against live cluster data.

### 🚨 Alertmanager UI
![Alertmanager UI](proof/alertmanager-ui.png)
> Alertmanager showing active alerts routed to send-email receiver.

---

## 🔜 Next Steps

- [ ] EFK Stack — log collection from all namespaces with Fluent Bit + Kibana dashboards
- [ ] Distributed tracing with Jaeger
- [ ] Slack webhook integration for team alerts
- [ ] Thanos for long-term Prometheus metric storage

---

## 📂 GitHub Portfolio

🔗 [github.com/AsadulCloud/azure-devops-portfolio](https://github.com/AsadulCloud/azure-devops-portfolio)

---

> 💡 I am actively looking for Junior Cloud/DevOps Engineer roles in Lisbon, Portugal.  
> Happy to walk through any part of this project in detail during a technical interview.