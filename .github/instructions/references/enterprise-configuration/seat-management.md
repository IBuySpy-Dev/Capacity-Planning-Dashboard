# Enterprise Configuration — Seat Management Reference

## Enable GitHub Copilot Licenses

### Via Web UI

1. Go to **Enterprise** → **Settings** → **Policies** → **Copilot**
2. Under **Access**, select **Enabled for all organizations** or configure per org
3. Set seat limit: **Billing** → **Copilot** → **Manage seat limit**

### Via API

```bash
# Get seat assignments and activity
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/orgs/{org}/copilot/billing/seats" \
  | jq '.seats[] | {login, last_activity_at, created_at}'
```

## Grant Organization Access

**Via Web UI:**

1. Enterprise → Settings → Policies → Copilot → Organization access
2. Enable for specific orgs or all orgs

**Auto-seat assignment:** Enable in org settings so users receive seats automatically
when they join the org or first use Copilot.

## Monitor Seat Usage

```bash
# Get billing data
curl -H "Authorization: token $GH_TOKEN" \
  "https://api.github.com/enterprises/{enterprise_slug}/settings/billing/usage"

# Returns: copilot_business_seats_used, seat_management_setting
```

## Optimize Seat Allocation

1. Review usage: `GET /orgs/{org}/copilot/billing/seats`
2. Identify inactive users (no `last_activity_at` in past 30 days)
3. Revoke seats from inactive users
4. Adjust seat limit down
5. Monitor trends monthly
