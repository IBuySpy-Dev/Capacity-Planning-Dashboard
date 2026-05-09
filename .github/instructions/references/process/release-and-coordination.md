# Release Process, Hotfix, and Cross-Team Coordination

## Versioning

Follow Semantic Versioning (`MAJOR.MINOR.PATCH`):

- **MAJOR** — breaking changes to public APIs or data contracts
- **MINOR** — new features, backward-compatible
- **PATCH** — bug fixes, backward-compatible

Pre-release: `1.2.0-rc.1` (hyphen suffix)

## Release Workflow

1. **Cut release branch** from `main`: `release/vX.Y.Z`
2. **Update CHANGELOG** — consolidate commits into sections: Added, Changed, Fixed, Removed, Security
3. **Run full test suite** — unit, integration, and end-to-end on the release branch
4. **Tag**: `git tag -a vX.Y.Z -m "Release vX.Y.Z"` → create GitHub Release with changelog body
5. **Deploy** via CI/CD pipeline triggered by the tag
6. **Verify production** — smoke tests and health checks pass
7. **Merge release branch back to `main`** if hotfixes were applied during the release

## Hotfix Process

1. Branch from the release tag: `fix/hotfix-<description>`
2. Apply the minimal fix, add tests, open a PR against `main`
3. Cherry-pick to the release branch if a patch release is needed
4. Follow the same release workflow for the patch version

## Cross-Team Coordination

### Shared Contracts

- API contracts (OpenAPI specs) and message schemas are the authoritative interface between teams.
- Contract changes require a PR reviewed by at least one representative from each consuming team.
- Breaking contract changes must be announced at least one sprint in advance with a migration guide.

### Dependency Management

- When your work depends on another team's deliverable, create a linked issue in their repository and reference it in your issue.
- Track cross-team dependencies on the sprint board with the `cross-team` label.
- Blocked cross-team items are raised in standup and escalated to team leads if unresolved within two business days.

### Communication Channels

| Channel | Use |
|---|---|
| GitHub Issue comments and PR reviews | Sprint-scoped decisions |
| Team chat channel (tag team lead) | Urgent coordination |
| ADR documents in the repository | Design and architecture discussions |

## Delivery Health Metrics

Track each sprint in the Retrospective:

| Metric | Target | Signal |
|---|---|---|
| Sprint velocity | Stable ± 15% from rolling average | Declining = overcommitment or blockers |
| Cycle time (open → merged) | ≤ 5 business days | Rising = review bottlenecks or scope creep |
| PR review turnaround | ≤ 1 business day | Slow = context-switch cost |
| Escaped defects (prod bugs) | ≤ 2 per sprint | Rising = testing/review gaps |
| Sprint goal completion | ≥ 80% of committed items | Miss = planning issues |
| Deployment frequency | ≥ 1 per week | Lower = release friction |
| Change failure rate | ≤ 10% cause rollback | Higher = insufficient staging |

- **Trends over single data points**: 3 consecutive bad sprints = pattern requiring process change.
- Never use velocity to compare teams — only for a single team's own forecasting.
