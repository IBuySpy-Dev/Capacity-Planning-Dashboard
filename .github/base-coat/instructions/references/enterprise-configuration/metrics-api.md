# Enterprise Configuration — Metrics API Reference

## Enable Usage Metrics Policy

**Via Web UI:**

1. Enterprise → Settings → Policies → Copilot
2. Scroll to **Usage metrics**
3. Toggle **Enable usage metrics for this enterprise**
4. Save

**Via API (requires `admin:enterprise` scope):**

```bash
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/enterprises/{enterprise_slug}/settings/policies/copilot"
# Response includes: copilot_metrics_enabled (true/false)
```

## API Endpoints (Post-2026-04-02)

> The old `GET /orgs/{org}/copilot/metrics` endpoint was **sunset 2026-04-02**.
> Use the reports API below.

```bash
# 28-day rolling report (latest)
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-28-day/latest"

# 1-day report for a specific date
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-1-day?day=YYYY-MM-DD"

# Per-user breakdown (28-day)
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/users-28-day/latest"

# Response: { "download_links": ["<url>"], "report_start_day": "...", "report_end_day": "..." }
# Download the NDJSON file — each line: daily_active_users, engagement_metrics,
# language_breakdown, editor_breakdown, model_breakdown
```

Required scopes: `admin:org` or `read:org` (no `manage_billing:copilot` needed).

## Common Issues

**404 on metrics endpoint:**

- Enterprise admin has NOT enabled the usage metrics policy
- User does not have `admin:org` scope
- Organization does not have Copilot Business access

**Solution:** Follow "Enable Usage Metrics Policy" above.

**User cannot see Copilot in IDE:**

1. Check org has Copilot access: Enterprise → Settings → Policies → Copilot → Organization access
2. Check user has a seat: `GET /orgs/{org}/copilot/billing/seats?login={username}`
3. If not listed, assign seat via org settings or wait for auto-assignment
