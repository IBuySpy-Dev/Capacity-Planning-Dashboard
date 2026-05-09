# Technical Debt Remediation

Frameworks for budgeting, paying down, and governing technical debt.

## Debt Budget Framework

Allocate sprint capacity by team maturity:

| Maturity Level | Debt Allocation | Features | Maintenance |
|---|---|---|---|
| Early Stage (0–1 yr) | 5–10% | 80–85% | 5–10% |
| Growth (1–3 yr) | 15–20% | 70–75% | 5–10% |
| Stable (3+ yr) | 20–30% | 60–70% | 5–10% |

### Example Sprint Budget

```yaml
Sprint 12:
  Total Capacity: 80 SP
  Debt Bucket (20%): 16 SP
    - TD-001 (8 SP): Refactor auth
    - TD-002 (5 SP): Add tests
    - TD-004 (3 SP): Logger upgrade
  Feature Bucket (80%): 64 SP
```

## Amortization Tracking

Calculate net debt reduction each quarter:

```text
Q2 Review:
  Debt capacity: 5 sprints × 80 SP × 15% = 60 SP
  Debt completed: 62 SP  ✓ Exceeded target
  Debt added:     28 SP  (new items identified)
  Net reduction:  62 - 28 = 34 SP
```

Target: maintain quarterly amortization ≥ 30 SP. If debt backlog exceeds 6 months of
capacity, increase allocation and escalate to leadership.

## Governance Rules

### Debt Policies

- **No legacy code without tests** — pay down immediately.
- **No major version upgrades skipped** — security risk.
- **No new features on top of P1 debt** — causes instability.

### When to Pay Debt

- Dedicate 15–20% of sprint capacity.
- Prioritize by RICE score.
- Include debt in sprint planning (not left to end of sprint).

## Quarterly Review Checklist

- [ ] Calculate debt-paid-down vs. debt-added
- [ ] Verify debt budget was allocated and spent
- [ ] Review top 10 items by RICE score
- [ ] Identify items that shifted priority
- [ ] Adjust debt budget for next quarter
- [ ] Communicate debt status to leadership

## References

- [RICE Prioritization](https://www.reforge.com/RICE)
- Martin Fowler's Technical Debt Quadrant
- Related agent: `sprint-planner` (sprint scheduling)
