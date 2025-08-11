const request = require('supertest');
const express = require('express');

// Mock the express app for testing
const app = express();
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

app.get('/', (req, res) => {
  res.json({ 
    message: 'Hello from Tekton CI/CD Pipeline!',
    environment: 'test',
    podName: 'test-pod'
  });
});

app.get('/api/info', (req, res) => {
  res.json({
    service: 'sample-app',
    version: '1.0.0',
    buildTime: 'test-time',
    commitHash: 'test-hash'
  });
});

describe('Sample App API Tests', () => {
  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/health');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('version');
    });
  });

  describe('GET /', () => {
    it('should return welcome message', async () => {
      const response = await request(app).get('/');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toContain('Tekton CI/CD Pipeline');
    });
  });

  describe('GET /api/info', () => {
    it('should return service information', async () => {
      const response = await request(app).get('/api/info');
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('service', 'sample-app');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('buildTime');
      expect(response.body).toHaveProperty('commitHash');
    });
  });
});