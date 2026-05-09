---
name: repo-health
description: Audit the operational health of a repository across six dimensions — CI stability, security posture, dependency hygiene, test coverage, governance completeness, and issue/PR hygiene. Produces a traffic-light scored report with prioritized remediation actions.
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Quality & Governance"
  tags: ["audit", "health", "ci", "security", "dependencies", "governance", "tech-debt"]
  maturity: "beta"
  audience: ["tech-leads", "platform-teams", "devops-engineers", "engineering-managers"]
allowed-tools: ["bash", "git", "grep", "gh", "npm", "python"]
---

# Repo Health Skill

## Overview

Runs a structured audit across six health dimensions and produces a scored Markdown report.
Each dimension is scored 🟢 GREEN / 🟡 YELLOW / 🔴 RED. The report ends with a prioritized
remediation list so the team knows exactly what to fix next.

**Developed using `ivegamsft/Capacity-Planning-Dashboard` as the pilot test case.**
The reference audit for that repo lives at `references/sample-audit-capdash.md`.

## When to Use

- Sprint kickoff: establish a health baseline before planning
- Pre-release gate: confirm the repo is production-ready
- Onboarding: quickly orient a new maintainer to the repo's state
- Quarterly review: track health trend over time

## Six Dimensions

| # | Dimension | What is checked |
|---|---|---|
| 1 | **CI Health** | Pass rate per workflow (last 30 runs), consecutive failures, stuck runs |
| 2 | **Security Posture** | Branch protection, secret scanning, push protection, Dependabot, secret alerts |
| 3 | **Dependency Hygiene** | `npm audit` / `pip-audit` / `dotnet list package --vulnerable`, outdated packages |
| 4 | **Test Coverage** | Test file count, coverage script presence, coverage report exists, CI enforces threshold |
| 5 | **Governance Completeness** | CODEOWNERS, PR template, issue templates, CHANGELOG, `.env.example`, `.gitignore` coverage |
| 6 | **Issue / PR Hygiene** | Open issues (labeled? stale?), open PRs (review lag, blocking CI?) |

## Scoring Rubric

### CI Health

| Signal | Score |
|---|---|
| All workflows ≥ 95% pass, no consecutive failures | 🟢 |
| One workflow 80–94% pass OR ≤2 consecutive failures | 🟡 |
| Any workflow < 80% pass OR ≥3 consecutive failures | 🔴 |

### Security Posture

| Signal | Score |
|---|---|
| Branch protection on, secret scanning on, 0 alerts | 🟢 |
| Secret scanning on but branch protection off OR 1–2 low/moderate alerts | 🟡 |
| Secret scanning off OR any high/critical alert OR push protection off | 🔴 |

### Dependency Hygiene

| Signal | Score |
|---|---|
| 0 vulnerabilities, all deps within 2 major versions | 🟢 |
| 1–3 low/moderate vulns OR 1–3 deps >2 major versions behind | 🟡 |
| Any high/critical vuln OR >3 deps significantly outdated | 🔴 |

### Test Coverage

| Signal | Score |
|---|---|
| Coverage script + CI threshold + coverage report all present | 🟢 |
| Test files exist but no coverage reporting | 🟡 |
| No test files OR test script missing from package.json | 🔴 |

### Governance Completeness

| Signal | Score |
|---|---|
| CODEOWNERS + PR template + issue templates + CHANGELOG + .env.example all present | 🟢 |
| 2–3 items missing | 🟡 |
| 4+ items missing OR CODEOWNERS missing | 🔴 |

### Issue / PR Hygiene

| Signal | Score |
|---|---|
| 0 open issues, 0 open PRs (or all labeled and active) | 🟢 |
| <5 open issues, <3 open PRs, none stale >14d | 🟡 |
| ≥5 unlabeled issues OR ≥3 open PRs stale >14d | 🔴 |

## Data Collection Commands

Run these to gather the raw data. Adapt package manager commands to the project's stack.

### CI Health

```bash
# Last 30 runs — pass rate per workflow
gh run list --repo OWNER/REPO --limit 30 --json name,conclusion,createdAt \
  | jq 'group_by(.name) | map({
      workflow: .[0].name,
      total: length,
      success: map(select(.conclusion=="success")) | length,
      failure: map(select(.conclusion=="failure" or .conclusion=="timed_out")) | length
    })'
```

### Security Posture

```bash
# Branch protection
gh api repos/OWNER/REPO/branches/main \
  --jq '{protected, required_reviews: .protection.required_pull_request_reviews.required_approving_review_count}'

# Secret scanning and Dependabot
gh api repos/OWNER/REPO --jq '.security_and_analysis'

# Open Dependabot alerts
gh api repos/OWNER/REPO/dependabot/alerts --jq 'group_by(.security_advisory.severity) | map({severity: .[0].security_advisory.severity, count: length})'

# Open secret scanning alerts
gh api repos/OWNER/REPO/secret-scanning/alerts --jq 'length'
```

### Dependency Hygiene

```bash
# Node.js
npm audit --json
npm outdated

# Python
pip-audit --format json

# .NET
dotnet list package --vulnerable
dotnet list package --outdated
```

### Test Coverage

```bash
# Node.js: check for test script and coverage
cat package.json | jq '{test: .scripts.test, coverage: .scripts.coverage}'
# Count test files
find . -name "*.test.*" -o -name "*.spec.*" | grep -v node_modules | wc -l
# Check if coverage output exists
ls coverage/ 2>/dev/null && echo "coverage dir exists" || echo "no coverage dir"
```

### Governance

```bash
# Check governance files
for f in CODEOWNERS .github/CODEOWNERS .github/pull_request_template.md \
          .github/ISSUE_TEMPLATE CHANGELOG.md .env.example; do
  [ -e "$f" ] && echo "✅ $f" || echo "❌ $f MISSING"
done

# Check .gitignore for minimum entries
for e in .env .env.local node_modules; do
  grep -q "$e" .gitignore && echo "✅ .gitignore: $e" || echo "❌ .gitignore missing: $e"
done
```

### Issue / PR Hygiene

```bash
# Open issues
gh issue list --repo OWNER/REPO --state open --limit 50 \
  --json number,title,labels,updatedAt

# Open PRs
gh pr list --repo OWNER/REPO --state open --limit 20 \
  --json number,title,reviewDecision,updatedAt,labels
```

## How to Invoke

> Run the repo-health audit on OWNER/REPO. Collect data across all six dimensions using the
> commands in the skill. Score each dimension with the traffic-light rubric. Output the report
> using the template at references/report-template.md. End with a prioritized remediation list.

## Report Template

See `references/report-template.md` for the scored output format.

## Sample Audit

See `references/sample-audit-capdash.md` for the pilot audit run against
`IBuySpy-Dev/Capacity-Planning-Dashboard` (May 2026).

## Limitations

- Branch protection API returns limited data without admin scope — some fields may be null
- `npm outdated` exit code 1 when deps are outdated; parse stdout, not exit code
- Coverage percentage requires running tests with `--coverage` flag; the audit checks for
  the *presence* of coverage infrastructure, not the actual percentage
- Secret scanning API requires the repo to have secret scanning enabled and the caller to have
  appropriate scope (`security_events` or `repo`)
