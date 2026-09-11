import os
from typing import Dict, List
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

# ---------- OpenTelemetry setup ----------
def setup_tracing():
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
    resource = Resource.create({
        "service.name": "cart",
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

app = FastAPI(title="Cart Service")
FastAPIInstrumentor.instrument_app(app)

# ---------- In-memory store ----------
# user_id -> list of items
carts: Dict[str, List[dict]] = {}

class CartItem(BaseModel):
    product_id: str
    quantity: int = 1

class AddItemRequest(BaseModel):
    user_id: str
    product_id: str
    quantity: int = 1

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/cart/{user_id}")
def get_cart(user_id: str):
    with tracer.start_as_current_span("get_cart") as span:
        span.set_attribute("user.id", user_id)
        items = carts.get(user_id, [])
        span.set_attribute("cart.item_count", len(items))
        return {"user_id": user_id, "items": items}

@app.post("/cart/add")
def add_item(req: AddItemRequest):
    with tracer.start_as_current_span("add_item") as span:
        span.set_attribute("user.id", req.user_id)
        span.set_attribute("product.id", req.product_id)
        span.set_attribute("quantity", req.quantity)

        if req.user_id not in carts:
            carts[req.user_id] = []

        # merge if already exists
        for item in carts[req.user_id]:
            if item["product_id"] == req.product_id:
                item["quantity"] += req.quantity
                return {"user_id": req.user_id, "items": carts[req.user_id]}

        carts[req.user_id].append({
            "product_id": req.product_id,
            "quantity": req.quantity,
        })
        return {"user_id": req.user_id, "items": carts[req.user_id]}

@app.delete("/cart/{user_id}")
def clear_cart(user_id: str):
    with tracer.start_as_current_span("clear_cart") as span:
        span.set_attribute("user.id", user_id)
        carts.pop(user_id, None)
        return {"status": "cleared"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8082"))
    uvicorn.run(app, host="0.0.0.0", port=port)
