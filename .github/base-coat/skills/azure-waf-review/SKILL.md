---

name: azure-waf-review
description: "Use when performing an Azure Well-Architected Framework (WAF) assessment against a workload, IaC templates, or architecture description. Covers all five pillars: Reliability, Security, Cost Optimization, Operational Excellence, and Performance Efficiency. Produces scored assessments, prioritized findings, and Bicep/Terraform remediation snippets."
context: fork
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure Well-Architected Framework Review Skill

Assess Azure workloads against the five WAF pillars, generate scored findings reports, and
produce prioritized remediation guidance with Bicep/Terraform templates.

## When to Use

- Evaluating a workload description, architecture diagram, or IaC templates against WAF pillars
- Generating a structured WAF assessment report with per-pillar scores
- Prioritizing architectural improvements by impact and implementation effort
- Producing Bicep or Terraform remediation snippets for identified gaps
- Conducting a pre-production architecture review for Azure-hosted workloads

## How to Invoke

> Use the azure-waf-review skill. Accept the IaC templates below, assess them against all five
> WAF pillars, score each pillar, and produce a remediation action plan with Bicep snippets.

## Reference Files

| File | Contents |
|------|----------|
| [`references/pillar-guide.md`](references/pillar-guide.md) | Five WAF pillars with key concerns, full 7-step assessment workflow, template index, all references |
| [`references/workflow-guardrails.md`](references/workflow-guardrails.md) | Guardrails for scope, secrets, and advisory use; agent pairing guidance |

## Key Patterns

- Score each pillar 1–5; flag findings Critical / High / Medium / Low
- Rank by impact × effort matrix — surface quick wins first
- Never emit secrets or credentials in generated IaC
- Pair with `solution-architect` (full assessment) and `devops-engineer` (IaC remediation)
