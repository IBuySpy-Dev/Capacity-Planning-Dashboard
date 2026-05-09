# Health & Monitoring

---

## Health check endpoint

`GET /healthz` returns the application and database health.

| Condition | HTTP | Body |
|---|---|---|
| App running, SQL connected | `200` | `{ "status": "ok", "checks": { "db": "ok" } }` |
| App running, SQL unreachable | `503` | `{ "status": "degraded", "checks": { "db": "error" } }` |
| App running, SQL not configured | `200` | `{ "status": "ok", "checks": { "db": "unconfigured" } }` |

The App Service health probe is configured to call `/healthz`. If it returns non-2xx for more than N consecutive checks, the runtime restarts the instance.

!!! warning
    A `503` from `/healthz` means the app cannot reach SQL. Check that:
    1. The managed identity has **SQL DB Contributor** on the database.
    2. The SQL server firewall allows traffic from the App Service VNet subnet.
    3. `SQL_SERVER` and `SQL_DATABASE` env vars are set correctly.

---

## Application Insights

The dashboard emits telemetry to Azure Application Insights when `APPLICATIONINSIGHTS_CONNECTION_STRING` is configured.

### Useful queries

**Recent errors with correlation IDs:**

```kql
exceptions
| where timestamp > ago(1h)
| project timestamp, type, outerMessage, customDimensions.correlationId
| order by timestamp desc
```

**Slow API calls:**

```kql
requests
| where timestamp > ago(1h) and duration > 2000
| project timestamp, name, duration, resultCode, url
| order by duration desc
```

**Ingestion run history:**

```kql
traces
| where message startswith "Ingestion"
| project timestamp, message, customDimensions
| order by timestamp desc
| take 50
```

**Look up a specific error ref:**

```kql
traces
| where customDimensions.correlationId == "<ref-id-from-error-response>"
| order by timestamp asc
```

---

## Key metrics to monitor

| Metric | Alert threshold | Description |
|---|---|---|
| App Service HTTP 5xx rate | > 5% over 5 min | Application errors |
| App Service response time (p95) | > 5s | Slow SQL or worker timeout |
| SQL DTU / CPU | > 80% sustained | Need to scale SQL tier |
| `/healthz` non-200 | Any | DB connection lost |
| Ingestion failure rate | > 2 consecutive | ARM auth or throttle issue |

---

## Log stream

For real-time debugging, stream App Service logs:

```bash
az webapp log tail --name app-capdash-prod --resource-group rg-capdash-prod
```

---

## Subscription access

The capacity data is scoped to Azure subscriptions that the App Service's **managed identity** has at least **Reader** access to.

If a subscription is missing from the capacity explorer:

1. Check that the subscription is accessible: `az account list --output table`
2. Verify the managed identity has **Reader** role on the subscription:
   ```bash
   az role assignment list \
     --assignee <managedIdentityPrincipalId> \
     --subscription <subscription-id>
   ```
3. If the role is missing, add it:
   ```bash
   az role assignment create \
     --assignee <managedIdentityPrincipalId> \
     --role Reader \
     --scope /subscriptions/<subscription-id>
   ```
4. Trigger a fresh ingestion from the Admin panel.
