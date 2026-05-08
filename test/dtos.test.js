const test = require('node:test');
const assert = require('node:assert/strict');

const {
  CapacityListDTO,
  CapacityDetailDTO,
  SubscriptionSummaryDTO,
  FamilySummaryDTO,
  TrendDTO,
  PaginationDTO
} = require('../src/models/dtos');

// ─── CapacityListDTO ──────────────────────────────────────────────────────────

test('CapacityListDTO computes quotaAvailable as limit minus current', () => {
  const dto = new CapacityListDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK', quotaLimit: 100, quotaCurrent: 30 });
  assert.equal(dto.quotaAvailable, 70);
  assert.equal(dto.quotaLimit, 100);
});

test('CapacityListDTO defaults missing numeric fields to 0', () => {
  const dto = new CapacityListDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK' });
  assert.equal(dto.quotaAvailable, 0);
  assert.equal(dto.quotaLimit, 0);
});

test('CapacityListDTO defaults subscriptionKey to legacy-data', () => {
  const dto = new CapacityListDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK' });
  assert.equal(dto.subscriptionKey, 'legacy-data');
});

test('CapacityListDTO uses provided subscriptionKey', () => {
  const dto = new CapacityListDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK', subscriptionKey: 'sub-abc' });
  assert.equal(dto.subscriptionKey, 'sub-abc');
});

// ─── CapacityDetailDTO ────────────────────────────────────────────────────────

test('CapacityDetailDTO splits zonesCsv into zones array', () => {
  const dto = new CapacityDetailDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK', zonesCsv: '1,2,3' });
  assert.deepEqual(dto.zones, ['1', '2', '3']);
});

test('CapacityDetailDTO returns empty zones array for blank zonesCsv', () => {
  const dto = new CapacityDetailDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK', zonesCsv: '' });
  assert.deepEqual(dto.zones, []);
});

test('CapacityDetailDTO computes quotaAvailable correctly', () => {
  const dto = new CapacityDetailDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK', quotaLimit: 200, quotaCurrent: 50 });
  assert.equal(dto.quotaAvailable, 150);
});

test('CapacityDetailDTO defaults subscriptionId and subscriptionName for legacy data', () => {
  const dto = new CapacityDetailDTO({ region: 'eastus', sku: 'D2s_v5', family: 'DSv5', availability: 'OK' });
  assert.equal(dto.subscriptionId, 'legacy-data');
  assert.equal(dto.subscriptionName, 'Legacy data');
});

// ─── SubscriptionSummaryDTO ───────────────────────────────────────────────────

test('SubscriptionSummaryDTO maps fields correctly', () => {
  const dto = new SubscriptionSummaryDTO({ subscriptionId: 'sub-1', subscriptionName: 'Prod Sub', rowCount: 42 });
  assert.equal(dto.subscriptionId, 'sub-1');
  assert.equal(dto.subscriptionName, 'Prod Sub');
  assert.equal(dto.rowCount, 42);
});

test('SubscriptionSummaryDTO defaults to legacy-data when fields missing', () => {
  const dto = new SubscriptionSummaryDTO({});
  assert.equal(dto.subscriptionId, 'legacy-data');
  assert.equal(dto.rowCount, 0);
});

// ─── FamilySummaryDTO ─────────────────────────────────────────────────────────

test('FamilySummaryDTO maps numeric fields correctly', () => {
  const dto = new FamilySummaryDTO({ family: 'DSv5', regions: '5', subscriptions: '3', totalQuotaAvailable: '500', averageUtilizationPct: '42.5' });
  assert.equal(dto.regions, 5);
  assert.equal(dto.subscriptions, 3);
  assert.equal(dto.totalQuotaAvailable, 500);
  assert.equal(dto.averageUtilizationPct, 42.5);
});

// ─── TrendDTO ─────────────────────────────────────────────────────────────────

test('TrendDTO maps fields and coerces numerics', () => {
  const dto = new TrendDTO({ capturedAtUtc: '2026-01-01', region: 'westus', family: 'DSv5', quotaAvailable: '100', quotaLimit: '200', subscriptionCount: '2' });
  assert.equal(dto.quotaAvailable, 100);
  assert.equal(dto.quotaLimit, 200);
  assert.equal(dto.subscriptionCount, 2);
});

// ─── PaginationDTO ────────────────────────────────────────────────────────────

test('PaginationDTO calculates pageCount correctly', () => {
  const dto = new PaginationDTO(100, 10, 1);
  assert.equal(dto.pageCount, 10);
  assert.equal(dto.hasNext, true);
  assert.equal(dto.hasPrev, false);
});

test('PaginationDTO hasNext false on last page', () => {
  const dto = new PaginationDTO(100, 10, 10);
  assert.equal(dto.hasNext, false);
  assert.equal(dto.hasPrev, true);
});

test('PaginationDTO handles partial last page', () => {
  const dto = new PaginationDTO(25, 10, 1);
  assert.equal(dto.pageCount, 3);
});

test('PaginationDTO page 1 of 1 has no next or prev', () => {
  const dto = new PaginationDTO(5, 10, 1);
  assert.equal(dto.hasNext, false);
  assert.equal(dto.hasPrev, false);
});
