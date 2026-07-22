const { createClient } = require('redis');
const express = require('express');

const REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379';
const PORT = process.env.PORT || 5000;

// Tiny in-memory log of "notifications sent", exposed via HTTP so you can
// prove the worker actually reacted to events, without needing to read pod logs.
let notificationLog = [];

const app = express();

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'notification-service', timestamp: new Date().toISOString() });
});

app.get('/api/notifications', (req, res) => {
  res.json(notificationLog);
});

async function main() {
  const subscriber = createClient({ url: REDIS_URL });
  subscriber.on('error', (err) => console.error('Redis Client Error', err));
  await subscriber.connect();
  console.log('Connected to Redis at', REDIS_URL);

  await subscriber.subscribe('task-events', (message) => {
    const event = JSON.parse(message);
    let notification;

    if (event.type === 'TASK_CREATED') {
      notification = `New task created: "${event.task.title}" (id ${event.task.id})`;
    } else if (event.type === 'TASK_COMPLETED') {
      notification = `Task completed: "${event.task.title}" (id ${event.task.id})`;
    } else {
      notification = `Unknown event received: ${event.type}`;
    }

    console.log('[notification]', notification);
    notificationLog.push({ notification, receivedAt: new Date().toISOString() });
    // keep the log from growing forever
    if (notificationLog.length > 100) notificationLog.shift();
  });

  console.log('Subscribed to task-events channel');
}

app.listen(PORT, '0.0.0.0', () => {
  console.log(`notification-service HTTP endpoint listening on port ${PORT}`);
});

main().catch((err) => {
  console.error('Fatal error in notification-service:', err);
  process.exit(1);
});
