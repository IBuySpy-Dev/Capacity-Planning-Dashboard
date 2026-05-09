const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

const { app } = require('../src/server');

// Mock data reference (from src/store/mockCapacity.js):
//   eastus  / Standard_D4s_v5  — OK,          quota 22/100  → headroom 78  → score High  (100)
//   eastus2 / Standard_E8s_v5  — LIMITED,      quota 40/80   → headroom 40  → score Medium (60)
//   centralus / Standard_D16s_v5 — CONSTRAINED, quota 75/80  → headroom  5  → score Medium (60)
//   westus2 / Standard_F8s_v2  — OK,           quota 18/120  → headroom 102 → score High  (100)
//   centralus / Standard_D4s_v4 — OK,          quota 12/120  → headroom 108 → score High  (100)

// ─── Input validation ─────────────────────────────────────────────────────────

test('POST /api/capacity/preflight returns 400 when resources is missing', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({});
  assert.equal(res.status, 400);
  assert.equal(res.body.ok, false);
  assert.ok(res.body.error, 'error message should be present');
});

test('POST /api/capacity/preflight returns 400 when resources is an empty array', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [] });
  assert.equal(res.status, 400);
  assert.equal(res.body.ok, false);
});

test('POST /api/capacity/preflight returns 400 when a resource is missing sku', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ region: 'eastus', count: 1 }] });
  assert.equal(res.status, 400);
  assert.equal(res.body.ok, false);
});

test('POST /api/capacity/preflight returns 400 when a resource is missing region', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', count: 1 }] });
  assert.equal(res.status, 400);
  assert.equal(res.body.ok, false);
});

test('POST /api/capacity/preflight returns 400 when a resource is missing count', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus' }] });
  assert.equal(res.status, 400);
  assert.equal(res.body.ok, false);
});

// ─── Successful go verdict ────────────────────────────────────────────────────

test('POST /api/capacity/preflight returns 200 with correct shape', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }] });
  assert.equal(res.status, 200);
  assert.equal(res.body.ok, true);
  assert.equal(typeof res.body.go, 'boolean');
  assert.ok(Array.isArray(res.body.resources), 'resources must be an array');
  assert.equal(res.body.resources.length, 1);
});

test('POST /api/capacity/preflight assigns go verdict when score is High and quota is sufficient', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }],
      options: { minScore: 60 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.equal(item.sku, 'Standard_D4s_v5');
  assert.equal(item.region, 'eastus');
  assert.equal(item.verdict, 'go');
  assert.equal(res.body.go, true);
});

test('POST /api/capacity/preflight sets top-level go=true when all resources are go', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [
        { sku: 'Standard_D4s_v5', region: 'eastus', count: 1 },
        { sku: 'Standard_D4s_v4', region: 'centralus', count: 1 }
      ],
      options: { minScore: 60 }
    });
  assert.equal(res.status, 200);
  assert.equal(res.body.go, true);
  assert.equal(res.body.resources.length, 2);
  assert.ok(
    res.body.resources.every((r) => r.verdict === 'go' || r.verdict === 'warn'),
    'no resource should have verdict no-go when go=true'
  );
});

// ─── No-go verdict ────────────────────────────────────────────────────────────

test('POST /api/capacity/preflight assigns no-go verdict when requested count exceeds quota headroom', async () => {
  // eastus / Standard_D4s_v5 has headroom of 78 — requesting 200 must trigger no-go
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 200 }],
      options: { minScore: 60 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.equal(item.verdict, 'no-go');
  assert.equal(res.body.go, false);
});

test('POST /api/capacity/preflight assigns no-go verdict for unknown SKU', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_Unknown_SKU_9999', region: 'eastus', count: 1 }],
      options: { minScore: 60 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.equal(item.verdict, 'no-go', 'unknown SKU has no capacity data and should be no-go');
  assert.equal(res.body.go, false);
});

test('POST /api/capacity/preflight sets top-level go=false when any resource is no-go', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [
        { sku: 'Standard_D4s_v5', region: 'eastus', count: 1 },      // go
        { sku: 'Standard_D4s_v5', region: 'eastus', count: 9999 }     // no-go (headroom exceeded)
      ],
      options: { minScore: 60 }
    });
  assert.equal(res.status, 200);
  assert.equal(res.body.go, false);
});

// ─── Resource result shape ────────────────────────────────────────────────────

test('POST /api/capacity/preflight each resource result includes required fields', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }] });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.ok('sku' in item, 'sku field required');
  assert.ok('region' in item, 'region field required');
  assert.ok('count' in item, 'count field required');
  assert.ok('score' in item, 'score field required');
  assert.ok('scoreLabel' in item, 'scoreLabel field required');
  assert.ok('quotaHeadroom' in item, 'quotaHeadroom field required');
  assert.ok('verdict' in item, 'verdict field required');
  assert.ok('reason' in item, 'reason field required');
  assert.ok(Array.isArray(item.alternatives), 'alternatives must be an array');
});

test('POST /api/capacity/preflight score is a number and scoreLabel is a string', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }] });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.equal(typeof item.score, 'number');
  assert.equal(typeof item.scoreLabel, 'string');
  assert.ok(['High', 'Medium', 'Low'].includes(item.scoreLabel));
});

test('POST /api/capacity/preflight verdict is one of go/warn/no-go', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }] });
  assert.equal(res.status, 200);
  assert.ok(['go', 'warn', 'no-go'].includes(res.body.resources[0].verdict));
});

// ─── Alternatives ─────────────────────────────────────────────────────────────

test('POST /api/capacity/preflight alternatives are capped by topAlternatives option', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_D16s_v5', region: 'centralus', count: 1 }],
      options: { topAlternatives: 1 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  assert.ok(item.alternatives.length <= 1, 'alternatives should not exceed topAlternatives');
});

test('POST /api/capacity/preflight alternative entries include sku, region, score, scoreLabel, quotaHeadroom', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_D16s_v5', region: 'centralus', count: 1 }],
      options: { topAlternatives: 5 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  if (item.alternatives.length > 0) {
    const alt = item.alternatives[0];
    assert.ok('sku' in alt, 'alternative sku required');
    assert.ok('region' in alt, 'alternative region required');
    assert.ok('score' in alt, 'alternative score required');
    assert.ok('scoreLabel' in alt, 'alternative scoreLabel required');
    assert.ok('quotaHeadroom' in alt, 'alternative quotaHeadroom required');
    assert.equal(typeof alt.score, 'number');
  }
});

test('POST /api/capacity/preflight alternatives do not include the requested SKU', async () => {
  const sku = 'Standard_D16s_v5';
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku, region: 'centralus', count: 1 }],
      options: { topAlternatives: 10 }
    });
  assert.equal(res.status, 200);
  const item = res.body.resources[0];
  const selfInAlts = item.alternatives.some(
    (a) => a.sku.toLowerCase() === sku.toLowerCase()
  );
  assert.equal(selfInAlts, false, 'requested SKU must not appear in alternatives');
});

test('POST /api/capacity/preflight alternatives are sorted by score descending', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({
      resources: [{ sku: 'Standard_D16s_v5', region: 'centralus', count: 1 }],
      options: { topAlternatives: 10 }
    });
  assert.equal(res.status, 200);
  const { alternatives } = res.body.resources[0];
  for (let i = 1; i < alternatives.length; i++) {
    assert.ok(
      alternatives[i - 1].score >= alternatives[i].score,
      'alternatives must be sorted by score descending'
    );
  }
});

// ─── Auth guard ───────────────────────────────────────────────────────────────

test('POST /api/capacity/preflight does not return 401 when AUTH_ENABLED is false', async () => {
  const res = await request(app)
    .post('/api/capacity/preflight')
    .send({ resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }] });
  assert.notEqual(res.status, 401);
});
