# Governance — Workflow Rules Reference

## Issue-First Mandate

Every change originates from an issue. If no issue exists, create one before touching code.
Issue fields required: title, description, acceptance criteria, labels.

## PR Workflow (Required Steps)

1. Create or confirm issue exists
2. Create branch: `<type>/<issue-number>-<short-description>`
3. Open PR referencing the issue
4. Wait for CI to pass
5. Request review or self-approve per repo policy
6. Merge via PR

Direct pushes to `main` are rejected by branch protection.

## Branch Naming

```text
<type>/<issue-number>-<short-description>
```

| Type | Use For |
|---|---|
| `feat` | New features, content, agents, skills |
| `fix` | Bug fixes, correctness corrections |
| `docs` | Documentation only |
| `chore` | Maintenance, dependencies, CI |
| `security` | Security-related changes |

## Commit Message Format

```text
<type>(<scope>): <short summary> (#<issue-number>)
```

- First line ≤ 72 characters
- Always reference the issue number
- Never include secrets, tokens, keys, passwords, or PII

## File Placement Rules

| Asset | Location |
|---|---|
| Agents | `agents/` |
| Skills | `skills/<skill-name>/` |
| Instructions | `instructions/` |
| Templates | `docs/templates/` |
| Governance docs | `docs/` and repo root |

## PR Description Template

```markdown
## Summary
<what changed and why>

## Validation
<how you verified this works>

## Issue Reference
closes #<issue-number>

## Risk
- Risk level: low | medium | high
- Rollback: <how to undo if needed>
```
