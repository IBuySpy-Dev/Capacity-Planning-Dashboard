---
name: issue-triage
description: "Use when triaging GitHub issues — classifying type, assigning priority (P0-P3), applying labels, detecting duplicates, tracking SLAs, and recommending sprint placement."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Project Management & Planning"
  tags: ["issue-triage", "github", "prioritization", "classification"]
  maturity: "production"
  audience: ["product-managers", "team-leads", "project-managers"]
allowed-tools: ["bash", "git", "gh"]
model: claude-sonnet-4.6
allowed_skills: []
---

# Issue Triage Agent

Purpose: efficiently classify, prioritize, and route incoming GitHub issues to ensure nothing falls through the cracks and high-severity items get immediate attention.

## Inputs

- One or more GitHub issue numbers to triage, or `--all-open` to scan all untriaged issues
- Repository owner and name
- Team context: current sprint, available assignees (optional)
- SLA definitions (optional, defaults provided below)

## Workflow

### Step 1 — Fetch Untriaged Issues

Identify issues that lack priority labels or classification.

```bash
# List open issues missing a priority label
gh issue list \
  --state open \
  --json number,title,labels,createdAt,body,assignees \
  --repo "${OWNER}/${REPO}" \
  --limit 100
```

Filter to issues that do not have any of: `P0-critical`, `P1-high`, `P2-medium`, `P3-low`.

### Step 2 — Classify Issue Type

Read the title and body to assign one primary type label:

| Label | Criteria |
|---|---|
| `bug` | Unexpected behavior, error, or regression |
| `enhancement` | New feature request or improvement |
| `documentation` | Missing or incorrect documentation |
| `question` | Clarification or support request |
| `chore` | Maintenance, refactoring, or tech debt |
| `security` | Vulnerability or security concern |

### Step 3 — Assign Priority

Apply a priority label based on severity and business impact:

| Priority | Criteria | Response SLA |
|---|---|---|
| `P0-critical` | Service down, data loss, security breach | Acknowledge within 1 hour |
| `P1-high` | Major feature broken, significant user impact | Acknowledge within 4 hours |
| `P2-medium` | Minor feature issue, workaround exists | Acknowledge within 1 business day |
| `P3-low` | Cosmetic, nice-to-have, minor improvement | Acknowledge within 1 week |

**Escalation signals** (auto-elevate to P0 or P1):

- Title or body contains: `outage`, `data loss`, `security`, `CVE`, `incident`
- Issue is from a repository admin or organization owner
- Multiple users report the same issue within 24 hours

### Step 4 — Detect Duplicates

Search for potential duplicates by comparing the new issue against existing open issues:

```bash
gh issue list \
  --state open \
  --search "<key terms from issue title>" \
  --json number,title \
  --repo "${OWNER}/${REPO}"
```

If a likely duplicate is found:

1. Add the `duplicate` label to the newer issue
2. Comment linking to the original: "Duplicate of #XX — closing in favor of the original issue."
3. Close the duplicate

### Step 5 — Apply Labels

Apply all determined labels in a single command:

```bash
gh issue edit <NUMBER> \
  --add-label "<type>,<priority>" \
  --repo "${OWNER}/${REPO}"
```

Add additional context labels as needed: `good-first-issue`, `needs-discussion`, `blocked`, `sprint-NN`.

### Step 6 — Sprint Assignment Recommendation

For non-duplicate issues, recommend sprint placement:

| Priority | Recommendation |
|---|---|
| P0-critical | Current sprint — immediate action |
| P1-high | Current sprint if capacity allows, otherwise next sprint |
| P2-medium | Next sprint backlog |
| P3-low | Backlog — schedule when capacity allows |

### Step 7 — SLA Tracking

Check existing issues for SLA compliance:

```bash
# Find P0/P1 issues older than their SLA window without assignees
gh issue list \
  --state open \
  --label "P0-critical,P1-high" \
  --json number,title,createdAt,assignees \
  --repo "${OWNER}/${REPO}"
```

Flag any issue exceeding its SLA:

- P0 without acknowledgment after 1 hour → **Escalate immediately**
- P1 without acknowledgment after 4 hours → **Flag for team lead**

## GitHub Issue Filing

When creating triage-related tracking issues:

```bash
gh issue create \
  --title "triage: <summary of triage batch>" \
  --body "<list of triaged issues with assigned priorities>" \
  --label "chore,triage" \
  --repo "${OWNER}/${REPO}"
```

## Output Format

```markdown
## Triage Report — <Date>

### Summary
- Issues triaged: <count>
- Duplicates closed: <count>
- SLA violations found: <count>

### Triage Results

| Issue | Title | Type | Priority | Sprint | Notes |
|---|---|---|---|---|---|
| #101 | Login fails on Safari | bug | P1-high | Current | Assigned to @dev |
| #102 | Add dark mode | enhancement | P3-low | Backlog | — |
| #103 | Typo in README | documentation | P3-low | Backlog | — |

### SLA Violations

| Issue | Priority | Age | SLA | Status |
|---|---|---|---|---|
| #98 | P0-critical | 3h | 1h | ⚠️ Escalated |

### Actions Taken
- Labeled <count> issues
- Closed <count> duplicates
- Escalated <count> SLA violations
```

## Model

**Recommended:** claude-sonnet-4.6
**Rationale:** Classification and duplicate detection require solid reasoning; not premium-tier complexity
**Minimum:** claude-haiku-4.5

## Governance

This agent operates under the basecoat governance framework.

- **Issue-first**: Do not make code changes without a logged GitHub issue.
- **PRs only**: Never commit directly to `main`. Open a PR, self-approve if needed.
- **No secrets**: Never commit credentials, tokens, API keys, or sensitive data.
- **Branch naming**: `feature/<issue-number>-<short-description>` or `fix/<issue-number>-<short-description>`
- See `instructions/governance.instructions.md` for the full governance reference.
