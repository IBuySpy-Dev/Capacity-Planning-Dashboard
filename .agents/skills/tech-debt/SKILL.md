---
name: tech-debt
description: Technical debt management frameworks, prioritization rubrics (RICE scoring), debt budgets, amortization tracking, and visualization templates
compatibility: "Works with VS Code, CLI, and Copilot Coding Agent. No external tools required."
metadata:
  category: "devex"
  keywords: "technical-debt, prioritization, RICE, budgeting, tracking, amortization"
  model-tier: "standard"
allowed-tools: "search/codebase"
---

# Technical Debt Management

Frameworks for inventorying, scoring, budgeting, and paying down technical debt across
engineering teams. Uses RICE scoring and sprint-based allocation.

## Reference Files

| File | Contents |
|------|----------|
| [`references/assessment.md`](references/assessment.md) | Debt register template, debt categories, RICE scoring rubric, visualization templates |
| [`references/remediation.md`](references/remediation.md) | Budget framework, amortization tracking, governance rules, quarterly review checklist |

## Core Concepts

- **Debt Register** — centralized register with ID, category, effort, impact, RICE score, status, and owner
- **RICE Score** = (Reach × Impact × Confidence) / Effort — higher score = higher priority
- **Budget allocation** — 5–30% of sprint capacity reserved for debt, scaled by team maturity
- **Amortization target** — net debt reduction ≥ 30 SP/quarter

## Key Rules

- Adding debt is a **conscious choice** — requires tech lead approval and remediation plan
- Never let debt backlog exceed 6 months of capacity
- No new features on top of P1 debt (causes instability)

## Related

- Agent: `sprint-planner` (for sprint scheduling)
- References: Martin Fowler's Technical Debt Quadrant, RICE framework
