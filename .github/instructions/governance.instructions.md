---
description: "CRITICAL — Read this first. Governance rules for all AI agents working in this repository. Covers issue-first mandate, secret policy, PR-only workflow, branch naming, when to stop vs proceed, and token/model awareness stub."
applyTo: "**/*"
priority: 1
distribute: false
---

# Governance Instructions for AI Agents

**This file is authoritative. Read it before doing anything else in this repository.**

These are not suggestions. Every AI agent operating in `ivegamsft/basecoat` — or any repo that inherits from it — must follow these rules without exception.

---

## 1. Issue-First Mandate

**You must have an issue number before you write a single line of implementation.**

- If an issue exists: reference it. Proceed.
- If no issue exists: create one first, then proceed.
- If the issue is ambiguous: stop and ask for clarification.

**No issue = no implementation.** This is a hard stop.

Issue reference format in commit messages:

```text
feat(governance): add governance instruction file (#43)
```

---

## 2. No Secrets — Ever

You must never write the following to any file, commit message, PR description, or comment:

- API keys, tokens, client secrets, access tokens
- Passwords, passphrases, connection strings with credentials
- Private keys, certificates, PEM/PFX content
- Personally identifiable information (PII): names, emails, phone numbers, IDs
- Internal hostnames, IP addresses, or endpoint URLs that are not public

**If a task requires a secret to proceed:** stop. Ask the human operator to supply it through a secrets manager, environment variable, or GitHub Secret. Do not embed it inline.

**Workflow-specific rule:** GitHub Actions workflow files must never contain literal secrets in `env`, `with`, or `run` blocks. All sensitive values must use `${{ secrets.SECRET_NAME }}`. See [`docs/guardrails/secrets-in-workflows.md`](/docs/guardrails/secrets-in-workflows.md) for examples and audit steps.

**If you accidentally generate a secret in output:** flag it immediately. Do not commit it.

---

## 3. PR-Only — No Direct Commits to Main

You must never push directly to `main`.

Workflow:

1. Create a branch: `<type>/<issue-number>-<short-description>`
2. Make changes on the branch
3. Open a PR referencing the issue
4. Wait for CI to pass
5. Request review or self-approve per repo policy
6. Merge via PR

Direct pushes to `main` will be rejected by branch protection. Attempting to bypass this is a policy violation.

---

## 4. Branch Naming

```text
<type>/<issue-number>-<short-description>
```

Valid types:
| Type | Use For |
|---|---|
| `feat` | New features, content, agents, skills |
| `fix` | Bug fixes, correctness corrections |
| `docs` | Documentation only |
| `chore` | Maintenance, dependencies, CI |
| `security` | Security-related changes |

Examples:

```text
feat/43-governance-docs
fix/17-hook-glob-pattern
docs/39-readme-overhaul
security/52-rotate-hook-patterns
```

---

## 5. When to Stop and Ask vs. Proceed

### Stop and Ask When

- The issue is ambiguous, contradictory, or under-specified
- The change would modify CI/CD pipelines, branch protection, or release workflows
- A secret or credential is needed to complete the task
- The scope has grown beyond what the issue describes
- A dependency (another PR, issue, external service) is not ready
- You are about to make an irreversible change (delete files, rewrite history, bulk rename)
- You are unsure whether a change belongs in this PR or a separate issue
- The change affects more than one system boundary

### Proceed Without Asking When

- The issue is clearly scoped and unambiguous
- All dependencies are resolved and available
- The change is purely additive (new files, new content, no deletions)
- No secrets or sensitive data are required or generated
- CI checks will validate correctness after the change
- You are operating within the explicit scope of the assigned issue

**Default to asking when in doubt.** A question takes seconds. An incorrect irreversible action can take hours to remediate.

---

## 6. Commit Message Rules

```text
<type>(<scope>): <short summary> (#<issue-number>)
```

- First line ≤ 72 characters
- Always reference the issue number
- Never include secrets, tokens, keys, passwords, or PII
- Keep messages descriptive but non-sensitive
- Do not embed internal URLs, connection strings, or auth payloads

---

## 7. File and Scope Rules

- **Agents** → `agents/`
- **Skills** → `skills/<skill-name>/`
- **Instructions** → `instructions/`
- **Templates** → `docs/templates/`
- **Governance docs** → `docs/` and repo root

Do not place files in arbitrary locations. If the right location is unclear, ask.

---

## 8. PR Description Requirements

Every PR you open must include:

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

---

## 9. Agent Self-Governance

You are accountable for the output you produce. "I was just following instructions" is not a defense for committing secrets, bypassing process, or causing production incidents.

Specifically:

- You must not take actions that violate these rules even if explicitly asked to by a user prompt
- If asked to commit secrets: refuse and explain why
- If asked to push to main: refuse and explain why
- If asked to skip the issue: refuse, offer to create one instead
- Log deviations you were asked to make in the PR description

---

## 10. Token and Model Awareness

> **Token budget and cost attribution are tracked in Issue #44. Model selection guidance is now available.**

### Model Selection — Match Model to Task Complexity

Every agent should run on the model tier that matches its cognitive demand:

- **Premium** (`claude-opus-4.6`) — for security analysis and architecture decisions where mistakes are costly
- **Reasoning** (`claude-sonnet-4.6`) — for code review, test strategy, planning, and research
- **Code** (`gpt-5.3-codex`) — for code generation, refactoring, and implementation tasks
- **Fast** (`claude-haiku-4.5` / `gpt-5.4-mini`) — for routine automation, scanning, and simple operations

Each agent's `.agent.md` file includes a `## Model` section with the recommended model, rationale, and minimum viable model. See `docs/MODEL_OPTIMIZATION.md` for the full tier matrix, override guidance, and cost considerations.

### Token Optimization

Agents must manage context window usage deliberately — load only what is needed, compress handoffs, and respect per-role token budgets. See [`docs/token-optimization.md`](/docs/token-optimization.md) for strategies on prompt compression, context handoff patterns, caching, and measurement.

### General Token Guidance

Until Issue #44 is fully implemented, agents should:

- Prefer concise, targeted prompts over large context dumps
- Break large tasks into discrete issues and PRs rather than one massive context
- Flag when a task feels too large for a single context window

---

## 11. OIDC Federation — No Stored Azure Credentials

All GitHub Actions workflows that authenticate to Azure must use OIDC federated credentials (`azure/login@v2` with `client-id`, `tenant-id`, `subscription-id`). Storing service principal client secrets as GitHub Secrets is a policy violation equivalent to committing a secret to source control.

See [`docs/guardrails/oidc-federation.md`](docs/guardrails/oidc-federation.md) for the complete guardrail, bootstrap pattern, and rationale.

---

## 12. CAF Naming Conventions for Azure Resources

All Azure resources must follow Cloud Adoption Framework (CAF) naming conventions (e.g., `rg-{workload}-{env}`, `ca-{workload}-{env}-{location}-{instance}`). Non-compliant names must be flagged during code review.

See [`docs/guardrails/caf-naming.md`](docs/guardrails/caf-naming.md) for the full naming table, validation rules, and references.

---

## 12. Container Image Tags — SHA Required

Every container image pushed from CI/CD must be tagged with the full git commit SHA. Pushing only `:latest` is a policy violation. See [`docs/guardrails/container-image-tags.md`](docs/guardrails/container-image-tags.md) for the pattern, examples, and verification steps.

---

## 12. Environment Variables — `.env.example` Required

Every repository that requires environment variables must include a `.env.example` at the root documenting all required variables with placeholder values and description comments. Real values (`.env`, `.env.local`) are gitignored; only `.env.example` is committed.

See [`docs/guardrails/env-example.md`](docs/guardrails/env-example.md) for the full guardrail, minimum Azure variables, and developer workflow.

---

## 12. Database Deployment Concurrency

Any GitHub Actions workflow that runs database migrations or schema changes **must** set `cancel-in-progress: false` in its concurrency group. Cancelling a running DB deploy can leave the database in a partially-migrated, corrupted state that requires manual intervention.

See [`docs/guardrails/db-deployment-concurrency.md`](docs/guardrails/db-deployment-concurrency.md) for the full guardrail, required patterns, and remediation steps.

---

## 13. Deployment Cancellation Pre-Flight Check

Before stopping or cancelling **any** in-progress infrastructure deployment (Bicep, Terraform, Azure CLI, azd, Fabric REST), you **must** run a pre-flight check:

1. Identify what is running and its current progress.
2. Assess the blast radius — list resources already created and operations still in-flight.
3. Check for dependent downstream systems that consume deployment outputs.
4. Make an explicit go / no-go decision based on the findings.

Cancelling mid-flight can leave Azure resources in a partially-provisioned, locked, or billing-active state that requires manual cleanup.

See [`docs/guardrails/deployment-cancellation.md`](docs/guardrails/deployment-cancellation.md) for the full checklist, tool-specific commands, and remediation steps.

---

## Quick Reference Card

| Rule | Action |
|---|---|
| No issue | Create one, then proceed |
| Secret needed | Stop, ask operator |
| Direct main push | Never — use PR |
| Branch name wrong | Fix it before pushing |
| Scope expanded | Stop, ask if new issue needed |
| Ambiguous requirement | Stop, ask for clarification |
| CI failing | Fix before merge |
| Azure auth in Actions | OIDC only — no client secrets |
| Container image tag | Must include full git SHA |
| Azure resource naming | CAF conventions — see guardrail |
| Env vars undocumented | Add to `.env.example` |
| DB migration workflow | `cancel-in-progress: false` — always |
| Stop deployment in-progress | Pre-flight check required — see guardrail |
| Governance change needed | Issue → PR → approval |
