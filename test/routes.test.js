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

// ─── GET /api/capacity/export ─────────────────────────────────────────────────

// CSV export — default format (no ?format param) — returns text/csv attachment.
test('GET /api/capacity/export returns CSV with correct Content-Type by default', async () => {
  const res = await request(app).get('/api/capacity/export');
  assert.equal(res.status, 200);
  assert.ok(
    String(res.headers['content-type'] || '').startsWith('text/csv'),
    `expected text/csv, got ${res.headers['content-type']}`
  );
  assert.ok(
    String(res.headers['content-disposition'] || '').includes('attachment'),
    'content-disposition should indicate attachment'
  );
  assert.ok(
    String(res.headers['content-disposition'] || '').includes('.csv'),
    'content-disposition filename should end with .csv'
  );
});

// CSV export — explicit ?format=csv.
test('GET /api/capacity/export?format=csv returns text/csv', async () => {
  const res = await request(app).get('/api/capacity/export?format=csv');
  assert.equal(res.status, 200);
  assert.ok(String(res.headers['content-type'] || '').startsWith('text/csv'));
});

// XLSX grid export — returns OOXML Content-Type.
test('GET /api/capacity/export?format=xlsx returns XLSX Content-Type', async () => {
  const res = await request(app).get('/api/capacity/export?format=xlsx&variant=grid');
  assert.equal(res.status, 200);
  assert.ok(
    String(res.headers['content-type'] || '').includes('spreadsheetml'),
    `expected spreadsheetml content-type, got ${res.headers['content-type']}`
  );
  assert.ok(
    String(res.headers['content-disposition'] || '').includes('.xlsx'),
    'content-disposition filename should end with .xlsx'
  );
});

// XLSX report export — multi-sheet workbook with report summary.
test('GET /api/capacity/export?format=xlsx&variant=report returns XLSX attachment with report prefix', async () => {
  const res = await request(app).get('/api/capacity/export?format=xlsx&variant=report');
  assert.equal(res.status, 200);
  assert.ok(String(res.headers['content-type'] || '').includes('spreadsheetml'));
  assert.ok(
    String(res.headers['content-disposition'] || '').includes('capacity-dashboard-report'),
    'report variant should use capacity-dashboard-report filename prefix'
  );
});

// Unknown/invalid format values default to CSV — the route must not 400.
test('GET /api/capacity/export?format=invalid falls back to CSV without error', async () => {
  const res = await request(app).get('/api/capacity/export?format=invalid');
  assert.equal(res.status, 200);
  assert.ok(String(res.headers['content-type'] || '').startsWith('text/csv'));
});

// X-Export-Truncated is not set when row count is within the 50k cap.
// Mock data is always well below 50 000 rows, so the header must be absent.
test('GET /api/capacity/export does not set X-Export-Truncated when below cap', async () => {
  const res = await request(app).get('/api/capacity/export');
  assert.equal(res.status, 200);
  assert.equal(
    res.headers['x-export-truncated'],
    undefined,
    'X-Export-Truncated should not be set for small result sets'
  );
});

// ─── Auth guard on protected routes ──────────────────────────────────────────

// With AUTH_ENABLED=false the middleware calls next() for all /api paths, so
// protected routes should not return 401.
test('GET /api/subscriptions does not return 401 when AUTH_ENABLED is false', async () => {
  const res = await request(app).get('/api/subscriptions');
  assert.notEqual(res.status, 401);
});

// ─── GET /api/admin/config ────────────────────────────────────────────────────

test('GET /api/admin/config returns 200 with sanitized config shape when AUTH_ENABLED is false', async () => {
  const res = await request(app).get('/api/admin/config');
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);

  const { config } = res.body;
  assert.ok(config, 'response body should have a config object');

  // Top-level sections present
  assert.ok(config.server, 'config.server section should be present');
  assert.ok(config.auth, 'config.auth section should be present');
  assert.ok(config.sql, 'config.sql section should be present');
  assert.ok(config.ingest, 'config.ingest section should be present');
  assert.ok(config.quota, 'config.quota section should be present');
  assert.ok(config.livePlacement, 'config.livePlacement section should be present');

  // Secrets must never be returned verbatim — only "set" or "not set"
  const ALLOWED_SECRET_VALUES = new Set(['set', 'not set']);
  assert.ok(ALLOWED_SECRET_VALUES.has(config.auth.entraClientSecret), 'entraClientSecret must be "set" or "not set"');
  assert.ok(ALLOWED_SECRET_VALUES.has(config.auth.adminGroupId), 'adminGroupId must be "set" or "not set"');
  assert.ok(ALLOWED_SECRET_VALUES.has(config.ingest.apiKey), 'ingest.apiKey must be "set" or "not set"');
  assert.ok(ALLOWED_SECRET_VALUES.has(config.quota.managementGroupId), 'quota.managementGroupId must be "set" or "not set"');

  // sql.poolReady must be a boolean
  assert.equal(typeof config.sql.poolReady, 'boolean', 'sql.poolReady must be a boolean');

  // auth.authEnabled must be a boolean
  assert.equal(typeof config.auth.authEnabled, 'boolean', 'auth.authEnabled must be a boolean');

  // appInsights section must be present with a boolean configured field
  assert.ok(config.appInsights, 'config.appInsights section should be present');
  assert.equal(typeof config.appInsights.configured, 'boolean', 'appInsights.configured must be a boolean');

  // ingestion status section must be present
  assert.ok(config.ingestion, 'config.ingestion section should be present');
  assert.ok(['never', 'success', 'error'].includes(config.ingestion.lastRunStatus), 'lastRunStatus must be never/success/error');
  assert.equal(typeof config.ingestion.inProgress, 'boolean', 'ingestion.inProgress must be a boolean');
  assert.equal(typeof config.ingestion.regionErrorCount, 'number', 'regionErrorCount must be a number');
});

// ─── GET /api/admin/config — ingestion status section ───────────────────────

test('GET /api/admin/config ingestion section present with correct cold-start shape', async () => {
  const res = await request(app).get('/api/admin/config');
  assert.equal(res.status, 200);
  const { ingestion } = res.body.config;
  assert.ok(ingestion, 'config.ingestion section should be present');
  assert.equal(ingestion.lastRunStatus, 'never', 'lastRunStatus should be "never" before any ingestion run');
  assert.equal(ingestion.lastRunAt, null, 'lastRunAt should be null before any ingestion run');
  assert.equal(ingestion.lastRunRecords, null, 'lastRunRecords should be null before any ingestion run');
  assert.equal(ingestion.lastErrorMessage, null, 'lastErrorMessage should be null before any ingestion run');
  assert.equal(typeof ingestion.inProgress, 'boolean', 'inProgress must be a boolean');
  assert.equal(typeof ingestion.regionErrorCount, 'number', 'regionErrorCount must be a number');
  assert.equal(ingestion.regionErrorCount, 0, 'regionErrorCount should be 0 on cold start');
});


test('GET /api/admin/config appInsights.configured is false when APPLICATIONINSIGHTS_CONNECTION_STRING is not set', async () => {
  const saved = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  delete process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;

  try {
    const res = await request(app).get('/api/admin/config');
    assert.equal(res.status, 200);
    assert.equal(res.body.config.appInsights.configured, false,
      'appInsights.configured should be false when env var is absent');
  } finally {
    if (saved !== undefined) process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = saved;
  }
});

test('GET /api/admin/config appInsights.configured is true when APPLICATIONINSIGHTS_CONNECTION_STRING is set', async () => {
  const saved = process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
  process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = 'InstrumentationKey=fake-key;IngestionEndpoint=https://fake.in.applicationinsights.azure.com/';

  try {
    const res = await request(app).get('/api/admin/config');
    assert.equal(res.status, 200);
    assert.equal(res.body.config.appInsights.configured, true,
      'appInsights.configured should be true when env var is set');
    // Verify the actual connection string value is NOT in the response
    const body = JSON.stringify(res.body);
    assert.ok(!body.includes('fake-key'), 'connection string value must not appear in response');
  } finally {
    if (saved !== undefined) {
      process.env.APPLICATIONINSIGHTS_CONNECTION_STRING = saved;
    } else {
      delete process.env.APPLICATIONINSIGHTS_CONNECTION_STRING;
    }
  }
});
