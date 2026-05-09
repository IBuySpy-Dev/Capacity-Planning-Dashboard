# Azure WAF Review — Pillar Guide & Workflow

## WAF Pillars

| Pillar | Key Concerns |
|---|---|
| **Reliability** | High availability, disaster recovery, fault tolerance, health probes, retry policies |
| **Security** | Zero trust, encryption at rest and in transit, managed identity, Key Vault, network segmentation |
| **Cost Optimization** | Right-sizing, reserved instances, spot/preemptible workloads, idle resource cleanup, cost alerts |
| **Operational Excellence** | Infrastructure as Code, monitoring, alerting, automated deployments, runbooks |
| **Performance Efficiency** | Auto-scaling, caching strategies, CDN, database indexing, connection pooling |

## Assessment Workflow

1. **Gather input** — Accept workload description, architecture diagrams, or IaC templates (Bicep, Terraform, ARM).
2. **Evaluate per pillar** — Assess the workload against each of the five WAF pillars.
3. **Score findings** — Assign a 1–5 score per pillar; flag individual findings with severity (Critical / High / Medium / Low).
4. **Prioritize** — Rank findings by a combined impact × effort matrix; surface quick wins first.
5. **Generate report** — Populate `waf-assessment-report-template.md` with findings, scores, and executive summary.
6. **Produce remediation templates** — Emit Bicep or Terraform snippets for each high/critical finding.
7. **Review and hand off** — Summarize open risks and recommended next steps.

## Templates in This Skill

| Template | Purpose |
|---|---|
| `waf-assessment-report-template.md` | Full WAF assessment report with per-pillar scores, findings table, and executive summary |
| `pillar-scoring-rubric.md` | Scoring rubric (1–5) for each WAF pillar with pass/fail criteria and evidence prompts |
| `remediation-action-plan-template.md` | Prioritized action plan with Bicep and Terraform remediation snippets |

## References

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [WAF Assessment Tool](https://learn.microsoft.com/assessments/azure-architecture-review/)
- [Reliability pillar](https://learn.microsoft.com/azure/well-architected/reliability/)
- [Security pillar](https://learn.microsoft.com/azure/well-architected/security/)
- [Cost Optimization pillar](https://learn.microsoft.com/azure/well-architected/cost-optimization/)
- [Operational Excellence pillar](https://learn.microsoft.com/azure/well-architected/operational-excellence/)
- [Performance Efficiency pillar](https://learn.microsoft.com/azure/well-architected/performance-efficiency/)
