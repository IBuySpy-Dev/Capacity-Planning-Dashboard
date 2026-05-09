# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0] — 2025-06-13

### Added

- **Env vars reference** (#49): `docs/ENVIRONMENT_VARIABLES.md` documents all required and optional environment variables with descriptions, defaults, and security notes.
- **Docker Compose local dev** (#48): `docker-compose.yml` spins up SQL Server 2022 locally for development and integration testing without Azure dependencies.
- **Ingestion status in `/api/admin/config`** (#50): New `ingestion` section in the admin diagnostics endpoint exposes `lastRunAt`, `lastRunStatus`, `lastRunRecords`, `lastErrorMessage`, `inProgress`, and `regionErrorCount` for operational visibility.
- **Per-region ingestion isolation** (#51): Failed ARM/AI quota regions now return `[]` instead of aborting the entire ingestion run. `lastRegionErrors` and `regionErrorCount` track partial failures without blocking successful regions.
- **App Insights structured telemetry** (#52): `src/services/telemetry.js` wraps Application Insights with no-op safety when `APPLICATIONINSIGHTS_CONNECTION_STRING` is absent. Ingestion runs emit `IngestionStarted`, `IngestionCompleted`, and `IngestionFailed` events.
- **Dashboard loading/error UI states** (#53): Capacity grid and family summary now show distinct "Loading…" and "Error: …" states instead of blank rows on slow loads or API failures. Closes the support gap around the `/api/capacity/families` failure reference.
- **Data staleness badge** (#54): Header shows "Last refreshed X minutes ago" (or "Never") using the `/api/admin/ingest/status` endpoint. Badge is hidden while fetching and for non-admin users (403 → graceful no-op).

---

## [0.2.0] — 2026-05-09

### Added

- **`/api/admin/config` — App Insights status** (#40, #45): New `appInsights.configured` boolean field in the admin config diagnostics endpoint. Operators can instantly verify telemetry wiring without opening Azure Portal. The actual connection string never appears in the response.
- **CI integration test job** (#39, #46): Second CI job in `ci.yml` that spins up a SQL Server 2022 service container, starts the Express app, and asserts `sql.poolReady: true` via `/api/admin/config`. Catches DB connectivity regressions before they reach production. Also triggers on push to `main` (previously PR-only).
- **`bicep-deploy.yml` workflow** (#42, #44): New GitHub Actions workflow that deploys the Bicep IaC and automatically captures deployment outputs (`AZURE_WEBAPP_NAME`, `SQL_SERVER_NAME`, `SQL_DATABASE_NAME`, `KEY_VAULT_NAME`) as GitHub repository variables. Eliminates manual variable configuration after infrastructure changes.
- **DACPAC SQL workflows** (#29, #30): Separate GitHub Actions workflows for schema (`sql-schema.yml`), seed data (`sql-seed-data.yml`), and sample data (`sql-sample-data.yml`) deployment using SQL Server DACPAC packages.
- **`GET /api/admin/config` endpoint** (#18, #31): Sanitized runtime configuration snapshot for operator diagnostics. Secrets returned as `"set"` / `"not set"` only.
- **UI export buttons** (#27): Wired export buttons to `/api/capacity/export` with CSV/XLSX support and truncation warning when results exceed 50k rows.
- **Release runbooks** (#28): Added release verification checklist and rollback playbook to `docs/runbooks/`.

### Fixed

- **Bootstrap secrets/vars mismatch** (#42, #43): SQL DACPAC workflows and deploy workflow were referencing `secrets.AZURE_CLIENT_ID` / `AZURE_TENANT_ID` / `AZURE_SUBSCRIPTION_ID` but bootstrap pushes these as GitHub **variables** (`vars.`). All four workflows corrected. Closes the silent OIDC auth failure that prevented all post-bootstrap CI.
- **Error context persistence** (#34, #35): `requestId` from `sendErrorResponse` is now persisted to `dbo.DashboardErrorLog` so operators can look up a `[Ref xxxxxxxx]` error ID in the admin UI without log stream access. Affects `/api/capacity/families` and `/api/subscriptions` endpoints.
- **Bootstrap: `db_ddladmin` grant and UAA role scope** (#33): Bootstrap script now grants `db_ddladmin` to the managed identity so DACPAC migrations can create tables. Azure role assignments now correctly scoped to subscription (not resource group).
- **Infra: Key Vault references replace placeholder secrets** (#2, #26): Removed hardcoded placeholder values from Bicep params; all secrets now flow through Key Vault references.

### Changed

- **Bootstrap: OIDC-only** (#43): `setup-secrets.yml` deleted (superseded by `setup-infrastructure.yml` rewrite). Bootstrap now exclusively uses OIDC federated credentials — no client secrets stored.
- **Bootstrap resource discovery removed** (#44): Removed incorrect resource-name discovery from bootstrap script (bootstrap runs before Azure resources exist). Resource names now sourced from Bicep deployment outputs via `bicep-deploy.yml`.
- **CI workflow now triggers on `push` to `main`** (#39): In addition to `pull_request` triggers, CI (both unit and integration test jobs) now runs on every push to `main`.
- **`bicep-validate.yml` action versions** (#44): Fixed `checkout@v6` → `@v4` and `login@v3` → `@v2`.
- **`sql.js`: `SQL_TRUST_SERVER_CERTIFICATE` env var** (#39): Adds opt-in for trusting self-signed certs in CI/dev environments (Docker MSSQL). Defaults to `false`; never set in production.
- **Dependency upgrades** (#19): Express 4→5, mssql 11→12, msal-node 2→5, dotenv 16→17, GitHub Actions bumped to latest versions.
- **Design tokens and accessibility** (#36): CSS design token system, focus indicators, and heading hierarchy improvements. Button hierarchy applied to pagination and secondary actions.
- **Basecoat v3 upgrade** (#32): Framework upgraded to v3; security audit completed.

### Security

- All GitHub Actions workflows authenticating to Azure use OIDC federated credentials only. No service principal client secrets stored as GitHub Secrets.
- Key Vault references enforce secret isolation in Bicep parameter files.

---

## [0.1.0] — Initial release

- Initial Express.js capacity planning dashboard
- Azure SQL integration with MSI authentication
- Capacity ingestion from Azure Management API
- Live placement scoring
- PaaS availability scanning
- Quota candidate and move-plan workflows
- AI quota provider integration
- XLSX and CSV export

[0.2.0]: https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/IBuySpy-Dev/Capacity-Planning-Dashboard/releases/tag/v0.1.0
