---
title: Enterprise Configuration and Policy Setup
type: instruction
description: "Enterprise-level GitHub Copilot policy configuration, including usage metrics enablement, seat management, and security policies."
applyTo: "**/*"
distribute: false
---

# Enterprise Configuration and Policy Setup

This instruction file defines best practices for configuring GitHub Copilot at the enterprise level, including policies, seat management, usage metrics, and security controls.

## Overview

Enterprise admins configure GitHub Copilot policies that apply across all organizations and seats in the enterprise. This includes:

- **Seat management:** Allocate and revoke seats, configure auto-assignment
- **Usage metrics:** Enable visibility into adoption and usage patterns
- **Security:** Configure policy enforcement, secret scanning, code suggestions for public code
- **Billing:** Review seat costs, manage subscriptions

## Enterprise Admin Prerequisites

To manage Copilot policies, you must have:

- **Enterprise owner** or **Enterprise security admin** role in the GitHub organization
- Access to Enterprise → Settings → Policies (or GitHub Settings → Enterprise settings)
- `admin:enterprise` + `admin:org` OAuth scopes if using the GitHub API

### Verify Your Role

```bash
# Check if you can access enterprise settings
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/user/memberships/orgs" \
  | jq '.[] | select(.role == "admin")'

# If empty, you do not have admin permissions
```

## Seat Allocation and Management

### Enable Copilot Licenses

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Under **Copilot licenses**, select:
   - **Enable Copilot for organizations in this enterprise**
   - Choose **Individual seat assignment** or **Auto-assign seats** (recommended)
3. Set seat limit (e.g., 100 seats for 2,000 employees)

### Grant Copilot Access to Organizations

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Under **Organization access**, select which organizations can use Copilot
3. Assign seats via:
   - **Individual assignment:** Org admins manually add users
   - **Auto-assign:** Enable policy; Copilot auto-assigns seats to active developers

### Monitor Seat Usage

```bash
# Get seat assignments and activity
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/orgs/{org}/copilot/billing/seats" \
  | jq '.seats[] | {login, last_activity_at, created_at}'

# Response:
# - login: GitHub username
# - last_activity_at: Last Copilot activity
# - created_at: When seat was assigned
# - pending_cancellation_date: When seat will be revoked (if pending)
```

## Enable Copilot Usage Metrics

### Why Enable Usage Metrics?

Metrics enable enterprise admins to:

- Track Copilot adoption across the organization
- Monitor usage by language, editor, and time period
- Identify underutilized seats and optimize allocation
- Report on productivity trends
- Build data-driven ROI cases

### Enabling the Policy

**Via Web UI:**

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Scroll to **Usage metrics**
3. Toggle **Enable usage metrics for this enterprise**
4. Save

**Via GitHub API (requires `admin:enterprise` scope):**

```bash
# Check current policy status
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/enterprises/{enterprise_slug}/settings/policies/copilot"

# Response includes: copilot_metrics_enabled (true/false)
```

### After Enabling: What Data Becomes Available

Once enabled, org admins can access:

```bash
# Get 28-day rolling usage report (latest)
# Returns a download_links array pointing to NDJSON file on Azure Blob Storage
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-28-day/latest"

# Get 1-day report for a specific date
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-1-day?day=2026-05-07"

# NDJSON report fields (each line is a JSON object):
# - daily_active_users
# - daily_active_cli_users
# - daily_active_copilot_cloud_agent_users
# - weekly_active_users
# Per language, editor, model, etc.

# NOTE: Old endpoint GET /orgs/{org}/copilot/metrics was sunset 2026-04-02.
# Requires: admin:org or read:org scope (no manage_billing:copilot needed)
```

### Querying Metrics via API

```bash
# Get 28-day report (latest)
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-28-day/latest"

# Get 1-day report
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-1-day?day=YYYY-MM-DD"

# Per-user breakdown (28-day)
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/users-28-day/latest"

# Response is { "download_links": ["<url>"], "report_start_day": "...", "report_end_day": "..." }
# Download the NDJSON file — each line: total_active_users, engagement_metrics,
# language_breakdown, editor_breakdown, model_breakdown
```

### Common Issues

**Metrics endpoint returns 404:**

- Enterprise admin has NOT enabled the policy yet
- User does not have `admin:org` scope (if using API)
- Organization does not have Copilot Business access

**Solution:** Follow "Enabling the Policy" section above.

## Security Policies

### Configure Code Suggestion Controls

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Under **Code suggestions**, choose:
   - **Enable for all users:** (default) All users can get suggestions
   - **Disable for all users:** Block Copilot suggestions enterprise-wide
   - **Custom policy:** Allow by org/team (configure per org)

### Configure Public Code Indexing

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Under **Public code matching**, choose:
   - **Allow:** Copilot can reference publicly available code (enables better suggestions)
   - **Disallow:** Disable public code matching (more restrictive)

### Enable Secret Scanning for Copilot

1. Go to **Enterprise** → **Settings** → **Security** → **Secret scanning**
2. Enable **Secret scanning for Copilot** (alerts if generated code contains secrets)

## Billing and Cost Management

### Review Seat Costs

1. Go to **Enterprise** → **Settings** → **Billing** → **Copilot**
2. View:
   - **Total monthly cost:** Seats × $19/month
   - **Current seats used:** e.g., 45 of 100
   - **Per-model costs:** Claude, GPT-5.4, etc. (if available)

### Monitor Budget and Usage

```bash
# Get billing data
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/enterprises/{enterprise_slug}/settings/billing/usage"

# Response includes:
# - copilot_business_seats_used
# - copilot_business_seat_management_setting
```

**Note:** Per-model cost breakdown (e.g., "Claude Opus: $72.72") is only available in the web UI. See `tracking/github-api-billing-notes.md` for details.

## Enterprise Setup Checklist

Use this checklist when setting up GitHub Copilot for your enterprise:

### Phase 1: Governance (Week 1)

- [ ] Designate enterprise admin(s) for Copilot
- [ ] Document Copilot usage policy (who can use, restrictions, security requirements)
- [ ] Communicate policy to all teams
- [ ] Create issue templates for Copilot feedback/issues

### Phase 2: Infrastructure (Week 2)

- [ ] Enable Copilot in Enterprise settings
- [ ] Configure auto-seat assignment or manual assignment workflow
- [ ] Set seat limits based on headcount + growth projection
- [ ] Grant organizations access to Copilot

### Phase 3: Observability (Week 3)

- [ ] **Enable usage metrics policy** (most important step)
- [ ] Configure daily metrics reports
- [ ] Set up alerts for unusual usage patterns
- [ ] Document baseline metrics (adoption rate, usage by team)

### Phase 4: Security (Week 4)

- [ ] Enable secret scanning for Copilot-generated code
- [ ] Review public code matching policy
- [ ] Document approved Copilot models (if restricting by model)
- [ ] Create data classification policy (public vs. confidential code)

### Phase 5: Optimization (Month 2+)

- [ ] Review monthly usage metrics
- [ ] Optimize seat allocation (adjust limits, add/remove org access)
- [ ] Publish ROI report (productivity gains, cost per user)
- [ ] Gather feedback from users
- [ ] Plan for LLM model updates (new Claude/GPT versions)

## Troubleshooting

**"Usage metrics API returns 404"**

**Cause:** Using the old `GET /orgs/{org}/copilot/metrics` endpoint, which was **sunset 2026-04-02**.

**Solution:** Switch to the new reports API:

```bash
curl -H "Authorization: token $GH_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/{org}/copilot/metrics/reports/organization-28-day/latest"

# Should return 200 with { "download_links": [...] }
```

If you still get 404, ensure the enterprise admin has enabled the Copilot usage metrics policy.

### "User cannot see Copilot in their IDE"

**Cause:** User's org doesn't have Copilot enabled, or user's seat was not assigned.

**Solution:**

1. Check org has Copilot access: Enterprise → Settings → Policies → Copilot → Organization access
2. Check user has a seat: `GET /orgs/{org}/copilot/billing/seats?login={username}`
3. If not listed, assign seat via org settings or wait for auto-assignment

### "Excessive Copilot costs"

**Cause:** Too many seats allocated, or seats assigned to inactive users.

**Solution:**

1. Review seat usage: `GET /orgs/{org}/copilot/billing/seats`
2. Identify inactive users (no `last_activity_at` in past 30 days)
3. Revoke seats from inactive users
4. Adjust seat limit down
5. Monitor trends and adjust monthly

## Related Documentation

- [GitHub Copilot Billing API](https://docs.github.com/en/rest/copilot/copilot-billing)
- [GitHub Copilot Metrics API](https://docs.github.com/en/rest/copilot/copilot-metrics)
- [GitHub Enterprise Settings](https://docs.github.com/en/enterprise-cloud@latest/admin/policies/enforcing-policies-for-your-enterprise/about-enterprise-policies)
- [Tracking: GitHub API Premium Billing](../tracking/github-api-billing-notes.md)

## See Also

- `instructions/security-monitoring.instructions.md` — Monitoring security posture
- `instructions/governance.instructions.md` — Base Coat governance policies
- `instructions/observability.instructions.md` — Observability and metrics
