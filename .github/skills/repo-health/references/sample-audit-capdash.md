# Repo Health Report — IBuySpy-Dev/Capacity-Planning-Dashboard

**Date:** 2026-05-09
**Auditor:** Copilot CLI (repo-health skill pilot run)
**Scope:** Full repo audit across 6 dimensions

---

## Overall Score

| Dimension | Score | One-line summary |
|---|---|---|
| CI Health | 🟡 | Deploy/CI 100%; DACPAC workflow 40% (3 historic failures now fixed) |
| Security Posture | 🟡 | Secret scanning ✅, Dependabot ✅, but branch protection not enabled |
| Dependency Hygiene | 🟢 | 0 vulnerabilities, all 11 deps current |
| Test Coverage | 🟡 | 9 test files, no coverage script or threshold enforcement |
| Governance | 🟡 | CHANGELOG ✅; CODEOWNERS, PR template, issue templates, .env.example all missing |
| Issue / PR Hygiene | 🟢 | 0 open issues, 0 open PRs |

**Summary:** 2 🟢 / 4 🟡 / 0 🔴

---

## 1. CI Health 🟡

| Workflow | Runs (last 30) | Pass % | Failures |
|---|---|---|---|
| Deploy Capacity Dashboard | 10+ | 100% | 0 |
| CI (tests) | 10+ | 100% | 0 |
| SQL Schema (DACPAC) | ~5 | 40% | 3 |

**Findings:**
- Deploy and CI workflows are stable — no concerns.
- DACPAC workflow had 3 failures (PR #72: missing `publicNetworkAccess=Enabled`; PR #73: wrong `sqlpackage` subcommand syntax). Both root causes are fixed and merged. Historic 40% rate will improve as recent successful runs accumulate.
- No stuck or in-progress runs at audit time.

**Score rationale:** YELLOW because DACPAC failures are recent and in the denominator, even though the root causes are resolved. Expected to reach GREEN within 5 successful DACPAC runs.

---

## 2. Security Posture 🟡

| Check | Status |
|---|---|
| Branch protection (main) | ❌ Not enabled |
| Required reviewers | ❌ (0 required) |
| Dismiss stale reviews | ❌ |
| Secret scanning | ✅ Enabled |
| Secret scanning AI detection | ✅ Enabled |
| Secret scanning push protection | ✅ Enabled |
| Non-provider pattern scanning | ✅ Enabled |
| Dependabot security updates | ✅ Enabled |
| Open Dependabot alerts | 0 |
| Open secret scanning alerts | 0 |

**Findings:**
- All scanning and Dependabot features are enabled — strong baseline.
- **Branch protection is absent on `main`.** Any team member can push directly. PRs can be merged without review. This is the primary security posture gap.
- No active vulnerability or secret alerts.

**Score rationale:** YELLOW (not RED) because scanning infrastructure is complete and no alerts are open. Branch protection is the single blocker to GREEN.

---

## 3. Dependency Hygiene 🟢

| Check | Status |
|---|---|
| `npm audit` critical | 0 |
| `npm audit` high | 0 |
| `npm audit` moderate | 0 |
| `npm audit` low | 0 |
| Outdated packages | None detected |
| Total production deps | 11 |
| GitHub Dependabot alerts | 0 |

**Dependency inventory:**

| Package | Version pinned |
|---|---|
| `@azure/identity` | ^4.5.0 |
| `@azure/msal-node` | ^5.2.0 |
| `applicationinsights` | ^3.14.0 |
| `connect-mssql-v2` | ^6.0.0 |
| `cors` | ^2.8.5 |
| `dotenv` | ^17.0.0 |
| `exceljs` | ^4.4.0 |
| `express` | ^5.2.1 |
| `express-session` | ^1.18.1 |
| `mssql` | ^12.5.2 |
| `supertest` | ^7.2.2 |

**Findings:**
- Zero vulnerabilities across all 11 deps. Clean.
- All packages appear current (no `npm outdated` output).
- Small dependency surface (11 packages) is a health positive — minimal exposure area.

---

## 4. Test Coverage 🟡

| Check | Status |
|---|---|
| Test files present | ✅ 9 files |
| Test runner (`node --test`) | ✅ configured in `package.json` |
| Coverage script in `package.json` | ❌ Missing |
| Coverage output directory | ❌ `coverage/` doesn't exist |
| CI enforces coverage threshold | ❌ No threshold in CI |

**Test files found:**
- `auth.test.js`
- `capacityService.test.js`
- `dtos.test.js`
- `familyNormalization.test.js`
- `livePlacementService.test.js`
- `quotaDiscoveryService.test.js`
- `routes.test.js`
- `sql.test.js`
- `telemetry.test.js`

**Findings:**
- Good test breadth — 9 files covering auth, services, DTOs, routes, SQL, and telemetry.
- Tests run in CI (`node --test`) but coverage is not measured or enforced.
- No `--experimental-test-coverage` flag in the test script and no threshold gates.
- Without a coverage number it's impossible to know what percentage of logic is exercised.

**Remediation:** Add `"coverage": "node --test --experimental-test-coverage"` to `package.json` scripts. Add a coverage threshold step to CI.

---

## 5. Governance Completeness 🟡

| File / Asset | Status |
|---|---|
| CODEOWNERS | ❌ Missing |
| PR template (`.github/pull_request_template.md`) | ❌ Missing |
| Issue templates (`.github/ISSUE_TEMPLATE/`) | ❌ Missing |
| CHANGELOG.md | ✅ Present |
| `.env.example` | ❌ Missing |
| `.gitignore` covers `.env` | ✅ |
| `.gitignore` covers `.env.local` | ❌ Missing |
| `.gitignore` covers `node_modules` | ✅ |

**Findings:**
- CHANGELOG is the only governance artifact present.
- CODEOWNERS missing means no automatic reviewer assignment on PRs — reviewers must be manually added every time.
- No PR template means contributors get a blank PR body, leading to inconsistent descriptions and missing issue references.
- No issue templates means bug reports and feature requests arrive in freeform text with no structured fields.
- `.env.example` missing violates the `env-example` guardrail in `docs/guardrails/` — new developers have no reference for required environment variables.
- `.gitignore` doesn't cover `.env.local`, which is a common local override file.

---

## 6. Issue / PR Hygiene 🟢

| Check | Value |
|---|---|
| Open issues | 0 |
| Open PRs | 0 |
| Stale issues (>14d no update) | 0 |
| Stale PRs (>14d) | 0 |

**Findings:**
- Perfectly clean. Backlog is fully burned down, no pending review work.

---

## Prioritized Remediation

| Priority | Dimension | Action | Effort |
|---|---|---|---|
| P1 | Security Posture | Enable branch protection on `main`: require 1 reviewer, dismiss stale reviews | Low |
| P2 | Governance | Add `.github/pull_request_template.md` using Basecoat template | Low |
| P3 | Governance | Add CODEOWNERS file assigning default reviewers | Low |
| P4 | Test Coverage | Add `--experimental-test-coverage` to test script; enforce 80% threshold in CI | Medium |
| P5 | Governance | Create `.env.example` documenting all required env vars | Low |
| P6 | Governance | Add `.env.local` to `.gitignore` | Low |
| P7 | Governance | Add issue templates (bug report, feature request) | Low |
| P8 | CI Health | Monitor DACPAC workflow — target 100% pass rate within 5 runs | None (monitor) |

---

## Notes for Future Audits

- This was the **pilot run** of the `repo-health` skill. The skill was authored based on what
  was useful to collect here and generalized for reuse.
- Re-run this audit at the start of each sprint to track trend.
- The DACPAC CI Health score should self-heal to 🟢 as recent successful runs accumulate.
- All P1–P3 items are Low effort — they can be bundled into a single governance PR.
