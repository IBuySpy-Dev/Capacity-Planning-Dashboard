const test = require('node:test');
const assert = require('node:assert/strict');

// Test sql.js helper functions and early-return paths that don't require a DB.
// All tests run with SQL_SERVER and SQL_DATABASE env vars unset so getSqlPool()
// returns null (no actual DB connection attempted).

const {
  getSqlPool,
  createSqlPoolWithAccessToken,
  insertCapacitySnapshots,
  upsertSubscriptions
} = require('../src/store/sql');

// ─── getSqlPool — returns null when server/database not configured ─────────────

test('getSqlPool returns null when SQL_SERVER is not set', async () => {
  // Env vars are not set in test environment
  const pool = await getSqlPool();
  assert.equal(pool, null);
});

// ─── createSqlPoolWithAccessToken — error paths ───────────────────────────────

test('createSqlPoolWithAccessToken throws when accessToken is empty string', async () => {
  await assert.rejects(
    () => createSqlPoolWithAccessToken(''),
    /SQL access token is required/
  );
});

test('createSqlPoolWithAccessToken throws when accessToken is null', async () => {
  await assert.rejects(
    () => createSqlPoolWithAccessToken(null),
    /SQL access token is required/
  );
});

test('createSqlPoolWithAccessToken throws when SQL_SERVER is not configured', async () => {
  // A non-empty token is provided but SQL_SERVER is not set
  await assert.rejects(
    () => createSqlPoolWithAccessToken('fake-token'),
    /SQL connection is not configured/
  );
});

// ─── insertCapacitySnapshots — early return for empty input ───────────────────

test('insertCapacitySnapshots returns 0 for empty array without touching DB', async () => {
  const count = await insertCapacitySnapshots([]);
  assert.equal(count, 0);
});

test('insertCapacitySnapshots returns 0 for non-array input', async () => {
  const count = await insertCapacitySnapshots(null);
  assert.equal(count, 0);
});

// ─── upsertSubscriptions — early return for empty input ──────────────────────

test('upsertSubscriptions returns 0 for empty array', async () => {
  const count = await upsertSubscriptions([]);
  assert.equal(count, 0);
});

test('upsertSubscriptions returns 0 for rows with only legacy-data subscriptionIds', async () => {
  // Pool is null (no SQL_SERVER), so returns 0 before trying to filter
  const count = await upsertSubscriptions([
    { subscriptionId: 'legacy-data', subscriptionName: 'Legacy data' }
  ]);
  assert.equal(count, 0);
});
