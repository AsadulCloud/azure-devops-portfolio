const express = require('express');
const { createClient } = require('redis');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 4000;
const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';

let tasks = [];
let nextId = 1;

let publisher;

async function connectRedis() {
  publisher = createClient({ url: REDIS_URL });
  publisher.on('error', (err) => console.error('Redis Client Error', err));
  await publisher.connect();
  console.log('Connected to Redis at', REDIS_URL);
}

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'api-service', timestamp: new Date().toISOString() });
});

app.get('/api/tasks', (req, res) => {
  res.json(tasks);
});

app.post('/api/tasks', async (req, res) => {
  const { title } = req.body;
  if (!title) {
    return res.status(400).json({ error: 'title is required' });
  }

  const task = { id: nextId++, title, status: 'pending', createdAt: new Date().toISOString() };
  tasks.push(task);

  // Publish an event so the notification-service can react asynchronously,
  // instead of the API directly calling the notification service.
  // This is the key architectural difference from the voting app pattern.
  try {
    await publisher.publish('task-events', JSON.stringify({ type: 'TASK_CREATED', task }));
  } catch (err) {
    console.error('Failed to publish event:', err.message);
  }

  res.status(201).json(task);
});

app.patch('/api/tasks/:id/complete', async (req, res) => {
  const task = tasks.find((t) => t.id === parseInt(req.params.id, 10));
  if (!task) {
    return res.status(404).json({ error: 'task not found' });
  }
  task.status = 'completed';

  try {
    await publisher.publish('task-events', JSON.stringify({ type: 'TASK_COMPLETED', task }));
  } catch (err) {
    console.error('Failed to publish event:', err.message);
  }

  res.json(task);
});

connectRedis()
  .then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`api-service listening on port ${PORT}`);
    });
  })
  .catch((err) => {
    console.error('Failed to connect to Redis, exiting:', err);
    process.exit(1);
  });
