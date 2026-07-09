const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Home route
app.get('/', (req, res) => {
  res.send(`
    <h1>Hello from Asadul's Node.js App!</h1>
    <p>This app is running inside a Docker container.</p>
    <p>Try <a href="/api/status">/api/status</a> or <a href="/api/greet?name=Asadul">/api/greet?name=Asadul</a></p>
  `);
});

// Health check route - useful for Docker/Kubernetes readiness checks
app.get('/api/status', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Simple greeting route with query param
app.get('/api/greet', (req, res) => {
  const name = req.query.name || 'World';
  res.json({ message: `Hello, ${name}!` });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
