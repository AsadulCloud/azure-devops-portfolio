import os
import random
import time
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

def setup_tracing():
    endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
    resource = Resource.create({
        "service.name": "payment",
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

app = FastAPI(title="Payment Service")
FastAPIInstrumentor.instrument_app(app)

class PaymentRequest(BaseModel):
    order_id: str
    amount: float
    currency: str = "USD"
    user_id: str

class PaymentResponse(BaseModel):
    transaction_id: str
    status: str
    order_id: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/charge", response_model=PaymentResponse)
def charge(req: PaymentRequest):
    with tracer.start_as_current_span("charge") as span:
        span.set_attribute("order.id", req.order_id)
        span.set_attribute("amount", req.amount)
        span.set_attribute("currency", req.currency)
        span.set_attribute("user.id", req.user_id)

        # Simulate some work
        time.sleep(random.uniform(0.05, 0.25))

        # Occasional failure for demo purposes (controlled by env)
        fail_rate = float(os.getenv("PAYMENT_FAIL_RATE", "0.05"))
        if random.random() < fail_rate:
            span.set_attribute("payment.status", "failed")
            raise HTTPException(status_code=402, detail="Payment declined")

        tx_id = str(uuid4())
        span.set_attribute("transaction.id", tx_id)
        span.set_attribute("payment.status", "success")

        return PaymentResponse(
            transaction_id=tx_id,
            status="success",
            order_id=req.order_id,
        )

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8085"))
    uvicorn.run(app, host="0.0.0.0", port=port)
