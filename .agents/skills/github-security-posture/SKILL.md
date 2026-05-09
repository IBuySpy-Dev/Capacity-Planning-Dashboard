---

name: github-security-posture
description: "Audit GitHub org and repo security settings with traffic-light scoring and remediation guidance. Covers code security configs, rulesets, secret scanning, push protection, Dependabot alerts, branch protection, and CODEOWNERS."
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Uncategorized"
  tags: ["uncategorized"]
  maturity: "beta"
  audience: ["developers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# GitHub Security Posture Skill

Audit GitHub organization and repository security settings with traffic-light scoring and
remediation guidance. Covers org-level configs, rulesets, secret scanning, push protection,
Dependabot alerts, branch protection, and CODEOWNERS.

## When to Use

- Auditing GitHub org-level code security configurations
- Checking repository rulesets and branch protection rules
- Verifying secret scanning and push protection status
- Triaging open Dependabot or code scanning alerts
- Producing a traffic-light posture report for a security review
- Generating remediation commands for failing security checks

## How to Invoke

> Use the github-security-posture skill. Run all org-level and repo-level checks, score each
> finding with the traffic-light rubric, and produce the posture report.

## Reference Files

| File | Contents |
|------|----------|
| [`references/org-checks.md`](references/org-checks.md) | Org-level checks (O1–O4), org API quick reference, scoring rubric |
| [`references/repo-checks.md`](references/repo-checks.md) | Repo-level checks (R1–R8), repo API quick reference |

## Key Patterns

- Run `gh auth status` first — verify `repo` and `read:org` scopes are present
- Overall score: 🟢 all pass | 🟡 no fails, some warnings | 🔴 any fail
- Pair with `github-security-posture` agent (drives workflow) and `security-analyst` for deep analysis

## Templates

| Template | Purpose |
|---|---|
| `posture-report-template.md` | Traffic-light posture report with org checks, repo checks, scorecard, and remediation commands |
