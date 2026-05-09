---
description: "Use when adding, updating, or reviewing tests. Covers common testing best practices for regression protection, determinism, and change validation."
applyTo: "**/*"
---

# Testing Standards

Use this instruction when adding or modifying tests, or when validating risky changes.

## Expectations

- Test behavior, not implementation trivia.
- Add the smallest set of tests that protects against the real regression.
- Prefer deterministic tests with explicit fixtures and clear failure messages.
- Cover boundary conditions and error paths when the change affects them.
- If tests cannot be run, state that clearly and explain why.
- Prefer narrow, high-value tests over broad brittle suites.
- When fixing a bug, add a test that fails before the fix when feasible.

## Positive Test Guidance

- Add positive-path tests that prove expected behavior under valid inputs and normal conditions.
- Confirm the main success path returns the expected result, state change, or output.
- Include at least one realistic end-to-end happy path when integration behavior changes.

## Negative Test Guidance

- Add negative-path tests that prove invalid inputs and failure conditions are handled safely.
- Verify error messages, status codes, and fallback behavior are explicit and stable.
- Cover authorization failures, validation failures, dependency failures, and timeout paths when relevant.
- Ensure failures do not leak secrets, PII, or internal-only diagnostic details.

## Minimum Validation Checklist

- Existing tests relevant to the change still pass.
- New or changed behavior is exercised.
- Manual verification steps are noted when automation is missing.
- The test names make the protected behavior obvious.
- Positive and negative scenarios are both represented for changed behavior.

## Manual Test Strategy

Use the manual test strategy agents and skill when a change or feature needs explicit decisions about where human judgment is still required and what should graduate into automation.

### When to Apply

- A new feature or risk area has no documented manual scope.
- Exploratory work is informal or undocumented.
- A checklist or charter needs to be reproducible by a new team member.
- Automation candidates from manual testing need to be captured and filed.

### Agents

- **`agents/manual-test-strategy.agent.md`**: produces the full strategy — decision rubric, exploratory charter, regression checklist, defect template, and automation backlog with GitHub Issues filed for every candidate.
- **`agents/exploratory-charter.agent.md`**: generates one or more time-boxed exploratory sessions with mission, scope, evidence format, and triage routing. Files GitHub Issues for automation-worthy findings.
- **`agents/strategy-to-automation.agent.md`**: converts manual paths and rubric rows into tiered automation candidates (smoke, regression, integration, or agent spec) and files a GitHub Issue for every candidate without exception.

### Skill

- **`skills/manual-test-strategy/`**: provides the rubric, charter, checklist, and defect templates used by all three agents.

### Decision Rubric

Every behavior under manual test scope should be classified as one of:

| Classification | When to use |
| --- | --- |
| **Manual-only** | Human judgment required; exploratory, context-dependent, or infrequent |
| **Automate-now** | Stable, deterministic, high-value, frequently repeated |
| **Hybrid** | Core path can be scripted; edge cases or environment variation still need a manual pass |

See `skills/manual-test-strategy/rubric-template.md` for the full scoring matrix.

### Automation Handoff

- Automation candidates are never left implicit. Every identified candidate is filed as a GitHub Issue with labels `testing` and `automation-candidate`.
- Defect evidence records include an automation handoff section so future scripted coverage is easier to prioritize.
- Keep all strategy artifacts stack-agnostic: no framework-specific references belong in rubrics, charters, or checklists.

## Node.js Native Test Runner (Node 22+)

For projects using `node --test` instead of Jest or Vitest:

### Coverage

```bash
# Run tests with built-in coverage (Node 22+, no extra deps)
node --test --experimental-test-coverage

# With threshold enforcement (exits non-zero if below threshold)
node --test --experimental-test-coverage \
  --test-reporter=tap \
  | npx tap-parser --strict
```

Add to `package.json`:

```json
{
  "scripts": {
    "test":     "node --test",
    "coverage": "node --test --experimental-test-coverage"
  }
}
```

### CI Coverage Gate

```yaml
- name: Run tests with coverage
  run: npm run coverage
  env:
    NODE_V8_COVERAGE: ./coverage

- name: Enforce coverage threshold
  run: |
    # Parse lcov or use c8 for threshold gates
    npx c8 --check-coverage --lines 80 --functions 80 --branches 70 \
      node --test
```

Or use `c8` as a zero-config wrapper:

```json
{
  "scripts": {
    "coverage": "c8 --check-coverage --lines 80 node --test"
  }
}
```

### Test File Discovery

`node --test` auto-discovers files matching:
- `**/*.test.{js,mjs,cjs}`
- `**/*.spec.{js,mjs,cjs}`
- `**/test.{js,mjs,cjs}`
- Files inside `test/` or `tests/` directories

No config file required. To restrict: `node --test src/**/*.test.js`

## CLI-Driven Integration Testing

Tests that call real HTTP endpoints (not mocking the server) can be driven from the CLI
without a browser, making them CI-friendly and agent-runnable.

### Pattern

```js
// tests/routes.test.js — uses supertest, no browser needed
import assert from 'node:assert';
import { test, before, after } from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';

let app;
before(async () => { app = await createApp(); });
after(async ()  => { await app.close?.(); });

test('GET /health returns 200', async () => {
  const res = await request(app).get('/health');
  assert.strictEqual(res.status, 200);
});

test('GET /api/capacity returns 401 without auth', async () => {
  const res = await request(app).get('/api/capacity');
  assert.strictEqual(res.status, 401);
});
```

### Environment variable wiring for CLI testing

The app must read all config from environment variables — no hardcoded values, no interactive prompts.

```bash
# .env.local (gitignored) — used for local CLI runs
DATABASE_SERVER=localhost
DATABASE_NAME=test_db
PORT=3001
NODE_ENV=test
SESSION_SECRET=test-secret-minimum-32-chars-long
```

```bash
# Run integration tests from the CLI
cp .env.example .env.local   # fill in test values once
node --env-file=.env.local --test tests/routes.test.js
```

### CI integration test pattern

```yaml
- name: Run integration tests
  run: node --test --env-file=.env.ci tests/integration/
  env:
    DATABASE_SERVER: ${{ vars.TEST_DB_SERVER }}
    DATABASE_PASSWORD: ${{ secrets.TEST_DB_PASSWORD }}
    NODE_ENV: test
```

**Key principle:** If a test requires a browser or manual session cookie, it is not an
integration test — it is an E2E test. CLI-drivable tests must work with `supertest` or
direct HTTP calls using `node:http`. If your tests currently require a browser, refactor
the app to accept auth tokens via a test-bypass header (protected by `NODE_ENV === 'test'`).
