---
description: "Reference map of GitHub Copilot usage APIs — which endpoints exist, which are missing for CLI/agent cost data, known workarounds, and the expected roadmap."
---

# Copilot CLI Usage API Landscape

Last reviewed: 2026-05-08

This document maps the available and unavailable GitHub and Microsoft APIs for accessing Copilot CLI and agent session usage data.

## Available APIs

> ⚠️ **API Migration (2026-04-02):** The legacy `/copilot/metrics` and `/copilot/usage`
> endpoints were sunset. All usage data is now under `/copilot/metrics/reports/`.

### GitHub REST — Copilot Usage Metrics (Current)

| Property | Value |
|---|---|
| Endpoint | `GET /orgs/{ORG}/copilot/metrics/reports/organization-28-day/latest` |
| Auth | `Bearer <GitHub token>` with `admin:org` or `read:org` scope |
| Returns | Download link to NDJSON report: DAU, CLI users, agent users, weekly active users (28-day window) |
| Also available | `organization-1-day?day=YYYY-MM-DD`, `users-1-day`, `users-28-day/latest` |
| Limitation | **Does not include per-session cost, model identity, or token-level data** |
| Docs | <https://docs.github.com/en/rest/copilot/copilot-usage-metrics> |

### GitHub REST — Copilot Billing

| Property | Value |
|---|---|
| Endpoint | `GET /orgs/{org}/copilot/billing` |
| Auth | `Bearer <GitHub token>` with `manage_billing:copilot` scope |
| Returns | Seat count, plan type, and billing cycle information |
| Limitation | **No per-model usage, per-session cost, or token-level data** |
| Docs | <https://docs.github.com/en/rest/copilot/copilot-billing> |

### GitHub REST — Copilot Metrics (Enterprise)

| Property | Value |
|---|---|
| Endpoint | `GET /enterprises/{enterprise}/copilot/metrics/reports/enterprise-28-day/latest` |
| Auth | `Bearer <GitHub token>` with `admin:org` scope |
| Returns | Download link to NDJSON report with enterprise-wide aggregate metrics |
| ~~Legacy~~ | ~~`GET /enterprises/{enterprise}/copilot/metrics`~~ — **sunset 2026-04-02** |
| Docs | <https://docs.github.com/en/rest/copilot/copilot-usage-metrics> |

## Missing / Unavailable APIs

### Per-Session CLI Usage

| Property | Value |
|---|---|
| Expected endpoint | `GET /orgs/{org}/copilot/sessions` or similar |
| Status | ❌ **Does not exist** (returns 404 or is undocumented) |
| Gap | No API exposes per-session token counts, model identifiers, or cost data for Copilot CLI/agent runs |
| Impact | Session cost must be estimated; no authoritative cost-per-issue metric is available |

### Power BI Copilot Usage Dataset

| Property | Value |
|---|---|
| Dataset ID | `<copilot-usage-dataset-id>` (Copilot Usage dataset in Power BI service) |
| Status | ❌ **Auth error** (`AADSTS9010010` — required resource is not listed in the token's `aud` claim) |
| Gap | The standard MCP Power BI token does not include the AAD scope for this dataset's resource |
| Workaround | Requires a separate service principal with `PowerBI.ReadAll` or a delegated token with the dataset's resource in `aud` |
| Impact | Historical trend analysis, territory rollups, and model efficiency comparisons are unavailable until auth is resolved |

## Workarounds (Short-Term)

1. **Self-tracking** — use `skills/copilot-usage-analytics/templates/session-cost-estimate-template.md` to manually record dispatch counts and estimate tokens.
2. **Workflow logging** — inject a final step in every GitHub Actions agent workflow to emit a structured cost-estimate log entry.
3. **Browser billing dashboard** — export the GitHub billing dashboard screenshot or CSV monthly for manual aggregation.

## Roadmap and Watch Items

| Item | Expected Availability | Notes |
|---|---|---|
| Copilot Metrics API — CLI extension | Unknown | GitHub has signaled expansion; monitor GitHub Changelog |
| Power BI auth fix | Requires operator action | Provision a service principal with the correct AAD resource scope |
| Per-model cost line items in billing | Unknown | Not on any public roadmap as of last review |

## References

- GitHub Copilot REST API docs: <https://docs.github.com/en/rest/copilot>
- GitHub Changelog (monitor for Metrics API updates): <https://github.blog/changelog>
- Power BI REST API — datasets: <https://learn.microsoft.com/en-us/rest/api/power-bi/datasets>
