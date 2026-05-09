# GitHub Security Posture — Org-Level Checks

## Org-Level Checks

| # | Check | API Endpoint | Pass Condition | Risk if Failing |
|---|---|---|---|---|
| O1 | Code security configuration applied | `GET /orgs/{org}/code-security/configurations` | At least one configuration applied to repositories | Inconsistent security baseline across repos |
| O2 | Org rulesets defined | `GET /orgs/{org}/rulesets` | At least one active ruleset | Branch policies bypass risk |
| O3 | Secret scanning enabled at org level | Configuration → `secret_scanning: enabled` | Field is `enabled` | Secrets committed without detection |
| O4 | Dependabot security updates enabled | Configuration → `dependabot_security_updates: enabled` | Field is `enabled` | Vulnerable dependencies remain unpatched |

## API Quick Reference — Org Endpoints

```bash
# Verify active session and scopes
gh auth status

# Code security configs
gh api /orgs/{org}/code-security/configurations

# Org rulesets
gh api /orgs/{org}/rulesets
```

## Scoring Rubric

| Rating | Symbol | Criteria |
|---|---|---|
| Pass | 🟢 | Setting is enabled and fully configured as required |
| Warning | 🟡 | Partially configured, deprecated method used, or medium-severity open alerts |
| Fail | 🔴 | Setting disabled, absent, or critical/high open alerts present |

Overall posture score:

- **🟢 Green** — All checks are 🟢 Pass
- **🟡 Yellow** — No 🔴 Fail checks; one or more 🟡 Warning
- **🔴 Red** — One or more 🔴 Fail checks

## Token Requirements

Standard GitHub token scopes: `repo`, `read:org`. No admin token required.
