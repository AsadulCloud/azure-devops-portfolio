'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { ATTR_SERVICE_NAME } = require('@opentelemetry/semantic-conventions');
const { trace, context } = require('@opentelemetry/api');
const express = require('express');
const { v4: uuidv4 } = require('uuid');

// ---------- OpenTelemetry ----------
const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'checkout',
    'service.namespace': 'otel-shop-demo',
  }),
  traceExporter: new OTLPTraceExporter({
    url: `${endpoint}/v1/traces`,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

const tracer = trace.getTracer('checkout');

// ---------- Service URLs ----------
const CART_URL = process.env.CART_URL || 'http://localhost:8082';
const PRODUCT_CATALOG_URL = process.env.PRODUCT_CATALOG_URL || 'http://localhost:8081';
const PAYMENT_URL = process.env.PAYMENT_URL || 'http://localhost:8085';

const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.post('/checkout', async (req, res) => {
  const span = tracer.startSpan('checkout');
  const ctx = trace.setSpan(context.active(), span);

  try {
    const { user_id } = req.body;
    if (!user_id) {
      span.setAttribute('error', true);
      return res.status(400).json({ error: 'user_id is required' });
    }

    span.setAttribute('user.id', user_id);

    // 1. Get cart
    const cartResp = await fetch(`${CART_URL}/cart/${user_id}`);
    if (!cartResp.ok) throw new Error('Failed to fetch cart');
    const cart = await cartResp.json();

    if (!cart.items || cart.items.length === 0) {
      span.setAttribute('cart.empty', true);
      return res.status(400).json({ error: 'cart is empty' });
    }

    // 2. Enrich items with product details + calculate total
    let total = 0;
    const orderItems = [];

    for (const item of cart.items) {
      const prodResp = await fetch(`${PRODUCT_CATALOG_URL}/products/${item.product_id}`);
      if (!prodResp.ok) throw new Error(`Product ${item.product_id} not found`);
      const product = await prodResp.json();

      const lineTotal = product.price * item.quantity;
      total += lineTotal;
      orderItems.push({
        product_id: product.id,
        name: product.name,
        quantity: item.quantity,
        unit_price: product.price,
        line_total: lineTotal,
      });
    }

    span.setAttribute('order.total', total);
    span.setAttribute('order.item_count', orderItems.length);

    const orderId = uuidv4();

    // 3. Charge payment
    const paymentResp = await fetch(`${PAYMENT_URL}/charge`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        order_id: orderId,
        amount: total,
        currency: 'USD',
        user_id,
      }),
    });

    if (!paymentResp.ok) {
      const errBody = await paymentResp.text();
      span.setAttribute('payment.failed', true);
      throw new Error(`Payment failed: ${errBody}`);
    }

    const payment = await paymentResp.json();

    // 4. Clear cart
    await fetch(`${CART_URL}/cart/${user_id}`, { method: 'DELETE' });

    span.setAttribute('order.id', orderId);
    span.setAttribute('transaction.id', payment.transaction_id);

    res.json({
      order_id: orderId,
      status: 'completed',
      total,
      items: orderItems,
      transaction_id: payment.transaction_id,
    });
  } catch (err) {
    span.recordException(err);
    span.setAttribute('error', true);
    console.error(err);
    res.status(500).json({ error: err.message || 'checkout failed' });
  } finally {
    span.end();
  }
});

const port = process.env.PORT || 8084;
app.listen(port, () => {
  console.log(`checkout listening on :${port}`);
});

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((err) => console.error('Error terminating tracing', err))
    .finally(() => process.exit(0));
});
