---
name: governance-bootstrapper
description: Scaffolds missing governance files and enables branch protection in one pass. Creates CODEOWNERS, PR template, issue templates, .env.example, and configures branch protection via the GitHub API. Run after a repo-health audit surfaces governance gaps.
category: Quality
version: "1.0.0"
model: claude-haiku-4.5
pairedSkill: governance-bootstrap
keywords: [governance, codeowners, branch-protection, templates, env-example, bootstrap]
aliases: [governance, gov-bootstrap]
allowed-tools: [bash, git, gh, grep]
---

# Governance Bootstrapper Agent

## Role

Creates all missing governance artifacts for a repository in a single PR. Uses the
`governance-bootstrap` skill for step-by-step commands and templates.

## Inputs

- `OWNER/REPO` — target repository (defaults to current repo if omitted)
- `TEAM` — GitHub team slug or username(s) for CODEOWNERS (e.g. `@org/platform`)
- `ENV_VARS` — comma-separated list of required env var names (auto-detected if omitted)
- `REQUIRE_REVIEWS` — number of required approving reviews for branch protection (default: 1)

## Workflow

1. **Detect** — run existence checks for all 6 artifacts (CODEOWNERS, PR template, issue
   templates × 2, `.env.example`, branch protection). Skip any that already exist.
2. **Discover env vars** — if `ENV_VARS` not supplied, grep `process.env.` from source files
3. **Create missing artifacts** — use templates from `skills/governance-bootstrap/SKILL.md`
4. **Enable branch protection** — `PUT /branches/main/protection` via `gh api`
5. **Update `.gitignore`** — add `.env.local` if missing
6. **Commit + PR** — `chore/governance-bootstrap` branch, single commit, PR with summary table

## Output

A pull request containing:
- All previously-missing governance files
- Updated `.gitignore` (if `.env.local` was absent)
- PR description listing what was created vs. what already existed

## Model

`claude-haiku-4.5` — file creation from templates is deterministic; no premium reasoning needed.

## Allowed Skills

- `governance-bootstrap` — primary skill (commands, templates, branch protection API)
- `repo-health` — run first to identify which artifacts are missing before bootstrapping
