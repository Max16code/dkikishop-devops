const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('<h1>íº€ DevOps Showcase App</h1><p>Successfully deployed via GitHub Actions + Docker to AWS EC2!</p><p><a href="/health">Health Check</a></p>');
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(PORT, () => {
  console.log(`âœ… App running on http://localhost:${PORT}`);
});
