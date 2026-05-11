# Sprint Backlog Burndown Learnings

Date: 2026-05-11

This reference captures five durable patterns from backlog burndown work tracked in issue #103.

## Bearer auth + CodeQL rate-limit finding

**Pattern**

Bearer token support on API routes can trigger CodeQL CWE-307 findings if requests are not rate limited.

**Problem**

Adding Bearer auth increases the risk of brute-force or high-volume request abuse. CodeQL flags the auth path when API routes are protected but not rate limited.

**Fix/Workaround**

Apply `express-rate-limit` globally to `/api/` so Bearer-authenticated and session-authenticated calls share the same protection envelope.

**References**

- Issue #103
- `src/server.js` (`const apiLimiter = rateLimit(...)`, `app.use('/api/', apiLimiter)`)
- `src/middleware/auth.js` (`verifyBearerToken`)

## Admin-gated endpoints silently break UI badges

**Pattern**

Read-only metadata endpoints should use `requireAuth`, not `requireAdmin`, when regular signed-in users depend on them for UI status.

**Problem**

When metadata endpoints are admin-gated, regular users receive `401` or `403` responses and the dashboard falls back to stale UI states such as `Last ingested: Never`.

**Fix/Workaround**

Use `requireAuth` for read-only metadata and status endpoints. Reserve `requireAdmin` for write operations or privileged diagnostics.

**References**

- Issue #103
- `src/server.js` (`GET /api/ingest/last-success`)
- `src/server.js` (`GET /api/admin/config`)
- `src/middleware/auth.js` (`requireAuth`, `requireAdmin`)

## Squash merge local cleanup always needs force delete

**Pattern**

After a squash merge, local branch cleanup should assume the feature branch tip is no longer an ancestor of `main`.

**Problem**

`git branch -d` checks for merged ancestry and fails after squash merges because the original branch commit graph is not preserved.

**Fix/Workaround**

Use `git branch -D <branch>` for local cleanup after confirming the PR was squash-merged.

**References**

- Issue #103
- Local git cleanup workflow after squash merge

## Preflight endpoint fan-out pattern

**Pattern**

Preflight capacity checks should fan out per resource with `Promise.allSettled()` and classify each result independently.

**Problem**

A single slow or failing dependency can block the entire preflight response when the endpoint waits on all resources as one failure domain.

**Fix/Workaround**

Use `Promise.allSettled()` for per-resource evaluation, then classify each resource as `go`, `warn`, or `no-go` so partial results remain available to operators.

**References**

- Issue #103
- `src/server.js` (`POST /api/capacity/preflight`)
- `src/server.js` (`const settled = await Promise.allSettled(...)`)

## App Roles for M2M auth need manual Entra setup

**Pattern**

Machine-to-machine auth can validate `roles` claims in code, but the backing App Roles still require manual setup in the Entra app registration.

**Problem**

The API can correctly enforce roles from a Bearer token while deployments still fail operationally if `Dashboard.Read` and `Dashboard.Admin` App Roles were never created and assigned in Entra.

**Fix/Workaround**

Keep the code-side roles validation, but document and perform the Entra app registration step manually: create `Dashboard.Read` and `Dashboard.Admin`, assign them to callers, and validate the resulting `roles` claim in issued tokens.

**References**

- Issue #103
- `src/middleware/auth.js` (Bearer token validation and `roles` claim handling)
- Azure Entra app registration configuration for dashboard API roles
