process.env.PORT = process.env.PORT || '4173';
process.env.NODE_ENV = process.env.NODE_ENV || 'test';
process.env.AUTH_ENABLED = process.env.AUTH_ENABLED || 'false';
process.env.SESSION_SECRET = process.env.SESSION_SECRET || 'e2e-session-secret';

const { startServer } = require('../src/server');

startServer();
