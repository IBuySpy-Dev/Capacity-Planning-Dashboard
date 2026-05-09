# E2E Testing — Playwright Patterns

## Setup

```bash
npm install -D @playwright/test
npx playwright install  # install browsers
```

### playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests/e2e',
  workers: 4,
  timeout: 30_000,
  expect: { timeout: 5_000 },
  reporter: [['list'], ['html', { outputFolder: 'playwright-report' }]],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
```

## Test Patterns

### Basic Structure

```typescript
import { test, expect } from '@playwright/test';

test('checkout flow', async ({ page }) => {
  await page.goto('/');
  await page.locator('[data-testid="search-input"]').fill('Blue Widget');
  await page.locator('button:has-text("Search")').click();
  await expect(page.locator('text=Blue Widget')).toBeVisible();
});
```

### Smart Waits (No Magic Sleeps)

```typescript
// ❌ Wrong: hardcoded sleep
await page.click('button');
await new Promise(r => setTimeout(r, 2000));

// ✅ Right: smart wait
await page.click('button');
await page.waitForSelector('h1:has-text("Loaded")');
```

### Locator Robustness Order

```typescript
// 1. Best: test ID
page.locator('[data-testid="submit-btn"]')

// 2. Good: ARIA role
page.locator('role=button[name="Submit"]')

// 3. Okay: text selector
page.locator('text="Submit"')

// ❌ Avoid: XPath or deep CSS
page.locator('//div/div/button[3]')
```

### Fixtures — Authenticated State

```typescript
import { test as base } from '@playwright/test';

export const test = base.extend({
  authenticatedPage: async ({ page }, use) => {
    await page.goto('/login');
    await page.fill('[name="email"]', 'test@example.com');
    await page.fill('[name="password"]', 'test-password');
    await page.click('button:has-text("Login")');
    await page.waitForNavigation();
    await use(page);
  },
});
```

### API Mocking

```typescript
test('show error when API fails', async ({ page }) => {
  await page.route('**/api/users/**', route => route.abort('failed'));
  await page.goto('/users');
  await expect(page.locator('text=Error loading users')).toBeVisible();
});
```

## Accessibility Testing

```typescript
import { injectAxe, checkA11y } from 'axe-playwright';

test('page is accessible', async ({ page }) => {
  await page.goto('/');
  await injectAxe(page);
  await checkA11y(page);
});
```

## Performance Assertions

```typescript
test('LCP under 2.5s', async ({ page }) => {
  const timing = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0];
    return { lcp: nav.domInteractive };
  });
  expect(timing.lcp).toBeLessThan(2500);
});
```
