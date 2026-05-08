const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

// Import the Express app without starting the HTTP listener.
// server.js guards startServer() behind require.main === module when required
// as a module, so no port is bound during tests.
const { app } = require('../src/server');

// ─── GET /healthz ─────────────────────────────────────────────────────────────

test('GET /healthz returns 200 with service status payload', async () => {
  const res = await request(app).get('/healthz');
  assert.equal(res.status, 200);
  assert.equal(res.body.status, 'ok');
  assert.equal(res.body.service, 'capacity-dashboard-api');
});

// ─── GET /api/auth/me ─────────────────────────────────────────────────────────

test('GET /api/auth/me returns 200 with auth state when AUTH_ENABLED is false', async () => {
  const res = await request(app).get('/api/auth/me');
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  assert.equal(res.body.auth.authEnabled, false);
  assert.equal(res.body.auth.isAuthenticated, true);
  assert.equal(res.body.auth.name, null);
  assert.equal(res.body.auth.username, null);
});

// ─── GET /api/capacity ────────────────────────────────────────────────────────

// Without SQL configured, capacityService falls back to in-memory mock rows,
// so the endpoint returns 200 with a rows array (may be empty or populated).
test('GET /api/capacity returns 200 with rows array when no SQL is configured', async () => {
  const res = await request(app).get('/api/capacity');
  assert.equal(res.status, 200);
  assert.ok(Array.isArray(res.body.rows), 'response body should have a rows array');
});

// ─── GET /api/sku-catalog/families ───────────────────────────────────────────

// This route is intentionally excluded from auth middleware. It returns either
// a catalog payload (200) or a 503 if the catalog fetch fails — either is
// acceptable in a unit/smoke test environment.
test('GET /api/sku-catalog/families responds without 401', async () => {
  const res = await request(app).get('/api/sku-catalog/families');
  assert.notEqual(res.status, 401);
  assert.notEqual(res.status, 404);
});

// ─── Auth guard on protected routes ──────────────────────────────────────────

// With AUTH_ENABLED=false the middleware calls next() for all /api paths, so
// protected routes should not return 401.
test('GET /api/subscriptions does not return 401 when AUTH_ENABLED is false', async () => {
  const res = await request(app).get('/api/subscriptions');
  assert.notEqual(res.status, 401);
});
