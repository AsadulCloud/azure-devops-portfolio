# OTel Shop Demo

A simplified OpenTelemetry microservices demo inspired by the official [OpenTelemetry Astronomy Shop Demo](https://github.com/open-telemetry/opentelemetry-demo).

This version is intentionally smaller and easier to own:

- 5 backend services + frontend
- REST/HTTP only (no gRPC/protobufs)
- OpenTelemetry traces + basic metrics
- Ready for you to add **Dockerfiles** and **Kubernetes manifests**

## Architecture

```
                    ┌─────────────┐
                    │  Frontend   │  (Node.js + simple UI)
                    └──────┬──────┘
           ┌──────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
   ┌─────────────┐ ┌──────────┐ ┌────────────────┐
   │ Product      │ │   Cart   │ │ Recommendation  │
   │ Catalog (Go) │ │ (Python) │ │    (Python)     │
   └─────────────┘ └──────────┘ └────────────────┘
           │               │
           │               │
           └───────┬───────┘
                   ▼
            ┌────────────┐
            │  Checkout  │  (Node.js)
            └──────┬─────┘
                   │
                   ▼
            ┌────────────┐
            │  Payment   │  (Python)
            └────────────┘
```

### Services

| Service            | Language   | Port  | Description                          |
|--------------------|------------|-------|--------------------------------------|
| frontend           | Node.js    | 8080  | Simple web UI + API gateway          |
| product-catalog    | Go         | 8081  | List / get products                  |
| cart               | Python     | 8082  | Shopping cart (in-memory)            |
| recommendation     | Python     | 8083  | Product recommendations              |
| checkout           | Node.js    | 8084  | Place order (orchestrates others)    |
| payment            | Python     | 8085  | Mock payment processing              |

## OpenTelemetry

Every service is instrumented with OpenTelemetry and exports to an OTLP endpoint.

Default environment variables (override as needed):

```bash
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
OTEL_SERVICE_NAME=<service-name>
OTEL_RESOURCE_ATTRIBUTES=service.namespace=otel-shop-demo
```

You can point all services at a real OpenTelemetry Collector, Jaeger, Grafana Tempo, etc.

## Quick local run (without Docker)

You need Go, Node.js (18+), and Python 3.10+.

```bash
# Terminal 1 – Product Catalog
cd src/product-catalog
go run .

# Terminal 2 – Cart
cd src/cart
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8082

# Terminal 3 – Recommendation
cd src/recommendation
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8083

# Terminal 4 – Payment
cd src/payment
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8085

# Terminal 5 – Checkout
cd src/checkout
npm install
npm start

# Terminal 6 – Frontend
cd src/frontend
npm install
npm start
```

Then open http://localhost:8080

## What you should add

1. **Dockerfile** for each service under `src/<service>/Dockerfile`
2. **Kubernetes manifests** under `k8s/` (Deployments, Services, ConfigMaps, etc.)
3. Optional: `docker-compose.yml` expansion, Helm chart, OpenTelemetry Collector config, load generator

## Feature ideas (optional later)

- Add Redis for the cart
- Feature flags (simple env-based or OpenFeature)
- Intentional failures (random 5xx, latency) controlled by env vars
- Kafka / message queue for order events
- More languages (Java, .NET, Rust…)

## License

Apache-2.0 (same spirit as the official demo)
