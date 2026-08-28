# Prometheus & Grafana Monitoring — service-a

A hands-on monitoring setup showing Prometheus metrics collection and a
custom Grafana dashboard built from scratch, covering request rate, error
rate, latency, and pod health for `service-a`.

---

## Part 1 — Explore metrics directly in Prometheus

Before building the dashboard, run these in the **Prometheus UI**
(e.g. `http://demo.<ingress-ip>.nip.io/prometheus/graph`) — this is the
"I can read raw metrics and write queries" skill interviewers probe for.

### 1. Total requests (Counter)

```promql
http_requests_total
```

Run it, switch to **Graph** view — this is a raw cumulative counter, always
going up. Not useful on its own; the next query fixes that.

### 2. Request rate — requests per second, over a 5-minute window

```promql
sum(rate(http_requests_total{service="a-service"}[5m]))
```

`rate()` turns the ever-increasing counter into a per-second rate — the
single most important PromQL pattern:

> Counters only go up, so you always wrap them in `rate()` to get something meaningful over time.

### 3. Request rate broken down by endpoint

```promql
sum(rate(http_requests_total{service="a-service"}[5m])) by (path)
```

Shows which routes are getting traffic — good for a "traffic by endpoint" panel.

### 4. Error rate as a percentage

```promql
sum(rate(http_requests_total{service="a-service", status_code=~"5.."}[5m]))
/
sum(rate(http_requests_total{service="a-service"}[5m]))
* 100
```

Filters to 5xx responses only, divides by total, multiplies by 100.
Trigger some `/serverError` requests first so this shows a non-zero value.

### 5. p95 latency (95th percentile response time)

```promql
histogram_quantile(0.95,
  sum(rate(http_request_duration_seconds_bucket{service="a-service"}[5m])) by (le)
)
```

This is the query that justifies using a **Histogram** metric type:

> 95% of requests complete faster than this value.

### 6. Pod restarts in the last hour

```promql
increase(kube_pod_container_status_restarts_total{namespace="dev"}[1h])
```

Trigger `/crash` once, wait a minute, re-run — you'll see it tick up.

### 7. Node CPU usage

```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Comes from `node-exporter` (included with kube-prometheus-stack) — useful
for a general cluster-health panel.

---

## Part 2 — Build the Grafana dashboard by hand

Go to Grafana → **Dashboards → New → New Dashboard → Add visualization** →
select your **Prometheus** data source (wired up via the same Helm release).

Build these 6 panels — for each, paste the PromQL query from Part 1 into
the panel's query editor:

| # | Panel title | Query | Visualization type | Why this panel |
|---|---|---|---|---|
| 1 | Request Rate | Query 2 | Time series | Traffic volume over time |
| 2 | Requests by Endpoint | Query 3 | Time series (stacked) | Which routes get hit |
| 3 | Error Rate % | Query 4 | Time series, unit = Percent | Immediately shows problems |
| 4 | p95 Latency | Query 5 | Time series, unit = seconds | Performance over time |
| 5 | Pod Restarts (1h) | Query 6 | Stat (single number) | Quick health check |
| 6 | Node CPU Usage | Query 7 | Gauge, unit = Percent | Infra-level health |

**For each panel**, also set:

- A clear title (not the raw query)
- The correct unit (Grafana unit dropdown — seconds, percent, req/s)
- A sensible time range default (Last 30 minutes, refresh every 10s)

Once all 6 panels are placed, **Save Dashboard** → name it
`service-a Monitoring Overview` → add a description.

---

## Part 3 — Generate traffic so the dashboard shows data

Static/empty panels don't demonstrate anything. Run the traffic script while
the dashboard is open so panels update live (good for a portfolio GIF/demo):

```bash
chmod +x generate-traffic.sh
./generate-traffic.sh http://demo.<ingress-ip>.nip.io/service-a
```

Or with the default base URL inside the script. Watch Request Rate and
Error Rate panels move in real time.

---

## Part 4 — Export the dashboard as JSON (dashboard-as-code)

Grafana → your dashboard → **Dashboard settings (gear)** → **JSON Model** →
copy the JSON → save under `dashboards/` (this repo already includes an
exported dashboard):

- [`dashboards/service-a-Monitoring-Overview-1787915013636.json`](dashboards/service-a-Monitoring-Overview-1787915013636.json)

Why this matters for the portfolio:

- Shows **dashboard as code** — dashboards in version control, not only in the UI
- Anyone can clone the repo and import the same dashboard into Grafana

---

## Interview talking points

- Why `rate()` is required for counters
- Why histograms need `histogram_quantile()` (vs gauges/counters)
- Difference between raw `http_requests_total` and a rate panel
- How ServiceMonitor discovers targets without hardcoding scrape configs
- How this dashboard pairs with Alertmanager rules (HighCpuUsage, PodRestart)
