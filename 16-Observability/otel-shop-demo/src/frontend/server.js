'use strict';

const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');
const { ATTR_SERVICE_NAME } = require('@opentelemetry/semantic-conventions');
const express = require('express');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318';

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: 'frontend',
    'service.namespace': 'otel-shop-demo',
  }),
  traceExporter: new OTLPTraceExporter({
    url: `${endpoint}/v1/traces`,
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();

const PRODUCT_CATALOG_URL = process.env.PRODUCT_CATALOG_URL || 'http://localhost:8081';
const CART_URL = process.env.CART_URL || 'http://localhost:8082';
const RECOMMENDATION_URL = process.env.RECOMMENDATION_URL || 'http://localhost:8083';
const CHECKOUT_URL = process.env.CHECKOUT_URL || 'http://localhost:8084';

const app = express();
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Simple session / user id
app.use((req, res, next) => {
  let userId = req.headers['x-user-id'];
  if (!userId) {
    userId = uuidv4();
  }
  req.userId = userId;
  res.setHeader('X-User-Id', userId);
  next();
});

app.get('/api/products', async (req, res) => {
  try {
    const r = await fetch(`${PRODUCT_CATALOG_URL}/products`);
    const data = await r.json();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/recommendations', async (req, res) => {
  try {
    const r = await fetch(`${RECOMMENDATION_URL}/recommendations?user_id=${req.userId}&count=3`);
    const data = await r.json();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/cart', async (req, res) => {
  try {
    const r = await fetch(`${CART_URL}/cart/${req.userId}`);
    const data = await r.json();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/cart/add', async (req, res) => {
  try {
    const r = await fetch(`${CART_URL}/cart/add`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        user_id: req.userId,
        product_id: req.body.product_id,
        quantity: req.body.quantity || 1,
      }),
    });
    const data = await r.json();
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/checkout', async (req, res) => {
  try {
    const r = await fetch(`${CHECKOUT_URL}/checkout`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ user_id: req.userId }),
    });
    const data = await r.json();
    if (!r.ok) {
      return res.status(r.status).json(data);
    }
    res.json(data);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log(`frontend listening on :${port}`);
});
