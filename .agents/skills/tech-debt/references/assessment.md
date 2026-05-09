# Technical Debt Assessment

Tools for inventorying, categorizing, and scoring technical debt.

## Debt Register Template

| ID | Category | Description | Effort (SP) | Impact (1-5) | RICE Score | Priority | Status | Sprint | Owner |
|----|----------|-------------|-------------|--------------|-----------|----------|--------|--------|-------|
| TD-001 | Legacy Code | Refactor auth microservice | 8 | 4 | 1.5 | P1 | Backlog | TBD | @alice |
| TD-002 | Test Gap | Add payment processor tests | 5 | 5 | 3.0 | P1 | In Progress | S12 | @bob |
| TD-003 | Dependency | Upgrade Express 4.x → 5.x | 3 | 2 | — | P3 | Backlog | TBD | @alice |

## Debt Categories

| Category | Examples | Typical Impact |
|----------|----------|---------------|
| Legacy Code | Unmaintained modules, old patterns | High |
| Test Gap | Missing unit/integration tests | Medium |
| Dependency | Outdated libraries, security patches | Medium-High |
| Tech Stack | Wrong tool for job, repeated patterns | Low-Medium |
| Documentation | Missing runbooks, stale guides | Low |
| Performance | Slow queries, N+1 problems | Medium-High |

## RICE Prioritization

**RICE Score = (Reach × Impact × Confidence) / Effort**

| Dimension | Scale |
|-----------|-------|
| Reach | 1 = <1% users … 4 = 50–100% users |
| Impact | 1 = cosmetic … 5 = critical blocker |
| Confidence | 0.5 = guess … 1.0 = data-backed |
| Effort | Story points (lower = higher RICE score) |

```text
TD-002: (3 × 5 × 1.0) / 5 = 3.0   ← Higher priority despite lower impact
TD-001: (4 × 4 × 0.75) / 8 = 1.5
```

## Visualization Templates

### Debt Quadrant (Impact vs. Effort)

Prioritize high-impact, low-effort items first (top-left quadrant).

### Debt Burndown

Track story points paid down vs. added each quarter. Target: net reduction ≥ 30 SP/quarter.

## When to Add Debt

- Only as a **conscious choice** (not an accident).
- Must be approved by tech lead.
- Must include remediation plan and target sprint for payoff.
