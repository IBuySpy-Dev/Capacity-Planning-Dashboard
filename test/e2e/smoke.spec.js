const { test, expect } = require('@playwright/test');
const { spawn } = require('child_process');
const path = require('path');

test('app shell loads with capacity grid visible', async ({ page }) => {
  await page.goto('/classic');
  await expect(page.locator('#topbarReportTitle')).toContainText('Capacity Planning Dashboard');
  await expect(page.locator('#capacityGrid')).toBeVisible();
});

test('auth-protected API returns 401 when auth is enabled', async () => {
  const child = spawn(process.execPath, ['scripts/start-e2e-server.js'], {
    cwd: path.resolve(__dirname, '..', '..'),
    env: {
      ...process.env,
      PORT: '4174',
      AUTH_ENABLED: 'true',
      SESSION_SECRET: 'e2e-auth-enabled-secret'
    },
    stdio: 'ignore'
  });

  try {
    await waitForHealthy('http://127.0.0.1:4174/healthz');

    const response = await fetch('http://127.0.0.1:4174/api/capacity/preflight', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }]
      })
    });
    expect(response.status).toBe(401);
  } finally {
    child.kill('SIGTERM');
    await waitForExit(child);
  }
});

test('capacity smoke flow covers grid, preflight, and export', async ({ request }) => {
  const capacityResponse = await request.get('/api/capacity');
  expect(capacityResponse.status()).toBe(200);

  const capacityPayload = await capacityResponse.json();
  expect(Array.isArray(capacityPayload.rows)).toBe(true);
  expect(capacityPayload.rows.length).toBeGreaterThan(0);
  expect(capacityPayload.rows[0].sku).toBe('Standard_D4s_v5');
  expect(capacityPayload.rows[0].region).toBe('eastus');

  const preflightResponse = await request.post('/api/capacity/preflight', {
    data: {
      resources: [{ sku: 'Standard_D4s_v5', region: 'eastus', count: 1 }],
      options: { minScore: 60, topAlternatives: 2 }
    }
  });

  expect(preflightResponse.status()).toBe(200);
  const preflightPayload = await preflightResponse.json();
  expect(preflightPayload.ok).toBe(true);
  expect(Array.isArray(preflightPayload.resources)).toBe(true);
  expect(preflightPayload.resources).toHaveLength(1);
  expect(preflightPayload.resources[0].sku).toBe('Standard_D4s_v5');
  expect(preflightPayload.resources[0].region).toBe('eastus');
  expect(['go', 'warn', 'no-go']).toContain(preflightPayload.resources[0].verdict);

  const exportResponse = await request.get('/api/capacity/export?format=csv');
  expect(exportResponse.status()).toBe(200);
  expect(exportResponse.headers()['content-type']).toContain('text/csv');
  expect(exportResponse.headers()['content-disposition']).toContain('attachment; filename="capacity-dashboard-');

  const exportBody = await exportResponse.text();
  expect(exportBody).toContain('Standard_D4s_v5');
  expect(exportBody).toContain('eastus');
});

async function waitForHealthy(url, timeoutMs = 30_000) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      const response = await fetch(url);
      if (response.ok) {
        return;
      }
    } catch {
      // Server not ready yet.
    }
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
  throw new Error(`Timed out waiting for server health check: ${url}`);
}

async function waitForExit(child, timeoutMs = 10_000) {
  await new Promise((resolve) => {
    if (child.killed) {
      resolve();
      return;
    }

    const timer = setTimeout(() => {
      if (!child.killed) {
        child.kill('SIGKILL');
      }
      resolve();
    }, timeoutMs);

    child.once('exit', () => {
      clearTimeout(timer);
      resolve();
    });
  });
}
