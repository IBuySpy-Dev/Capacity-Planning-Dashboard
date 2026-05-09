# Azure WAF Review — Guardrails & Agent Pairing

## Guardrails

- Scope assessments to Azure workloads only; do not apply WAF pillars to non-Azure targets.
- Do not emit secrets, connection strings, or credentials in any generated IaC snippet.
- Always cite the relevant WAF documentation URL for each finding.
- If the workload input is ambiguous, ask clarifying questions before scoring.
- Scores are advisory; always recommend a human architecture review for critical workloads.

## Agent Pairing

This skill is designed to be used alongside the `solution-architect` agent for full architecture
assessments. Pair with the `security-analyst` agent for deep-dive security pillar analysis, and
the `devops-engineer` agent for Operational Excellence remediation.

For IaC remediation, the `devops-engineer` agent can apply generated Bicep/Terraform snippets.
For cost workload analysis, pair with the `product-manager` agent to align optimization priorities
with business goals.
