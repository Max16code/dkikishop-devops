const express = require('express');
const os = require('os');
const app = express();
const PORT = process.env.PORT || 3000;
const ENVIRONMENT = process.env.ENVIRONMENT || 'development';

// Health check endpoint (required by ALB and Docker HEALTHCHECK)
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: ENVIRONMENT
  });
});

// Readiness probe (for rolling updates)
app.get('/ready', (req, res) => {
  res.status(200).json({
    status: 'ready',
    uptime: process.uptime()
  });
});

// Main route
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>DevOps Showcase App</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
          .success { color: green; }
          .info { background: #f0f0f0; padding: 20px; border-radius: 10px; display: inline-block; }
          table { margin: 20px auto; text-align: left; }
          td { padding: 5px 15px; }
        </style>
      </head>
      <body>
        <h1>🚀 DevOps Showcase App</h1>
        <div class="info">
          <h2>✅ Deployment Successful!</h2>
          <table>
            <tr><td><strong>Environment:</strong></td><td>${ENVIRONMENT}</td></tr>
            <tr><td><strong>Hostname:</strong></td><td>${os.hostname()}</td></tr>
            <tr><td><strong>Platform:</strong></td><td>${os.platform()}</td></tr>
            <tr><td><strong>Uptime:</strong></td><td>${Math.floor(process.uptime())} seconds</td></tr>
            <tr><td><strong>Node Version:</strong></td><td>${process.version}</td></tr>
          </table>
          <p>
            <a href="/health">🔍 Health Check</a> | 
            <a href="/ready">✅ Readiness Probe</a>
          </p>
        </div>
        <p>Deployed via: <strong>GitHub Actions + Docker + Terraform + AWS EC2</strong></p>
      </body>
    </html>
  `);
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

app.listen(PORT, () => {
  console.log(`
  ╔════════════════════════════════════════╗
  ║   🚀 App Started Successfully          ║
  ╠════════════════════════════════════════╣
  ║   Environment: ${ENVIRONMENT.padEnd(20)}║
  ║   Port:        ${String(PORT).padEnd(20)}║
  ║   Health:      http://localhost:${PORT}/health ║
  ╚════════════════════════════════════════╝
  `);
});

module.exports = app;