---
name: governance-bootstrap
description: Scaffold missing governance files and enable branch protection in one pass. Creates CODEOWNERS, PR template, issue templates, .env.example, and configures branch protection rules via the GitHub API. Use after a repo-health audit surfaces governance gaps.
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Quality & Governance"
  tags: ["governance", "codeowners", "branch-protection", "templates", "bootstrap"]
  maturity: "beta"
  audience: ["tech-leads", "platform-teams", "engineering-managers"]
allowed-tools: ["bash", "git", "gh", "grep"]
---

# Governance Bootstrap Skill

## Overview

Creates the five governance artifacts that are most commonly missing from repos and enables
branch protection on `main` — all in a single pass. Designed to be run immediately after
a `repo-health` audit identifies governance gaps.

**Artifacts created:**

| Artifact | Path | Purpose |
|---|---|---|
| CODEOWNERS | `.github/CODEOWNERS` | Auto-assign reviewers on every PR |
| PR template | `.github/pull_request_template.md` | Enforce PR description structure |
| Bug report template | `.github/ISSUE_TEMPLATE/bug_report.md` | Structured bug reports |
| Feature request template | `.github/ISSUE_TEMPLATE/feature_request.md` | Structured feature requests |
| `.env.example` | `.env.example` | Document required environment variables |
| Branch protection | GitHub API | Require reviews, block direct pushes |

## When to Use

- After a `repo-health` audit returns 🟡/🔴 on Governance dimension
- When onboarding a new repo to team standards
- When CODEOWNERS is missing and reviewers must be manually assigned on every PR

## Inputs

- `OWNER/REPO` — target repository (defaults to current repo)
- `TEAM` — GitHub team slug or individual login(s) to assign as default reviewers in CODEOWNERS
- `ENV_VARS` — space-separated list of required environment variable names for `.env.example`
- `REQUIRE_REVIEWS` — number of required approving reviews (default: 1)

## Step-by-Step Workflow

### Step 1 — Detect existing artifacts

```bash
REPO="OWNER/REPO"

for f in .github/CODEOWNERS .github/pull_request_template.md \
          .github/ISSUE_TEMPLATE/bug_report.md \
          .github/ISSUE_TEMPLATE/feature_request.md \
          .env.example; do
  [ -e "$f" ] && echo "EXISTS: $f" || echo "MISSING: $f"
done

# Check branch protection
gh api repos/$REPO/branches/main --jq '{protected: .protected}'
```

Only create artifacts that are missing — never overwrite existing files.

### Step 2 — Create CODEOWNERS

```bash
mkdir -p .github
cat > .github/CODEOWNERS << 'EOF'
# Default reviewers for all files
* @TEAM_OR_USER

# Infra and CI changes require additional review
.github/workflows/ @TEAM_OR_USER
*.bicep @TEAM_OR_USER
*.tf @TEAM_OR_USER
EOF
```

Replace `TEAM_OR_USER` with `@org/team-slug` (for a team) or `@username` (for an individual).

### Step 3 — Create PR template

```bash
cat > .github/pull_request_template.md << 'EOF'
## Summary
<!-- What changed and why -->

## Type of change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactor
- [ ] Docs / chore

## Validation
<!-- How you verified this works: tests run, manual steps, screenshots -->

## Issue Reference
closes #

## Risk
- Risk level: low | medium | high
- Rollback: <!-- how to undo if needed -->
EOF
```

### Step 4 — Create issue templates

```bash
mkdir -p .github/ISSUE_TEMPLATE

cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug report
about: Something is broken
labels: bug
---

## Describe the bug
<!-- A clear description of what is wrong -->

## Steps to reproduce
1.
2.
3.

## Expected behavior
<!-- What should happen -->

## Actual behavior
<!-- What actually happens -->

## Environment
- OS:
- Browser / runtime version:
- Deployment environment (local / staging / prod):

## Logs / screenshots
<!-- Paste relevant logs or attach screenshots -->

## Reference ID
<!-- If available: correlation ID, trace ID, or error reference from the app -->
EOF

cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature request
about: Propose a new capability
labels: enhancement
---

## Problem statement
<!-- What problem does this solve? Who is affected? -->

## Proposed solution
<!-- Describe what you'd like to happen -->

## Alternatives considered
<!-- Other approaches you thought of -->

## Acceptance criteria
- [ ]
- [ ]
EOF
```

### Step 5 — Create `.env.example`

```bash
cat > .env.example << 'EOF'
# ── Required ──────────────────────────────────────────────────────────────────
# All variables below are required. Copy this file to .env.local and fill in
# values for your environment. Never commit .env.local or .env to source control.

# Azure AD / Entra ID
AZURE_TENANT_ID=<your-tenant-id>
AZURE_CLIENT_ID=<your-client-id>

# Database
DATABASE_SERVER=<sql-server-name>.database.windows.net
DATABASE_NAME=<database-name>
DATABASE_USER=<db-username>
DATABASE_PASSWORD=<db-password>

# Application
PORT=3000
NODE_ENV=development

# ── Optional ──────────────────────────────────────────────────────────────────
# SESSION_SECRET=<random-string-min-32-chars>
# APPINSIGHTS_INSTRUMENTATIONKEY=<key>
EOF
```

Populate with the actual variable names from the codebase:
```bash
# Auto-discover env var names from source
grep -rh 'process\.env\.' src/ --include="*.js" --include="*.ts" \
  | grep -oP 'process\.env\.\K[A-Z_]+' | sort -u
```

### Step 6 — Enable branch protection

```bash
REPO="OWNER/REPO"
REQUIRE_REVIEWS=1

gh api repos/$REPO/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["CI"]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews="{
    \"required_approving_review_count\": $REQUIRE_REVIEWS,
    \"dismiss_stale_reviews\": true
  }" \
  --field restrictions=null
```

**Notes:**
- `required_status_checks.contexts` must match the exact CI job names that appear in your repo's check suite. Use `gh pr checks <pr-number>` to find the exact names.
- `restrictions: null` means no push restriction beyond the review requirement.
- After enabling, verify: `gh api repos/$REPO/branches/main --jq '.protected'` → should return `true`.

### Step 7 — Add `.env.local` to `.gitignore`

```bash
grep -q '\.env\.local' .gitignore || echo '.env.local' >> .gitignore
grep -q '\.env$' .gitignore     || echo '.env' >> .gitignore
```

### Step 8 — Commit and PR

```bash
git checkout -b chore/governance-bootstrap
git add .github/CODEOWNERS .github/pull_request_template.md \
        .github/ISSUE_TEMPLATE/ .env.example .gitignore
git commit -m "chore(governance): bootstrap CODEOWNERS, templates, .env.example"
gh pr create --title "chore(governance): bootstrap governance files" \
  --body "Adds CODEOWNERS, PR template, issue templates, and .env.example.
Branch protection enabled separately via GitHub API.
Generated by governance-bootstrap skill."
```

## Verification

After running, confirm:

```bash
# All governance files present
for f in .github/CODEOWNERS .github/pull_request_template.md \
          .github/ISSUE_TEMPLATE/bug_report.md \
          .github/ISSUE_TEMPLATE/feature_request.md \
          .env.example; do
  [ -e "$f" ] && echo "✅ $f" || echo "❌ MISSING: $f"
done

# Branch protection active
gh api repos/OWNER/REPO/branches/main --jq '{
  protected: .protected,
  required_reviews: .protection.required_pull_request_reviews.required_approving_review_count
}'
```

Expected output: all ✅, `protected: true`, `required_reviews: 1`.

## Limitations

- Branch protection via `PUT /branches/main/protection` requires `admin` scope on the token.
  If the token lacks admin, apply protection manually: Settings → Branches → Add rule → `main`.
- `required_status_checks.contexts` must list existing check names. Pass an empty array `[]`
  to enable protection without status check requirements (less strict but functional).
- CODEOWNERS team slugs must use the full `@org/team` format, not just the team name.

## See Also

- `skills/repo-health/` — audit skill that identifies which of these are missing
- `docs/guardrails/env-example.md` — `.env.example` guardrail detail
- `docs/guardrails/secrets-in-workflows.md` — what to keep out of `.env.example`
