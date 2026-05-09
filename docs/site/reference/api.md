# API Reference

All API endpoints are served from the App Service Express application.

---

## Auth levels

| Level | Middleware | Who |
|---|---|---|
| **Public** | none | Any caller, no authentication required |
| **User** | `requireAuth` | Any authenticated Entra user |
| **Admin** | `requireAdmin` | Members of the configured `ADMIN_GROUP_ID` Entra group |
| **Internal** | `requireIngestKey` | Requests with `x-ingest-api-key` header matching `INGEST_API_KEY` |

---

## Error format

All error responses use a consistent JSON envelope with a correlation ID for log lookup:

```json
{
  "error": "Failed to retrieve family summary.",
  "ref": "3827140a-d475-4cd7-875b-04953f50e0c1"
}
```

Use the `ref` value to search Application Insights logs:

```kql
traces
| where customDimensions.correlationId == "3827140a-d475-4cd7-875b-04953f50e0c1"
| order by timestamp asc
```

---

## Health

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/healthz` | Public | Liveness + DB readiness check. Returns `{ status: "ok" }` or `{ status: "degraded" }` with HTTP 503 if SQL is unreachable. |

---

## Capacity

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/capacity` | Public | VM SKU capacity data with filters |
| `GET` | `/api/capacity/paged` | Public | Paginated capacity data |
| `GET` | `/api/capacity/export` | Public | Download capacity data as Excel |
| `GET` | `/api/capacity/families` | Public | VM family summary grouped by family and region |
| `GET` | `/api/capacity/analytics` | Public | Aggregate analytics over the capacity snapshot |
| `GET` | `/api/capacity/trends` | Public | Capacity trend data over time |
| `GET` | `/api/capacity/scores` | Public | Placement score results |
| `GET` | `/api/capacity/scores/history` | Public | Historical placement score records |
| `POST` | `/api/capacity/scores/live` | Public | Compute live placement scores on demand |
| `POST` | `/api/capacity/recommendations` | Public | Get capacity recommendations from worker |
| `GET` | `/api/capacity/subscriptions` | Public | List subscriptions present in the capacity snapshot |

### Common query parameters (capacity endpoints)

| Parameter | Description | Example |
|---|---|---|
| `regionPreset` | Named region group filter | `USMajor`, `All` |
| `region` | Specific region or `all` | `eastus`, `all` |
| `family` | VM family filter or `all` | `Standard_D`, `all` |
| `familyBase` | Base family filter or `all` | `Standard_D`, `all` |
| `sku` | Specific VM SKU or `all` | `Standard_D4s_v5`, `all` |
| `availability` | Availability state filter or `all` | `Available`, `all` |
| `resourceType` | Resource type or `all` | `virtualMachines`, `all` |
| `subscriptionIds` | Comma-separated subscription IDs or `all` | `sub1,sub2`, `all` |

---

## Subscriptions

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/subscriptions` | Public | List all Azure subscriptions available to the app's managed identity |

---

## SKU Catalog

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/sku-catalog/families` | Public | Available VM families from the SKU catalog |

---

## AI Models

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/ai/models` | Public | Azure AI model availability by region |
| `GET` | `/api/ai/models/providers` | Public | AI providers list |
| `GET` | `/api/ai/models/regions` | Public | Regions with AI model availability |
| `GET` | `/api/ai/quota/providers` | Public | AI quota by provider |
| `GET` | `/api/ai/quota` | Public | AI quota summary |

---

## PaaS Availability

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/paas-availability` | Public | PaaS service availability by region |
| `GET` | `/api/paas-availability/probe` | Public | Probe PaaS availability data freshness |
| `POST` | `/api/paas-availability/refresh` | Public | Trigger PaaS availability refresh |

---

## Auth

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/auth/me` | Public | Returns current user info or `{ authenticated: false }` |

---

## Quota (User)

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/quota/groups` | User | Quota groups and headroom by subscription/family |
| `GET` | `/api/quota/management-groups` | User | Management group hierarchy. Requires `QUOTA_MANAGEMENT_GROUP_ID` to be set. |
| `GET` | `/api/quota/shareable-report` | User | Generate a shareable quota report link |

---

## Quota (Admin)

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/quota/candidates` | Admin | Quota increase candidates |
| `POST` | `/api/quota/candidates/capture` | Admin | Capture current quota state as a candidate snapshot |
| `GET` | `/api/quota/candidate-runs` | Admin | Candidate run history |
| `GET` | `/api/quota/plan` | Admin | Quota increase plan |
| `POST` | `/api/quota/simulate` | Admin | Simulate a quota increase request |
| `POST` | `/api/quota/apply` | Admin | Submit quota increase to ARM |
| `GET` | `/api/quota/apply/jobs/:jobId` | Admin | Check status of a submitted quota job |

---

## Admin

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/api/admin/config` | Admin | Current app configuration (safe subset of env vars) |
| `GET` | `/api/admin/sql-preview` | Admin | Preview SQL table contents |
| `GET` | `/api/admin/recommendations/diagnostics` | Admin | Recommendations engine diagnostics |
| `POST` | `/api/admin/ingest/capacity` | Admin | Trigger capacity ingestion |
| `GET` | `/api/admin/ingest/status` | Admin | Current ingestion status |
| `POST` | `/api/admin/ingest/model-catalog` | Admin | Trigger AI model catalog ingestion |
| `GET` | `/api/admin/ingest/jobs/:jobId` | Admin | Ingestion job status |
| `GET` | `/api/admin/ingest/schedule` | Admin | Current ingestion schedule configuration |
| `PUT` | `/api/admin/ingest/schedule` | Admin | Update ingestion schedule |
| `GET` | `/api/admin/ui-settings` | Admin | UI settings from DB |
| `PUT` | `/api/admin/ui-settings` | Admin | Update UI settings |
| `POST` | `/api/admin/errors/log` | User | Log a client-side error |
| `GET` | `/api/admin/errors` | Admin | View error log |
| `POST` | `/api/admin/operations/log` | User | Log a user operation |
| `GET` | `/api/admin/operations` | Admin | View operations log |

---

## Internal (worker-to-API)

These endpoints require the `x-ingest-api-key` header matching `INGEST_API_KEY`.

| Method | Path | Description |
|---|---|---|
| `POST` | `/internal/ingest/capacity` | Trigger full capacity ingestion from worker |
| `GET` | `/internal/ingest/status` | Ingestion run status |
| `GET` | `/internal/diagnostics/report-counts` | Row counts for all reporting tables |
| `GET` | `/internal/diagnostics/sql-objects` | SQL schema object list |
| `GET` | `/internal/diagnostics/sql-ping` | SQL connection health check |
| `GET` | `/internal/diagnostics/capacity-read` | Read a sample of capacity data |
| `POST` | `/internal/db/ensure-phase3-schema` | Ensure Phase 3 schema is applied |
| `POST` | `/internal/db/bootstrap` | Bootstrap database schema |
| `POST` | `/internal/db/migrate` | Run a specific DB migration |
| `POST` | `/internal/db/normalize-family-casing` | Normalise VM family name casing in DB |
| `POST` | `/internal/db/bootstrap-admin` | Bootstrap admin configuration |
