---
description: "Enterprise-level GitHub Copilot policy configuration, including usage metrics enablement, seat management, and security policies."
applyTo: "**/*"
distribute: false
---

# Enterprise Configuration and Policy Setup

Best practices for configuring GitHub Copilot at the enterprise level: policies, seat management, usage metrics, and security controls.

## Prerequisites

- **Enterprise owner** or **Enterprise security admin** role
- `admin:enterprise` + `admin:org` OAuth scopes for API access
- Access to Enterprise → Settings → Policies

## Seat Management (Summary)

1. Enterprise → Settings → Policies → Copilot → Enable Copilot for organizations
2. Set seat limit based on headcount + growth projection
3. Grant org access and configure auto-assign or manual assignment
4. Monitor monthly — revoke seats inactive > 30 days

See [`references/enterprise-configuration/seat-management.md`](references/enterprise-configuration/seat-management.md) for API commands.

## Usage Metrics (Summary)

Enable via: Enterprise → Settings → Policies → Copilot → Usage metrics → Enable.

> **Note:** The old `GET /orgs/{org}/copilot/metrics` endpoint was **sunset 2026-04-02**.
> Use the reports API: `GET /orgs/{org}/copilot/metrics/reports/organization-28-day/latest`

See [`references/enterprise-configuration/metrics-api.md`](references/enterprise-configuration/metrics-api.md) for full API reference and troubleshooting.

## Security Policies (Summary)

- **Code suggestions:** Enterprise → Policies → Copilot → Code suggestions (enable/disable/custom per org)
- **Public code matching:** Enterprise → Policies → Copilot → Public code matching (allow/disallow)
- **Secret scanning:** Enterprise → Security → Secret scanning → Enable for Copilot-generated code

## Setup Checklist

Five-phase rollout: Governance (Week 1) → Infrastructure (Week 2) → Observability (Week 3) → Security (Week 4) → Optimization (Month 2+).

See [`references/enterprise-configuration/security-and-checklist.md`](references/enterprise-configuration/security-and-checklist.md) for the full checklist and troubleshooting guide.

## References

| Topic | File |
|---|---|
| Seat assignment, grant access, monitor usage, revoke inactive | [`references/enterprise-configuration/seat-management.md`](references/enterprise-configuration/seat-management.md) |
| Enable metrics policy, API endpoints, NDJSON fields, common issues | [`references/enterprise-configuration/metrics-api.md`](references/enterprise-configuration/metrics-api.md) |
| Security policies, billing, 5-phase setup checklist, troubleshooting | [`references/enterprise-configuration/security-and-checklist.md`](references/enterprise-configuration/security-and-checklist.md) |

## See Also

- `instructions/security-monitoring.instructions.md` — Monitoring security posture
- `instructions/governance.instructions.md` — Base Coat governance policies
- `instructions/observability.instructions.md` — Observability and metrics
