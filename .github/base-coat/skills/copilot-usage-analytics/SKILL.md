---

name: copilot-usage-analytics
description: "Use when estimating per-session Copilot CLI cost, analyzing model-routing efficiency, tracking agent dispatch patterns, or documenting which GitHub Copilot usage APIs exist. Covers session cost estimation, model selection recommendations, and API landscape mapping."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Copilot Usage Analytics Skill

Estimate per-session Copilot CLI cost, analyze model-routing efficiency, track agent dispatch
patterns, and document which GitHub Copilot usage APIs exist.

## When to Use

- Estimating cost for a completed or in-progress Copilot CLI session
- Analyzing which sub-agent dispatches are driving the most token consumption
- Choosing the right model tier for a task to minimize cost without sacrificing quality
- Auditing agent workflows for routing inefficiencies
- Generating an ROI report (issues resolved versus estimated spend)
- Documenting which Copilot usage APIs are available versus missing

## How to Invoke

> Use the copilot-usage-analytics skill. Apply the session cost estimate template and the
> model-routing recommendation template to the current session's dispatch log.

## Reference Files

| File | Contents |
|------|----------|
| [`references/api-landscape-detail.md`](references/api-landscape-detail.md) | Full API source table (metrics/billing/Power BI), response format, model routing guidance table |
| [`references/cost-estimation-guide.md`](references/cost-estimation-guide.md) | 6-step estimation workflow, guardrails, agent pairing |

## Templates in This Skill

| Template | Purpose |
|---|---|
| `templates/session-cost-estimate-template.md` | Per-session cost breakdown by dispatch, model, and estimated token usage |
| `templates/model-routing-recommendation-template.md` | Structured recommendations for right-sizing model selection per task type |
| `templates/api-landscape.md` | Reference map of GitHub Copilot usage APIs — what exists, what is missing, and current workarounds |

## Key Patterns

- **Metrics API**: `GET /orgs/{org}/copilot/metrics/reports/organization-28-day/latest` — returns NDJSON; requires `admin:org` or `read:org`
- **Self-track costs**: GitHub does not expose per-session cost data; use the estimation workflow
- **ROI**: always include issues resolved alongside cost — cost alone is not actionable
