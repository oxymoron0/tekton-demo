const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION || '1.0.0'
  });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Tekton CI/CD Pipeline!',
    environment: process.env.NODE_ENV || 'development',
    podName: process.env.POD_NAME || 'local'
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    service: 'sample-app',
    version: process.env.APP_VERSION || '1.0.0',
    buildTime: process.env.BUILD_TIME || 'unknown',
    commitHash: process.env.COMMIT_HASH || 'unknown'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});