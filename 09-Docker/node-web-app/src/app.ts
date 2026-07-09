import express, { Request, Response } from 'express';

const app = express();
const PORT = Number(process.env.PORT) || 3000;

app.use(express.json());

app.get('/', (req: Request, res: Response) => {
  res.send(`
    <h1>Hello from Asadul's Node.js App!</h1>
    <p>This app is running inside a Docker container.</p>
    <p>Try <a href="/api/status">/api/status</a> or <a href="/api/greet?name=Asadul">/api/greet?name=Asadul</a></p>
  `);
});

app.get('/api/status', (req: Request, res: Response) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/greet', (req: Request, res: Response) => {
  const name = (req.query.name as string) || 'World';
  res.json({ message: `Hello, ${name}!` });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
});
