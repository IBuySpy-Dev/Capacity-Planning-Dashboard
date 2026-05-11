const test = require('node:test');
const assert = require('node:assert/strict');
const request = require('supertest');

function withMockedModule(modulePath, mockExports, loadFn) {
  const resolvedPath = require.resolve(modulePath);
  const original = require.cache[resolvedPath];

  require.cache[resolvedPath] = {
    id: resolvedPath,
    filename: resolvedPath,
    loaded: true,
    exports: mockExports
  };

  try {
    return loadFn();
  } finally {
    delete require.cache[resolvedPath];
    if (original) {
      require.cache[resolvedPath] = original;
    }
  }
}

test('getSubscriptions prefers Subscriptions table path when available', async () => {
  const storeSqlPath = '../src/store/sql';
  const capacityServicePath = '../src/services/capacityService';

  let poolRequestCalls = 0;
  const mockPool = {
    request() {
      poolRequestCalls += 1;
      throw new Error('pool.request should not be called when getSubscriptionsFromTable returns rows');
    }
  };

  await withMockedModule(storeSqlPath, {
    getSqlPool: async () => mockPool,
    getSubscriptionsFromTable: async () => ([
      { subscriptionId: 'sub-1', subscriptionName: 'Subscription One' }
    ]),
    getLatestLivePlacementSnapshots: async () => [],
    ensureVmSkuCatalogSchema: async () => ({ ok: true })
  }, async () => {
    const resolvedCapacityServicePath = require.resolve(capacityServicePath);
    delete require.cache[resolvedCapacityServicePath];
    const { getSubscriptions } = require(capacityServicePath);
    const rows = await getSubscriptions({ limit: 50 });

    assert.deepEqual(rows, [
      { subscriptionId: 'sub-1', subscriptionName: 'Subscription One' }
    ]);
    assert.equal(poolRequestCalls, 0);
  });
});

test('getSubscriptions returns empty list when snapshot schema is missing', async () => {
  const storeSqlPath = '../src/store/sql';
  const capacityServicePath = '../src/services/capacityService';

  const mockPool = {
    request() {
      return {
        input() {
          return this;
        },
        async query(sqlText) {
          if (String(sqlText).includes('FROM sys.columns')) {
            return { recordset: [] };
          }
          return { recordset: [] };
        }
      };
    }
  };

  await withMockedModule(storeSqlPath, {
    getSqlPool: async () => mockPool,
    getSubscriptionsFromTable: async () => null,
    getLatestLivePlacementSnapshots: async () => [],
    ensureVmSkuCatalogSchema: async () => ({ ok: true })
  }, async () => {
    const resolvedCapacityServicePath = require.resolve(capacityServicePath);
    delete require.cache[resolvedCapacityServicePath];
    const { getSubscriptions } = require(capacityServicePath);
    const rows = await getSubscriptions({ limit: 100 });
    assert.deepEqual(rows, []);
  });
});

test('GET /api/subscriptions returns 503 with explicit message when backend is not ready', async () => {
  const capacityServicePath = '../src/services/capacityService';
  const serverPath = '../src/server';

  const backendNotReadyMessage = 'Subscriptions are temporarily unavailable because required SQL schema objects are not ready.';

  const mockCapacityService = {
    getCapacityRows: async () => [],
    getCapacityRowsPaginated: async () => ({ data: [], pagination: { total: 0, page: 1, pageSize: 50 } }),
    getCapacityAnalyticsSummary: async () => ({ totalRows: 0, constrainedRows: 0 }),
    getSubscriptions: async () => {
      const err = new Error(backendNotReadyMessage);
      err.code = 'SUBSCRIPTIONS_BACKEND_NOT_READY';
      throw err;
    },
    SUBSCRIPTIONS_BACKEND_NOT_READY_CODE: 'SUBSCRIPTIONS_BACKEND_NOT_READY',
    getSubscriptionSummary: async () => [],
    getCapacityTrends: async () => [],
    getFamilySummary: async () => [],
    getCapacityScoreSummary: async () => [],
    getCapacityScoreSummaryPaginated: async () => ({ data: [], pagination: { total: 0, page: 1, pageSize: 50 } }),
    getSkuFamilyCatalog: async () => ({ source: 'mock', fetchedAt: new Date().toISOString(), families: {} })
  };

  await withMockedModule(capacityServicePath, mockCapacityService, async () => {
    const resolvedServerPath = require.resolve(serverPath);
    delete require.cache[resolvedServerPath];
    const { app } = require(serverPath);

    const res = await request(app).get('/api/subscriptions');
    assert.equal(res.status, 503);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.error, backendNotReadyMessage);
    assert.equal(typeof res.body.requestId, 'string');
  });
});

test('getSubscriptions retries once after retryable SQL connection failure', async () => {
  const storeSqlPath = '../src/store/sql';
  const capacityServicePath = '../src/services/capacityService';

  let getSqlPoolCallCount = 0;
  let resetSqlPoolCallCount = 0;

  const firstPool = {
    request() {
      return {
        input() {
          return this;
        },
        async query(sqlText) {
          if (String(sqlText).includes('FROM sys.columns')) {
            return {
              recordset: [
                { name: 'subscriptionId' },
                { name: 'subscriptionName' },
                { name: 'capturedAtUtc' }
              ]
            };
          }

          const err = new Error('Connection is closed.');
          err.code = 'ECONNCLOSED';
          throw err;
        }
      };
    }
  };

  const secondPool = {
    request() {
      return {
        input() {
          return this;
        },
        async query(sqlText) {
          if (String(sqlText).includes('FROM sys.columns')) {
            return {
              recordset: [
                { name: 'subscriptionId' },
                { name: 'subscriptionName' },
                { name: 'capturedAtUtc' }
              ]
            };
          }

          return {
            recordset: [
              { subscriptionId: 'sub-1', subscriptionName: 'Subscription One' }
            ]
          };
        }
      };
    }
  };

  await withMockedModule(storeSqlPath, {
    getSqlPool: async () => {
      getSqlPoolCallCount += 1;
      return getSqlPoolCallCount === 1 ? firstPool : secondPool;
    },
    resetSqlPool: async () => {
      resetSqlPoolCallCount += 1;
    },
    getSubscriptionsFromTable: async () => null,
    getLatestLivePlacementSnapshots: async () => [],
    ensureVmSkuCatalogSchema: async () => ({ ok: true })
  }, async () => {
    const resolvedCapacityServicePath = require.resolve(capacityServicePath);
    delete require.cache[resolvedCapacityServicePath];
    const { getSubscriptions } = require(capacityServicePath);

    const rows = await getSubscriptions({ limit: 100 });
    assert.deepEqual(rows, [{ subscriptionId: 'sub-1', subscriptionName: 'Subscription One' }]);
    assert.equal(getSqlPoolCallCount, 2, 'should fetch a new SQL pool after reset');
    assert.equal(resetSqlPoolCallCount, 1, 'should reset stale pool exactly once');
  });
});

test('getSubscriptions returns empty list when CapacitySnapshot table is missing', async () => {
  const storeSqlPath = '../src/store/sql';
  const capacityServicePath = '../src/services/capacityService';

  let resetSqlPoolCallCount = 0;

  const failingPool = {
    request() {
      return {
        input() {
          return this;
        },
        async query() {
          const err = new Error('Invalid object name \'dbo.CapacitySnapshot\'.');
          err.code = 'EREQUEST';
          throw err;
        }
      };
    }
  };

  await withMockedModule(storeSqlPath, {
    getSqlPool: async () => failingPool,
    resetSqlPool: async () => {
      resetSqlPoolCallCount += 1;
    },
    getSubscriptionsFromTable: async () => null,
    getLatestLivePlacementSnapshots: async () => [],
    ensureVmSkuCatalogSchema: async () => ({ ok: true })
  }, async () => {
    const resolvedCapacityServicePath = require.resolve(capacityServicePath);
    delete require.cache[resolvedCapacityServicePath];
    const { getSubscriptions } = require(capacityServicePath);
    const rows = await getSubscriptions({ limit: 100 });
    assert.deepEqual(rows, []);
    assert.equal(resetSqlPoolCallCount, 0, 'non-retryable errors must not reset the SQL pool');
  });
});
