const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.send(`
    <h1>Asadul's CI/CD Portfolio App</h1>
    <p>Deployed via Terraform + Azure DevOps + AKS</p>
    <p>Try <a href="/api/status">/api/status</a></p>
  `);
});

app.get('/api/status', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
