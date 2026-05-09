# E2E Testing — CI Integration & Flakiness Prevention

## GitHub Actions Cross-Browser Matrix

```yaml
name: E2E Tests

on: [pull_request, push]

jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps chromium
      - run: npm run test:e2e -- --project=chromium
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/

  full-matrix:
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    strategy:
      matrix:
        browser: [chromium, firefox, webkit]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps ${{ matrix.browser }}
      - run: npx playwright test --project=${{ matrix.browser }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report-${{ matrix.browser }}
          path: playwright-report/
```

## Flakiness Prevention Checklist

```yaml
1. Eliminate Magic Sleeps:
   ❌ cy.wait(2000)  /  await sleep(2000)
   ✅ cy.contains('Loaded').should('be.visible')
   ✅ await page.waitForSelector('[data-loaded]')

2. Robust Locators:
   ❌ cy.get('div.container > div:nth-child(3) > button')
   ✅ cy.get('[data-testid="submit-btn"]')

3. Isolate Tests (Fresh Fixtures):
   ✅ beforeEach: create data, afterEach: clean up
   ❌ Tests that depend on previous test order

4. Mock External Dependencies:
   ✅ cy.intercept('/api/**', { fixture: 'data.json' })
   ❌ Tests that call real payment/email providers

5. Use Retry Logic:
   ✅ Playwright retries assertions automatically up to timeout
   ✅ CI retry: npx playwright test --retries=2

6. Deterministic Data:
   ✅ Generate unique IDs per test (e.g., Date.now() suffix)
   ❌ Hardcoded email addresses shared across tests
```

## Test Data Management

```typescript
// ❌ Wrong: assumes seed data exists
test('find user', async ({ page }) => {
  await page.goto('/users');
  await page.fill('[name="search"]', 'test@example.com');
  // Fails if DB was reset
});

// ✅ Right: create data in the test
test('find user', async ({ page, request }) => {
  const user = await request.post('/api/users', {
    data: { email: `test-${Date.now()}@example.com`, name: 'Test User' },
  });
  const { id } = await user.json();

  await page.goto('/users');
  await page.fill('[name="search"]', `test-${Date.now()}@example.com`);
  await expect(page.locator(`[data-user-id="${id}"]`)).toBeVisible();

  // Cleanup
  await request.delete(`/api/users/${id}`);
});
```

## Test Categorization Strategy

| Category | Trigger | Scope | Duration |
|---|---|---|---|
| Smoke | Every PR | Critical paths only | < 3 min |
| Full E2E | Merge to main | All user flows | < 15 min |
| Cross-browser | Nightly | Full matrix | < 30 min |
| Performance | Weekly | Core Web Vitals | < 10 min |
