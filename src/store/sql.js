const { randomUUID } = require('crypto');
const sql = require('mssql');
const { normalizeFamilyName } = require('../lib/familyNormalization');

let cachedPool;
const SQL_POOL_RETRY_LIMIT = 1;

function buildSqlConfig({ accessToken } = {}) {
  const server = process.env.SQL_SERVER || process.env.Sql__Server;
  const database = process.env.SQL_DATABASE || process.env.Sql__Database;
  const authMode = (process.env.SQL_AUTH_MODE || process.env.Sql__AuthMode || '').toLowerCase();
  const msiClientId = process.env.SQL_MSI_CLIENT_ID || process.env.Sql__MsiClientId;
  const user = process.env.SQL_USER;
  const password = process.env.SQL_PASSWORD;

  if (!server || !database) {
    return null;
  }

  const useManagedIdentity = authMode === 'managed-identity' || authMode === 'msi';
  if (!accessToken && !useManagedIdentity && (!user || !password)) {
    return null;
  }

  const config = {
    server,
    database,
    requestTimeout: Number(process.env.SQL_REQUEST_TIMEOUT_MS) || 600000,
    connectionTimeout: 30000,
    options: {
      encrypt: true,
      // Allow self-signed certs in CI/dev (e.g. Docker MSSQL) via env var.
      // Never set this in production — always use a CA-signed cert.
      trustServerCertificate: process.env.SQL_TRUST_SERVER_CERTIFICATE === 'true'
    },
    pool: {
      max: 10,
      min: 0,
      idleTimeoutMillis: 30000
    }
  };

  if (accessToken) {
    config.authentication = {
      type: 'azure-active-directory-access-token',
      options: { token: accessToken }
    };
  } else if (useManagedIdentity) {
    config.authentication = {
      type: 'azure-active-directory-msi-app-service',
      options: msiClientId ? { clientId: msiClientId } : {}
    };
  } else {
    config.user = user;
    config.password = password;
  }

  return config;
}

function normalizeSkuName(value) {
  const trimmed = String(value || '').trim();
  if (!trimmed) {
    return '';
  }

  const normalizeSuffix = (suffix) => String(suffix || '')
    .split('_')
    .map((segment) => {
      const normalized = String(segment || '').trim().toLowerCase();
      if (!normalized) {
        return '';
      }
      if (/^v\d+$/.test(normalized)) {
        return normalized;
      }
      return normalized.replace(/^([a-z]+)/, (match) => match.toUpperCase());
    })
    .filter(Boolean)
    .join('_');

  const prefixedSku = trimmed.match(/^(standard|basic|internal)(?:[_\s-]?)(.*)$/i);
  if (prefixedSku) {
    const prefixToken = String(prefixedSku[1] || '').toLowerCase();
    const prefix = prefixToken === 'standard'
      ? 'Standard'
      : (prefixToken === 'basic' ? 'Basic' : 'Internal');
    const rawSuffix = String(prefixedSku[2] || '').replace(/^[_\s-]+/, '');
    const suffix = normalizeSuffix(rawSuffix);
    return suffix ? `${prefix}_${suffix}` : prefix;
  }

  return trimmed;
}

async function getSqlPool(retryCount = 0) {
  const config = buildSqlConfig();
  if (!config) {
    return null;
  }

  if (cachedPool) {
    try {
      await cachedPool.request().query('SELECT 1');
      return cachedPool;
    } catch (err) {
      console.warn(`[sql] Cached SQL pool health check failed; resetting pool (attempt ${retryCount + 1}/${SQL_POOL_RETRY_LIMIT + 1}).`, err?.message || err);
      await resetSqlPool();
    }
  }

  try {
    cachedPool = await sql.connect(config);
    await cachedPool.request().query('SELECT 1');
    return cachedPool;
  } catch (err) {
    cachedPool = undefined;
    if (retryCount < SQL_POOL_RETRY_LIMIT) {
      console.warn(`[sql] Failed to establish SQL pool; retrying connection (attempt ${retryCount + 2}/${SQL_POOL_RETRY_LIMIT + 1}).`, err?.message || err);
      return getSqlPool(retryCount + 1);
    }
    throw new Error(`Failed to establish SQL connection pool after ${SQL_POOL_RETRY_LIMIT + 1} attempts: ${err?.message || err}`);
  }
}

async function resetSqlPool() {
  if (!cachedPool) {
    return;
  }

  const poolToClose = cachedPool;
  cachedPool = undefined;
  try {
    await poolToClose.close();
  } catch (err) {
    console.warn('[sql] Failed to close cached pool during reset:', err?.message || err);
  }
}

async function createSqlPoolWithAccessToken(accessToken) {
  const normalizedToken = String(accessToken || '').trim();
  if (!normalizedToken) {
    throw new Error('SQL access token is required.');
  }

  const config = buildSqlConfig({ accessToken: normalizedToken });
  if (!config) {
    throw new Error('SQL connection is not configured.');
  }

  const pool = new sql.ConnectionPool(config);
  await pool.connect();
  return pool;
}

async function tableExists(pool, tableName) {
  if (!pool || !tableName) {
    return false;
  }

  const request = pool.request();
  request.input('tableName', sql.NVarChar(256), String(tableName));
  const result = await request.query(`
    SELECT 1 AS hasTable
    WHERE OBJECT_ID(@tableName, 'U') IS NOT NULL
  `);

  return Boolean(result.recordset && result.recordset.length > 0);
}

async function insertCapacitySnapshots(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured for ingestion.');
  }

  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    for (const row of rows) {
      const request = new sql.Request(transaction);
      const normalizedSkuName = normalizeSkuName(row.skuName);
      const normalizedFamilyName = normalizeFamilyName(row.skuFamily);
      request.input('capturedAtUtc', sql.DateTime2, row.capturedAtUtc || new Date());
      request.input('sourceType', sql.NVarChar(50), row.sourceType || 'live-azure-ingest');
      request.input('subscriptionKey', sql.NVarChar(64), row.subscriptionKey || 'legacy-data');
      request.input('subscriptionId', sql.NVarChar(64), row.subscriptionId || 'legacy-data');
      request.input('subscriptionName', sql.NVarChar(256), row.subscriptionName || 'Legacy data');
      request.input('region', sql.NVarChar(64), row.region);
      request.input('skuName', sql.NVarChar(128), normalizedSkuName);
      request.input('skuFamily', sql.NVarChar(128), normalizedFamilyName);
      request.input('vCpu', sql.Int, row.vCpu ?? null);
      request.input('memoryGB', sql.Decimal(10, 2), row.memoryGB ?? null);
      request.input('zonesCsv', sql.NVarChar(256), row.zonesCsv ?? null);
      request.input('availabilityState', sql.NVarChar(32), row.availabilityState);
      request.input('quotaCurrent', sql.Int, row.quotaCurrent);
      request.input('quotaLimit', sql.Int, row.quotaLimit);
      request.input('monthlyCostEstimate', sql.Decimal(18, 2), row.monthlyCostEstimate ?? null);

      await request.query(`
        INSERT INTO dbo.CapacitySnapshot
        (capturedAtUtc, sourceType, subscriptionKey, subscriptionId, subscriptionName, region, skuName, skuFamily, vCpu, memoryGB, zonesCsv, availabilityState, quotaCurrent, quotaLimit, monthlyCostEstimate)
        VALUES
        (@capturedAtUtc, @sourceType, @subscriptionKey, @subscriptionId, @subscriptionName, @region, @skuName, @skuFamily, @vCpu, @memoryGB, @zonesCsv, @availabilityState, @quotaCurrent, @quotaLimit, @monthlyCostEstimate)
      `);
    }

    await transaction.commit();

    // Upsert distinct subscriptions from this batch (best-effort; non-transactional)
    await upsertSubscriptions(rows).catch(() => {/* silently skip if table doesn't exist yet */});

    return rows.length;
  } catch (err) {
    await transaction.rollback();
    throw err;
  }
}

async function upsertSubscriptions(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    return 0;
  }

  // Collect distinct (subscriptionId, subscriptionName) pairs from the batch
  const seen = new Map();
  for (const row of rows) {
    const id = row.subscriptionId;
    const name = row.subscriptionName;
    if (id && id !== 'legacy-data' && !seen.has(id)) {
      seen.set(id, name || id);
    }
  }
  if (seen.size === 0) {
    return 0;
  }

  const now = new Date();
  let upserted = 0;

  for (const [subscriptionId, subscriptionName] of seen) {
    const request = pool.request();
    request.input('subscriptionId', sql.NVarChar(64), subscriptionId);
    request.input('subscriptionName', sql.NVarChar(256), subscriptionName);
    request.input('updatedAtUtc', sql.DateTime2, now);

    await request.query(`
      IF OBJECT_ID('dbo.Subscriptions', 'U') IS NOT NULL
      BEGIN
        MERGE dbo.Subscriptions AS tgt
        USING (SELECT @subscriptionId AS subscriptionId, @subscriptionName AS subscriptionName, @updatedAtUtc AS updatedAtUtc) AS src
        ON tgt.subscriptionId = src.subscriptionId
        WHEN MATCHED THEN
          UPDATE SET subscriptionName = src.subscriptionName, updatedAtUtc = src.updatedAtUtc
        WHEN NOT MATCHED THEN
          INSERT (subscriptionId, subscriptionName, updatedAtUtc) VALUES (src.subscriptionId, src.subscriptionName, src.updatedAtUtc);
      END
    `);

    upserted++;
  }

  return upserted;
}

async function getSubscriptionsFromTable({ search, limit } = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return [{ subscriptionId: 'legacy-data', subscriptionName: 'Legacy data' }];
  }

  // If the Subscriptions table doesn't exist yet (pre-migration), fall back to
  // deriving the list from CapacityLatest (the old behaviour).
  if (!(await tableExists(pool, 'dbo.Subscriptions'))) {
    return null; // caller falls back to CapacityLatest GROUP BY
  }

  const maxLimit = Math.max(10, Math.min(Number(limit || 500), 1000));
  const request = pool.request();
  request.input('limitRows', sql.Int, maxLimit);

  let query = `
    SELECT TOP (@limitRows)
      subscriptionId,
      subscriptionName
    FROM dbo.Subscriptions
    WHERE 1 = 1
  `;

  if (search && search.trim()) {
    request.input('search', sql.NVarChar(256), `%${search.trim()}%`);
    query += ` AND (subscriptionId LIKE @search OR subscriptionName LIKE @search)`;
  }

  query += ` ORDER BY subscriptionName ASC`;

  const result = await request.query(query);
  return (result.recordset || []).map((r) => ({
    subscriptionId: r.subscriptionId,
    subscriptionName: r.subscriptionName
  }));
}

async function ensureSubscriptionsTableSchema(pool) {
  return tableExists(pool, 'dbo.Subscriptions');
}

async function ensureCapacityScoreSnapshotSchema(pool) {
  return tableExists(pool, 'dbo.CapacityScoreSnapshot');
}

async function insertCapacityScoreSnapshots(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured for capacity score history.');
  }

  if (!(await ensureCapacityScoreSnapshotSchema(pool))) {
    return 0;
  }

  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    for (const row of rows) {
      const request = new sql.Request(transaction);
      const normalizedSkuName = normalizeSkuName(row.sku);
      const normalizedFamilyName = normalizeFamilyName(row.family);
      request.input('capturedAtUtc', sql.DateTime2, row.capturedAtUtc || new Date());
      request.input('region', sql.NVarChar(64), row.region);
      request.input('skuName', sql.NVarChar(128), normalizedSkuName);
      request.input('skuFamily', sql.NVarChar(128), normalizedFamilyName);
      request.input('subscriptionCount', sql.Int, row.subscriptionCount ?? 0);
      request.input('okRows', sql.Int, row.okRows ?? 0);
      request.input('limitedRows', sql.Int, row.limitedRows ?? 0);
      request.input('constrainedRows', sql.Int, row.constrainedRows ?? 0);
      request.input('totalQuotaAvailable', sql.Int, row.totalQuotaAvailable ?? 0);
      request.input('utilizationPct', sql.Int, row.utilizationPct ?? 0);
      request.input('score', sql.NVarChar(16), row.score || 'Unknown');
      request.input('reason', sql.NVarChar(512), row.reason || 'No reason recorded.');
      request.input('latestSourceCapturedAtUtc', sql.DateTime2, row.latestCapturedAtUtc ?? null);

      await request.query(`
        INSERT INTO dbo.CapacityScoreSnapshot
        (capturedAtUtc, region, skuName, skuFamily, subscriptionCount, okRows, limitedRows, constrainedRows, totalQuotaAvailable, utilizationPct, score, reason, latestSourceCapturedAtUtc)
        VALUES
        (@capturedAtUtc, @region, @skuName, @skuFamily, @subscriptionCount, @okRows, @limitedRows, @constrainedRows, @totalQuotaAvailable, @utilizationPct, @score, @reason, @latestSourceCapturedAtUtc)
      `);
    }

    await transaction.commit();
    return rows.length;
  } catch (err) {
    await transaction.rollback();
    throw err;
  }
}

async function getCapacityScoreSnapshotHistory(filters = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return [];
  }

  if (!(await ensureCapacityScoreSnapshotSchema(pool))) {
    return [];
  }

  const days = Math.max(1, Math.min(Number(filters.days || 30), 365));
  const request = pool.request();
  request.input('daysBack', sql.Int, days);

  let where = `
    WHERE capturedAtUtc >= DATEADD(day, -@daysBack, SYSUTCDATETIME())
  `;

  if (filters.region && filters.region !== 'all') {
    where += ' AND region = @region';
    request.input('region', sql.NVarChar(64), filters.region);
  }

  if (filters.family && filters.family !== 'all') {
    where += ' AND skuFamily = @family';
    request.input('family', sql.NVarChar(128), filters.family);
  }

  if (filters.score && filters.score !== 'all') {
    where += ' AND score = @score';
    request.input('score', sql.NVarChar(16), filters.score);
  }

  if (filters.sku && filters.sku !== 'all') {
    where += ' AND skuName = @sku';
    request.input('sku', sql.NVarChar(128), filters.sku);
  }

  const result = await request.query(`
    SELECT
      capturedAtUtc,
      region,
      skuName,
      skuFamily,
      subscriptionCount,
      okRows,
      limitedRows,
      constrainedRows,
      totalQuotaAvailable,
      utilizationPct,
      score,
      reason,
      latestSourceCapturedAtUtc
    FROM dbo.CapacityScoreSnapshot
    ${where}
    ORDER BY capturedAtUtc DESC, region ASC, skuName ASC
  `);

  return (result.recordset || []).map((row) => ({
    capturedAtUtc: row.capturedAtUtc,
    region: row.region,
    sku: row.skuName,
    family: row.skuFamily,
    subscriptionCount: Number(row.subscriptionCount || 0),
    okRows: Number(row.okRows || 0),
    limitedRows: Number(row.limitedRows || 0),
    constrainedRows: Number(row.constrainedRows || 0),
    totalQuotaAvailable: Number(row.totalQuotaAvailable || 0),
    utilizationPct: Number(row.utilizationPct || 0),
    score: row.score,
    reason: row.reason,
    latestCapturedAtUtc: row.latestSourceCapturedAtUtc
  }));
}

async function ensureQuotaCandidateSnapshotTable(pool) {
  const hasTable = await tableExists(pool, 'dbo.QuotaCandidateSnapshot');
  if (!hasTable) {
    throw new Error('Quota candidate history is unavailable because the QuotaCandidateSnapshot table is not provisioned. Run the SQL schema/bootstrap migration for this environment.');
  }
}

async function insertQuotaCandidateSnapshots(rows) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured for quota candidate capture.');
  }

  await ensureQuotaCandidateSnapshotTable(pool);

  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    for (const row of rows) {
      const request = new sql.Request(transaction);
      request.input('analysisRunId', sql.UniqueIdentifier, row.analysisRunId);
      request.input('capturedAtUtc', sql.DateTime2, row.capturedAtUtc || new Date());
      request.input('sourceCapturedAtUtc', sql.DateTime2, row.sourceCapturedAtUtc ?? null);
      request.input('managementGroupId', sql.NVarChar(128), row.managementGroupId);
      request.input('groupQuotaName', sql.NVarChar(128), row.groupQuotaName);
      request.input('subscriptionId', sql.NVarChar(64), row.subscriptionId);
      request.input('subscriptionName', sql.NVarChar(256), row.subscriptionName || 'Subscription');
      request.input('region', sql.NVarChar(64), row.region);
      request.input('quotaName', sql.NVarChar(128), row.quotaName);
      request.input('skuList', sql.NVarChar(sql.MAX), row.skuList || null);
      request.input('skuCount', sql.Int, row.skuCount ?? 0);
      request.input('availabilityState', sql.NVarChar(32), row.availabilityState || 'Unknown');
      request.input('quotaCurrent', sql.Int, row.quotaCurrent ?? 0);
      request.input('quotaLimit', sql.Int, row.quotaLimit ?? 0);
      request.input('quotaAvailable', sql.Int, row.quotaAvailable ?? 0);
      request.input('suggestedMovable', sql.Int, row.suggestedMovable ?? 0);
      request.input('safetyBuffer', sql.Int, row.safetyBuffer ?? 0);
      request.input('subscriptionHash', sql.NVarChar(128), row.subscriptionHash);
      request.input('candidateStatus', sql.NVarChar(32), row.candidateStatus || 'Unknown');

      await request.query(`
        INSERT INTO dbo.QuotaCandidateSnapshot
        (analysisRunId, capturedAtUtc, sourceCapturedAtUtc, managementGroupId, groupQuotaName, subscriptionId, subscriptionName, region, quotaName, skuList, skuCount, availabilityState, quotaCurrent, quotaLimit, quotaAvailable, suggestedMovable, safetyBuffer, subscriptionHash, candidateStatus)
        VALUES
        (@analysisRunId, @capturedAtUtc, @sourceCapturedAtUtc, @managementGroupId, @groupQuotaName, @subscriptionId, @subscriptionName, @region, @quotaName, @skuList, @skuCount, @availabilityState, @quotaCurrent, @quotaLimit, @quotaAvailable, @suggestedMovable, @safetyBuffer, @subscriptionHash, @candidateStatus)
      `);
    }

    await transaction.commit();
    return rows.length;
  } catch (err) {
    await transaction.rollback();
    throw err;
  }
}

async function getQuotaCandidateSnapshots(filters = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured for quota planning.');
  }

  const managementGroupId = filters.managementGroupId;
  const groupQuotaName = filters.groupQuotaName;
  const region = filters.region || 'all';
  const quotaName = filters.quotaName || filters.family || 'all';
  const analysisRunId = filters.analysisRunId || null;

  if (!managementGroupId) {
    throw new Error('managementGroupId is required.');
  }

  if (!groupQuotaName || groupQuotaName === 'all') {
    throw new Error('groupQuotaName is required.');
  }

  await ensureQuotaCandidateSnapshotTable(pool);

  const request = pool.request();
  request.input('managementGroupId', sql.NVarChar(128), managementGroupId);
  request.input('groupQuotaName', sql.NVarChar(128), groupQuotaName);
  request.input('region', sql.NVarChar(64), region);
  request.input('quotaName', sql.NVarChar(128), quotaName);
  request.input('analysisRunId', sql.UniqueIdentifier, analysisRunId);

  const result = await request.query(`
    WITH SelectedRun AS (
      SELECT TOP (1)
        analysisRunId,
        capturedAtUtc
      FROM dbo.QuotaCandidateSnapshot
      WHERE managementGroupId = @managementGroupId
        AND groupQuotaName = @groupQuotaName
        AND (@analysisRunId IS NULL OR analysisRunId = @analysisRunId)
        AND (@region = 'all' OR region = @region)
        AND (@quotaName = 'all' OR quotaName = @quotaName)
      GROUP BY analysisRunId, capturedAtUtc
      ORDER BY capturedAtUtc DESC, analysisRunId DESC
    )
    SELECT
      qcs.analysisRunId,
      qcs.capturedAtUtc,
      qcs.sourceCapturedAtUtc,
      qcs.managementGroupId,
      qcs.groupQuotaName,
      qcs.subscriptionId,
      qcs.subscriptionName,
      qcs.region,
      qcs.quotaName,
      qcs.skuList,
      qcs.skuCount,
      qcs.availabilityState,
      qcs.quotaCurrent,
      qcs.quotaLimit,
      qcs.quotaAvailable,
      qcs.suggestedMovable,
      qcs.safetyBuffer,
      qcs.subscriptionHash,
      qcs.candidateStatus
    FROM dbo.QuotaCandidateSnapshot qcs
    INNER JOIN SelectedRun selectedRun
      ON selectedRun.analysisRunId = qcs.analysisRunId
    WHERE (@region = 'all' OR qcs.region = @region)
      AND (@quotaName = 'all' OR qcs.quotaName = @quotaName)
    ORDER BY qcs.region, qcs.quotaName, qcs.suggestedMovable DESC, qcs.subscriptionName
  `);

  return result.recordset || [];
}

async function listQuotaCandidateRuns(filters = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured for quota planning.');
  }

  const managementGroupId = filters.managementGroupId;
  const groupQuotaName = filters.groupQuotaName;
  const region = filters.region || 'all';
  const quotaName = filters.quotaName || filters.family || 'all';

  if (!managementGroupId) {
    throw new Error('managementGroupId is required.');
  }

  if (!groupQuotaName || groupQuotaName === 'all') {
    throw new Error('groupQuotaName is required.');
  }

  await ensureQuotaCandidateSnapshotTable(pool);

  const request = pool.request();
  request.input('managementGroupId', sql.NVarChar(128), managementGroupId);
  request.input('groupQuotaName', sql.NVarChar(128), groupQuotaName);
  request.input('region', sql.NVarChar(64), region);
  request.input('quotaName', sql.NVarChar(128), quotaName);

  const result = await request.query(`
    SELECT
      analysisRunId,
      capturedAtUtc,
      MAX(sourceCapturedAtUtc) AS latestSourceCapturedAtUtc,
        COUNT(*) AS [rowCount],
        COUNT(DISTINCT subscriptionId) AS [subscriptionCount],
        SUM(CASE WHEN suggestedMovable > 0 THEN 1 ELSE 0 END) AS [movableCandidateCount]
    FROM dbo.QuotaCandidateSnapshot
    WHERE managementGroupId = @managementGroupId
      AND groupQuotaName = @groupQuotaName
      AND (@region = 'all' OR region = @region)
      AND (@quotaName = 'all' OR quotaName = @quotaName)
    GROUP BY analysisRunId, capturedAtUtc
    ORDER BY capturedAtUtc DESC, analysisRunId DESC
  `);

  return result.recordset || [];
}

async function ensureDashboardErrorLogSchema(pool) {
  return tableExists(pool, 'dbo.DashboardErrorLog');
}

async function insertDashboardErrorLog(entry = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return 0;
  }

  if (!(await ensureDashboardErrorLogSchema(pool))) {
    return 0;
  }

  const request = pool.request();
  request.input('errorSource', sql.NVarChar(64), entry.source || 'unknown');
  request.input('errorType', sql.NVarChar(128), entry.type || 'UnkownError');
  request.input('errorMessage', sql.NVarChar(2048), (entry.message || 'No error message').substring(0, 2048));
  request.input('stackTrace', sql.NVarChar(sql.MAX), entry.stack || null);
  request.input('occurredAtUtc', sql.DateTime2, entry.occurredAtUtc || new Date());
  request.input('severity', sql.NVarChar(16), entry.severity || 'error');
  request.input('context', sql.NVarChar(sql.MAX), entry.context ? JSON.stringify(entry.context) : null);
  request.input('affectedRegion', sql.NVarChar(64), entry.region || null);
  request.input('affectedSku', sql.NVarChar(128), entry.sku || null);
  request.input('affectedDesiredCount', sql.Int, Number.isFinite(entry.desiredCount) ? entry.desiredCount : null);
  request.input('requestId', sql.NVarChar(36), entry.requestId || null);

  try {
    await request.query(`
      INSERT INTO dbo.DashboardErrorLog
      (errorSource, errorType, errorMessage, stackTrace, occurredAtUtc, severity, context, affectedRegion, affectedSku, affectedDesiredCount, isResolved, requestId)
      VALUES
      (@errorSource, @errorType, @errorMessage, @stackTrace, @occurredAtUtc, @severity, @context, @affectedRegion, @affectedSku, @affectedDesiredCount, 0, @requestId)
    `);
    return 1;
  } catch (err) {
    console.error('Failed to log error to database:', err.message);
    return 0;
  }
}

async function listDashboardErrorLogs(options = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return [];
  }

  if (!(await ensureDashboardErrorLogSchema(pool))) {
    return [];
  }

  const limit = Math.max(5, Math.min(Number(options.limit || 50), 200));
  const onlyUnresolved = Boolean(options.onlyUnresolved);
  const source = options.source || null;
  const severity = options.severity || null;
  const hoursBack = Math.max(1, Math.min(Number(options.hoursBack || 168), 24 * 365));

  const request = pool.request();
  request.input('limitRows', sql.Int, limit);
  request.input('hoursBack', sql.Int, hoursBack);

  let where = 'WHERE occurredAtUtc >= DATEADD(hour, -@hoursBack, SYSUTCDATETIME())';
  if (onlyUnresolved) {
    where += ' AND isResolved = 0';
  }
  if (source) {
    where += ' AND errorSource = @source';
    request.input('source', sql.NVarChar(64), source);
  }
  if (severity) {
    where += ' AND severity = @severity';
    request.input('severity', sql.NVarChar(16), severity);
  }

  const result = await request.query(`
    SELECT TOP (@limitRows)
      errorLogId,
      errorSource,
      errorType,
      errorMessage,
      stackTrace,
      occurredAtUtc,
      severity,
      context,
      affectedRegion,
      affectedSku,
      affectedDesiredCount,
      isResolved,
      resolvedAtUtc,
      resolutionNotes,
      requestId
    FROM dbo.DashboardErrorLog
    ${where}
    ORDER BY occurredAtUtc DESC, errorLogId DESC
  `);

  return (result.recordset || []).map((row) => {
    let contextObj = null;
    if (row.context) {
      try {
        contextObj = JSON.parse(row.context);
      } catch {
        contextObj = null;
      }
    }

    return {
      id: Number(row.errorLogId),
      source: row.errorSource,
      type: row.errorType,
      message: row.errorMessage,
      stack: row.stackTrace,
      occurredAtUtc: row.occurredAtUtc,
      severity: row.severity,
      context: contextObj,
      region: row.affectedRegion,
      sku: row.affectedSku,
      desiredCount: row.affectedDesiredCount == null ? null : Number(row.affectedDesiredCount),
      isResolved: Boolean(row.isResolved),
      resolvedAtUtc: row.resolvedAtUtc,
      resolutionNotes: row.resolutionNotes,
      requestId: row.requestId || null
    };
  });
}

async function ensureDashboardOperationLogSchema(pool) {
  return tableExists(pool, 'dbo.DashboardOperationLog');
}

async function logDashboardOperation(entry = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return 0;
  }

  if (!(await ensureDashboardOperationLogSchema(pool))) {
    return 0;
  }

  const request = pool.request();
  request.input('operationType', sql.NVarChar(64), entry.type || 'unknown');
  request.input('operationName', sql.NVarChar(128), entry.name || entry.type || 'Unknown Operation');
  request.input('status', sql.NVarChar(16), entry.status || 'success');
  request.input('triggerSource', sql.NVarChar(32), entry.triggerSource || 'manual');
  request.input('startedAtUtc', sql.DateTime2, entry.startedAtUtc || new Date());
  request.input('completedAtUtc', sql.DateTime2, entry.completedAtUtc || new Date());
  request.input('durationMs', sql.Int, Number.isFinite(entry.durationMs) ? entry.durationMs : null);
  request.input('rowsAffected', sql.Int, Number.isFinite(entry.rowsAffected) ? entry.rowsAffected : null);
  request.input('subscriptionCount', sql.Int, Number.isFinite(entry.subscriptionCount) ? entry.subscriptionCount : null);
  request.input('requestedDesiredCount', sql.Int, Number.isFinite(entry.requestedDesiredCount) ? entry.requestedDesiredCount : null);
  request.input('effectiveDesiredCount', sql.Int, Number.isFinite(entry.effectiveDesiredCount) ? entry.effectiveDesiredCount : null);
  request.input('regionPreset', sql.NVarChar(64), entry.regionPreset || null);
  request.input('note', sql.NVarChar(512), entry.note || null);
  request.input('errorMessage', sql.NVarChar(2048), entry.errorMessage || null);

  try {
    await request.query(`
      INSERT INTO dbo.DashboardOperationLog
      (operationType, operationName, status, triggerSource, startedAtUtc, completedAtUtc, durationMs, rowsAffected, subscriptionCount, requestedDesiredCount, effectiveDesiredCount, regionPreset, note, errorMessage)
      VALUES
      (@operationType, @operationName, @status, @triggerSource, @startedAtUtc, @completedAtUtc, @durationMs, @rowsAffected, @subscriptionCount, @requestedDesiredCount, @effectiveDesiredCount, @regionPreset, @note, @errorMessage)
    `);
    return 1;
  } catch (err) {
    console.error('Failed to log operation:', err.message);
    return 0;
  }
}

async function listDashboardOperations(options = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return [];
  }

  if (!(await ensureDashboardOperationLogSchema(pool))) {
    return [];
  }

  const limit = Math.max(5, Math.min(Number(options.limit || 25), 100));
  const request = pool.request();
  request.input('limitRows', sql.Int, limit);

  let where = '';
  if (options.operationType) {
    where += ' WHERE operationType = @operationType';
    request.input('operationType', sql.NVarChar(64), options.operationType);
  }

  if (options.onlyFailed) {
    where = where ? where + ' AND status = \'failed\'' : ' WHERE status = \'failed\'';
  }

  const result = await request.query(`
    SELECT TOP (@limitRows)
      operationLogId,
      operationType,
      operationName,
      status,
      triggerSource,
      startedAtUtc,
      completedAtUtc,
      durationMs,
      rowsAffected,
      subscriptionCount,
      requestedDesiredCount,
      effectiveDesiredCount,
      regionPreset,
      note,
      errorMessage
    FROM dbo.DashboardOperationLog
    ${where}
    ORDER BY startedAtUtc DESC, operationLogId DESC
  `);

  return (result.recordset || []).map((row) => ({
    id: Number(row.operationLogId),
    type: row.operationType,
    name: row.operationName,
    status: row.status,
    triggerSource: row.triggerSource,
    startedAtUtc: row.startedAtUtc,
    completedAtUtc: row.completedAtUtc,
    durationMs: Number(row.durationMs || 0),
    rowsAffected: row.rowsAffected == null ? null : Number(row.rowsAffected),
    subscriptionCount: row.subscriptionCount == null ? null : Number(row.subscriptionCount),
    requestedDesiredCount: row.requestedDesiredCount == null ? null : Number(row.requestedDesiredCount),
    effectiveDesiredCount: row.effectiveDesiredCount == null ? null : Number(row.effectiveDesiredCount),
    regionPreset: row.regionPreset,
    note: row.note,
    errorMessage: row.errorMessage
  }));
}

async function ensureDashboardSettingSchema(pool) {
  return tableExists(pool, 'dbo.DashboardSetting');
}

async function getDashboardSettings(prefix = null) {
  const pool = await getSqlPool();
  if (!pool) {
    return {};
  }

  if (!(await tableExists(pool, 'dbo.DashboardSetting'))) {
    return {};
  }

  const request = pool.request();
  let where = '';

  if (prefix && String(prefix).trim()) {
    request.input('prefix', sql.NVarChar(128), `${String(prefix).trim()}%`);
    where = 'WHERE settingKey LIKE @prefix';
  }

  const result = await request.query(`
    SELECT settingKey, settingValue, updatedAtUtc
    FROM dbo.DashboardSetting
    ${where}
    ORDER BY settingKey ASC
  `);

  const map = {};
  for (const row of result.recordset || []) {
    map[row.settingKey] = {
      value: row.settingValue,
      updatedAtUtc: row.updatedAtUtc
    };
  }

  return map;
}

async function getDashboardSettingsPersistence() {
  const pool = await getSqlPool();
  if (!pool) {
    return {
      available: false,
      source: 'runtime-defaults',
      message: 'SQL scheduler settings are unavailable because SQL connectivity is not configured.'
    };
  }

  if (!(await tableExists(pool, 'dbo.DashboardSetting'))) {
    return {
      available: false,
      source: 'runtime-defaults',
      message: 'SQL scheduler settings are unavailable because the DashboardSetting table is not provisioned.'
    };
  }

  return {
    available: true,
    source: 'sql',
    message: 'SQL scheduler settings are available.'
  };
}

async function upsertDashboardSettings(entries = {}) {
  const keys = Object.keys(entries || {});
  if (keys.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    return 0;
  }

  if (!(await tableExists(pool, 'dbo.DashboardSetting'))) {
    throw new Error('Scheduler settings are unavailable until the DashboardSetting table is provisioned in SQL.');
  }

  let updatedCount = 0;
  for (const key of keys) {
    const normalizedKey = String(key || '').trim();
    if (!normalizedKey) {
      continue;
    }

    const rawValue = entries[key];
    const normalizedValue = rawValue == null ? '' : String(rawValue);

    const request = pool.request();
    request.input('settingKey', sql.NVarChar(128), normalizedKey);
    request.input('settingValue', sql.NVarChar(sql.MAX), normalizedValue);

    await request.query(`
      MERGE dbo.DashboardSetting AS target
      USING (
        SELECT
          @settingKey AS settingKey,
          @settingValue AS settingValue,
          SYSUTCDATETIME() AS updatedAtUtc
      ) AS source
      ON target.settingKey = source.settingKey
      WHEN MATCHED THEN
        UPDATE SET
          settingValue = source.settingValue,
          updatedAtUtc = source.updatedAtUtc
      WHEN NOT MATCHED THEN
        INSERT (settingKey, settingValue, updatedAtUtc)
        VALUES (source.settingKey, source.settingValue, source.updatedAtUtc);
    `);

    updatedCount += 1;
  }

  return updatedCount;
}

async function ensureLivePlacementSnapshotSchema(pool) {
  return tableExists(pool, 'dbo.LivePlacementSnapshot');
}

async function ensurePaaSAvailabilitySnapshotSchema(pool) {
  return tableExists(pool, 'dbo.PaaSAvailabilitySnapshot');
}

async function saveLivePlacementSnapshots(rows = []) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return 0;
  }

  const pool = await getSqlPool();
  if (!pool) {
    return 0;
  }

  if (!(await ensureLivePlacementSnapshotSchema(pool))) {
    return 0;
  }

  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    for (const row of rows) {
      const request = new sql.Request(transaction);
      const normalizedSkuName = normalizeSkuName(row.sku);
      request.input('capturedAtUtc', sql.DateTime2, row.capturedAtUtc || new Date());
      request.input('desiredCount', sql.Int, Math.max(Number(row.desiredCount || 1), 1));
      request.input('region', sql.NVarChar(64), row.region);
      request.input('skuName', sql.NVarChar(128), normalizedSkuName);
      request.input('livePlacementScore', sql.NVarChar(64), row.livePlacementScore || 'N/A');
      request.input('livePlacementAvailable', sql.Bit, typeof row.livePlacementAvailable === 'boolean' ? row.livePlacementAvailable : null);
      request.input('livePlacementRestricted', sql.Bit, typeof row.livePlacementRestricted === 'boolean' ? row.livePlacementRestricted : null);
      request.input('warningMessage', sql.NVarChar(512), row.warning || null);

      await request.query(`
        INSERT INTO dbo.LivePlacementSnapshot
        (capturedAtUtc, desiredCount, region, skuName, livePlacementScore, livePlacementAvailable, livePlacementRestricted, warningMessage)
        VALUES
        (@capturedAtUtc, @desiredCount, @region, @skuName, @livePlacementScore, @livePlacementAvailable, @livePlacementRestricted, @warningMessage)
      `);
    }

    await transaction.commit();
    return rows.length;
  } catch (err) {
    await transaction.rollback();
    console.error('Failed to save live placement snapshots:', err.message);
    return 0;
  }
}

async function savePaaSAvailabilitySnapshots(rows = [], options = {}) {
  if (!Array.isArray(rows) || rows.length === 0) {
    return { runId: null, rowCount: 0 };
  }

  const pool = await getSqlPool();
  if (!pool) {
    return { runId: null, rowCount: 0 };
  }

  if (!(await ensurePaaSAvailabilitySnapshotSchema(pool))) {
    return { runId: null, rowCount: 0 };
  }

  const effectiveRunId = options.runId || randomUUID();
  const requestedService = String(options.requestedService || 'All').trim() || 'All';
  const requestedRegionPreset = options.requestedRegionPreset ? String(options.requestedRegionPreset).trim() : null;
  const requestedRegionsJson = Array.isArray(options.requestedRegions) ? JSON.stringify(options.requestedRegions) : (options.requestedRegions ? JSON.stringify(options.requestedRegions) : null);
  const metadataJson = options.metadata ? JSON.stringify(options.metadata) : null;

  const transaction = new sql.Transaction(pool);
  await transaction.begin();

  try {
    for (const row of rows) {
      const request = new sql.Request(transaction);
      request.input('runId', sql.UniqueIdentifier, effectiveRunId);
      request.input('capturedAtUtc', sql.DateTime2, row.capturedAtUtc || new Date());
      request.input('requestedService', sql.NVarChar(64), requestedService);
      request.input('requestedRegionPreset', sql.NVarChar(64), requestedRegionPreset);
      request.input('requestedRegionsJson', sql.NVarChar(sql.MAX), requestedRegionsJson);
      request.input('metadataJson', sql.NVarChar(sql.MAX), metadataJson);
      request.input('category', sql.NVarChar(64), String(row.category || 'unknown'));
      request.input('service', sql.NVarChar(64), String(row.service || requestedService));
      request.input('region', sql.NVarChar(64), String(row.region || 'global').toLowerCase());
      request.input('resourceType', sql.NVarChar(64), row.resourceType || null);
      request.input('name', sql.NVarChar(256), String(row.name || row.displayName || 'unknown'));
      request.input('displayName', sql.NVarChar(256), row.displayName || null);
      request.input('edition', sql.NVarChar(128), row.edition || null);
      request.input('tier', sql.NVarChar(256), row.tier || null);
      request.input('family', sql.NVarChar(128), row.family || null);
      request.input('status', sql.NVarChar(64), row.status || null);
      request.input('available', sql.Bit, typeof row.available === 'boolean' ? row.available : null);
      request.input('zoneRedundant', sql.Bit, typeof row.zoneRedundant === 'boolean' ? row.zoneRedundant : null);
      request.input('quotaCurrent', sql.Int, Number.isFinite(Number(row.quotaCurrent)) ? Number(row.quotaCurrent) : null);
      request.input('quotaLimit', sql.Int, Number.isFinite(Number(row.quotaLimit)) ? Number(row.quotaLimit) : null);
      request.input('metricPrimary', sql.NVarChar(256), row.metricPrimary == null ? null : String(row.metricPrimary));
      request.input('metricSecondary', sql.NVarChar(256), row.metricSecondary == null ? null : String(row.metricSecondary));
      request.input('detailsJson', sql.NVarChar(sql.MAX), row.details ? JSON.stringify(row.details) : null);

      await request.query(`
        INSERT INTO dbo.PaaSAvailabilitySnapshot
        (runId, capturedAtUtc, requestedService, requestedRegionPreset, requestedRegionsJson, metadataJson, category, service, region, resourceType, name, displayName, edition, tier, family, status, available, zoneRedundant, quotaCurrent, quotaLimit, metricPrimary, metricSecondary, detailsJson)
        VALUES
        (@runId, @capturedAtUtc, @requestedService, @requestedRegionPreset, @requestedRegionsJson, @metadataJson, @category, @service, @region, @resourceType, @name, @displayName, @edition, @tier, @family, @status, @available, @zoneRedundant, @quotaCurrent, @quotaLimit, @metricPrimary, @metricSecondary, @detailsJson)
      `);
    }

    await transaction.commit();
    return { runId: effectiveRunId, rowCount: rows.length };
  } catch (err) {
    await transaction.rollback();
    console.error('Failed to save PaaS availability snapshots:', err.message);
    return { runId: null, rowCount: 0 };
  }
}

async function getLatestPaaSAvailabilitySnapshots(options = {}) {
  const pool = await getSqlPool();
  if (!pool) {
    return { rows: [] };
  }

  if (!(await ensurePaaSAvailabilitySnapshotSchema(pool))) {
    return { rows: [] };
  }

  const requestedService = String(options.requestedService || '').trim();
  const normalizedMaxAge = Math.max(1, Math.min(Number(options.maxAgeHours || 168), 24 * 365));

  const runRequest = pool.request();
  runRequest.input('maxAgeHours', sql.Int, normalizedMaxAge);
  let runQuery = `
    SELECT TOP (1)
      runId,
      capturedAtUtc,
      requestedService,
      requestedRegionPreset,
      requestedRegionsJson,
      metadataJson
    FROM dbo.PaaSAvailabilitySnapshot
    WHERE capturedAtUtc >= DATEADD(hour, -@maxAgeHours, SYSUTCDATETIME())
  `;

  if (requestedService) {
    runRequest.input('requestedService', sql.NVarChar(64), requestedService);
    runQuery += ` AND requestedService = @requestedService`;
  }

  runQuery += ` ORDER BY capturedAtUtc DESC, paasAvailabilitySnapshotId DESC`;

  const runResult = await runRequest.query(runQuery);
  const runRow = runResult.recordset && runResult.recordset[0];
  if (!runRow) {
    return { rows: [] };
  }

  const rowRequest = pool.request();
  rowRequest.input('runId', sql.UniqueIdentifier, runRow.runId);
  const rowResult = await rowRequest.query(`
    SELECT
      runId,
      capturedAtUtc,
      requestedService,
      requestedRegionPreset,
      requestedRegionsJson,
      metadataJson,
      category,
      service,
      region,
      resourceType,
      name,
      displayName,
      edition,
      tier,
      family,
      status,
      available,
      zoneRedundant,
      quotaCurrent,
      quotaLimit,
      metricPrimary,
      metricSecondary,
      detailsJson
    FROM dbo.PaaSAvailabilitySnapshot
    WHERE runId = @runId
    ORDER BY service ASC, region ASC, category ASC, name ASC
  `);

  return {
    runId: runRow.runId,
    capturedAtUtc: runRow.capturedAtUtc,
    requestedService: runRow.requestedService,
    requestedRegionPreset: runRow.requestedRegionPreset,
    requestedRegions: (() => {
      try {
        return JSON.parse(runRow.requestedRegionsJson || '[]');
      } catch {
        return [];
      }
    })(),
    metadata: (() => {
      try {
        return JSON.parse(runRow.metadataJson || 'null');
      } catch {
        return null;
      }
    })(),
    rows: (rowResult.recordset || []).map((row) => ({
      runId: row.runId,
      capturedAtUtc: row.capturedAtUtc,
      category: row.category,
      service: row.service,
      region: row.region,
      resourceType: row.resourceType,
      name: row.name,
      displayName: row.displayName,
      edition: row.edition,
      tier: row.tier,
      family: row.family,
      status: row.status,
      available: typeof row.available === 'boolean' ? row.available : null,
      zoneRedundant: typeof row.zoneRedundant === 'boolean' ? row.zoneRedundant : null,
      quotaCurrent: row.quotaCurrent,
      quotaLimit: row.quotaLimit,
      metricPrimary: row.metricPrimary,
      metricSecondary: row.metricSecondary,
      details: (() => {
        try {
          return JSON.parse(row.detailsJson || 'null');
        } catch {
          return null;
        }
      })()
    }))
  };
}

async function getLatestLivePlacementSnapshots(desiredCount = 1, maxAgeHours = 168) {
  const pool = await getSqlPool();
  if (!pool) {
    return [];
  }

  if (!(await ensureLivePlacementSnapshotSchema(pool))) {
    return [];
  }

  const normalizedDesiredCount = Math.max(1, Math.min(Number(desiredCount || 1), 1000));
  const normalizedMaxAge = Math.max(1, Math.min(Number(maxAgeHours || 168), 24 * 365));

  const request = pool.request();
  request.input('desiredCount', sql.Int, normalizedDesiredCount);
  request.input('maxAgeHours', sql.Int, normalizedMaxAge);

  const result = await request.query(`
    WITH RankedSnapshots AS (
      SELECT
        capturedAtUtc,
        desiredCount,
        region,
        skuName,
        livePlacementScore,
        livePlacementAvailable,
        livePlacementRestricted,
        warningMessage,
        ROW_NUMBER() OVER (
          PARTITION BY region, skuName
          ORDER BY capturedAtUtc DESC, livePlacementSnapshotId DESC
        ) AS rn
      FROM dbo.LivePlacementSnapshot
      WHERE desiredCount = @desiredCount
        AND capturedAtUtc >= DATEADD(hour, -@maxAgeHours, SYSUTCDATETIME())
    )
    SELECT
      capturedAtUtc,
      region,
      skuName,
      livePlacementScore,
      livePlacementAvailable,
      livePlacementRestricted,
      warningMessage
    FROM RankedSnapshots
    WHERE rn = 1
  `);

  return (result.recordset || []).map((row) => ({
    capturedAtUtc: row.capturedAtUtc,
    region: row.region,
    sku: row.skuName,
    livePlacementScore: row.livePlacementScore,
    livePlacementAvailable: typeof row.livePlacementAvailable === 'boolean' ? row.livePlacementAvailable : null,
    livePlacementRestricted: typeof row.livePlacementRestricted === 'boolean' ? row.livePlacementRestricted : null,
    warning: row.warningMessage
  }));
}

async function ensureVmSkuCatalogSchema(pool) {
  return tableExists(pool, 'dbo.VmSkuCatalog');
}

async function upsertVmSkuCatalogRows(rows) {
  const pool = await getSqlPool();
  if (!pool || !Array.isArray(rows) || rows.length === 0) {
    return { upserted: 0 };
  }

  if (!(await ensureVmSkuCatalogSchema(pool))) {
    return { upserted: 0 };
  }

  // Deduplicate by (family, name) within the batch.
  const dedup = new Map();
  rows.forEach((row) => {
    const family = String(row?.skuFamily || '').trim();
    const name = String(row?.skuName || '').trim();
    if (!family || !name) return;
    const key = `${family.toLowerCase()}|${name.toLowerCase()}`;
    if (!dedup.has(key)) {
      dedup.set(key, {
        skuFamily: family,
        skuName: name,
        vCpu: row.vCpu == null ? null : Number(row.vCpu),
        memoryGB: row.memoryGB == null ? null : Number(row.memoryGB)
      });
    }
  });
  const items = [...dedup.values()];
  if (items.length === 0) {
    return { upserted: 0 };
  }

  const json = JSON.stringify(items);
  const request = pool.request();
  request.input('payload', sql.NVarChar(sql.MAX), json);
  await request.query(`
    DECLARE @now DATETIME2 = SYSUTCDATETIME();
    MERGE dbo.VmSkuCatalog AS target
    USING (
      SELECT
        skuFamily,
        skuName,
        vCpu,
        memoryGB
      FROM OPENJSON(@payload)
      WITH (
        skuFamily NVARCHAR(128) '$.skuFamily',
        skuName NVARCHAR(128) '$.skuName',
        vCpu INT '$.vCpu',
        memoryGB DECIMAL(10,2) '$.memoryGB'
      )
    ) AS source
      ON target.skuFamily = source.skuFamily AND target.skuName = source.skuName
    WHEN MATCHED THEN UPDATE SET
      vCpu = COALESCE(source.vCpu, target.vCpu),
      memoryGB = COALESCE(source.memoryGB, target.memoryGB),
      lastSeenUtc = @now
    WHEN NOT MATCHED THEN INSERT (skuFamily, skuName, vCpu, memoryGB, firstSeenUtc, lastSeenUtc)
      VALUES (source.skuFamily, source.skuName, source.vCpu, source.memoryGB, @now, @now);
  `);

  return { upserted: items.length };
}

async function getVmSkuCatalogFamilies() {
  const pool = await getSqlPool();
  if (!pool) {
    return null;
  }
  if (!(await ensureVmSkuCatalogSchema(pool))) {
    return null;
  }
  const result = await pool.request().query(`
    SELECT skuFamily, skuName, vCpu, memoryGB
    FROM dbo.VmSkuCatalog
    ORDER BY skuFamily, skuName
  `);
  return result.recordset || [];
}

async function ensurePhase3SchemaForPool(pool) {
  const requiredTables = [
    'dbo.CapacitySnapshot',
    'dbo.Subscriptions',
    'dbo.CapacityScoreSnapshot',
    'dbo.LivePlacementSnapshot',
    'dbo.PaaSAvailabilitySnapshot',
    'dbo.DashboardErrorLog',
    'dbo.DashboardOperationLog',
    'dbo.DashboardSetting',
    'dbo.VmSkuCatalog',
    'dbo.AIModelAvailability'
  ];
  const missingTables = [];

  for (const tableName of requiredTables) {
    if (!(await tableExists(pool, tableName))) {
      missingTables.push(tableName);
    }
  }

  if (missingTables.length > 0) {
    throw new Error(`Database schema is not fully provisioned via DACPAC. Missing objects: ${missingTables.join(', ')}`);
  }

  return {
    ok: true,
    schemaManagedBy: 'dacpac',
    missingTables
  };
}

async function ensurePhase3Schema() {
  const pool = await getSqlPool();
  if (!pool) {
    throw new Error('SQL connection is not configured.');
  }

  return ensurePhase3SchemaForPool(pool);
}

module.exports = {
  getSqlPool,
  resetSqlPool,
  createSqlPoolWithAccessToken,
  insertCapacitySnapshots,
  upsertSubscriptions,
  getSubscriptionsFromTable,
  ensureSubscriptionsTableSchema,
  insertCapacityScoreSnapshots,
  insertQuotaCandidateSnapshots,
  getCapacityScoreSnapshotHistory,
  getQuotaCandidateSnapshots,
  listQuotaCandidateRuns,
  ensureLivePlacementSnapshotSchema,
  saveLivePlacementSnapshots,
  getLatestLivePlacementSnapshots,
  ensurePaaSAvailabilitySnapshotSchema,
  savePaaSAvailabilitySnapshots,
  getLatestPaaSAvailabilitySnapshots,
  ensureDashboardErrorLogSchema,
  insertDashboardErrorLog,
  listDashboardErrorLogs,
  ensureDashboardOperationLogSchema,
  logDashboardOperation,
  listDashboardOperations,
  ensureDashboardSettingSchema,
  getDashboardSettings,
  getDashboardSettingsPersistence,
  upsertDashboardSettings,
  ensurePhase3SchemaForPool,
  ensurePhase3Schema,
  ensureVmSkuCatalogSchema,
  upsertVmSkuCatalogRows,
  getVmSkuCatalogFamilies
};
