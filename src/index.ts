import express from 'express';
import client from 'prom-client';

const app = express();
const port = parseInt(process.env.PORT || '8080', 10);

const register = new client.Registry();
register.setDefaultLabels({
  app: 'ron-zbd-challenge'
});

const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

register.registerMetric(httpRequestCounter);

app.get('/health', (req, res) => {
  httpRequestCounter.inc({ method: 'GET', route: '/health', status_code: 200 });
  res.status(200).json({
    statusCode: 200,
    message: "I'm healthy",
    metadata: {
      timestamp: new Date().toISOString(),
      ip: req.ip || req.socket.remoteAddress,
      userAgent: req.get('user-agent'),
      method: req.method,
      path: req.path,
      protocol: req.protocol,
      hostname: req.hostname
    }
  });
});

app.get('/metrics', async (req, res) => {
  httpRequestCounter.inc({ method: 'GET', route: '/metrics', status_code: 200 });
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.get('/hello', (req, res) => {
  httpRequestCounter.inc({ method: 'GET', route: '/hello', status_code: 200 });
  res.status(200).json({
    statusCode: 200,
    message: "Hello, world!",
    metadata: {
      timestamp: new Date().toISOString(),
      ip: req.ip || req.socket.remoteAddress,
      userAgent: req.get('user-agent'),
      method: req.method,
      path: req.path,
      protocol: req.protocol,
      hostname: req.hostname
    }
  });
});

app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
  console.log(`Environment: PORT=${port}`);
});
