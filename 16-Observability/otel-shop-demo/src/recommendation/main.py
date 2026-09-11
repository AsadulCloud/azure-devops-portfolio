import os
import random
from typing import List

import httpx
from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

def setup_tracing():
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
    resource = Resource.create({
        "service.name": "recommendation",
        "service.namespace": "otel-shop-demo",
    })
    provider = TracerProvider(resource=resource)
    processor = BatchSpanProcessor(
        OTLPSpanExporter(endpoint=f"{endpoint}/v1/traces")
    )
    provider.add_span_processor(processor)
    trace.set_tracer_provider(provider)

setup_tracing()
tracer = trace.get_tracer(__name__)
HTTPXClientInstrumentor().instrument()

app = FastAPI(title="Recommendation Service")
FastAPIInstrumentor.instrument_app(app)

PRODUCT_CATALOG_URL = os.getenv("PRODUCT_CATALOG_URL", "http://localhost:8081")

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/recommendations")
async def get_recommendations(user_id: str = "anonymous", count: int = 3):
    with tracer.start_as_current_span("get_recommendations") as span:
        span.set_attribute("user.id", user_id)
        span.set_attribute("count", count)

        async with httpx.AsyncClient() as client:
            resp = await client.get(f"{PRODUCT_CATALOG_URL}/products")
            resp.raise_for_status()
            products = resp.json()

        # Simple random recommendation (demo only)
        selected = random.sample(products, min(count, len(products)))
        span.set_attribute("recommendation.count", len(selected))
        return {"user_id": user_id, "recommendations": selected}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8083"))
    uvicorn.run(app, host="0.0.0.0", port=port)
