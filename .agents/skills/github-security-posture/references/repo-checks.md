# GitHub Security Posture — Repo-Level Checks

## Repo-Level Checks

| # | Check | API Endpoint | Pass Condition | Risk if Failing |
|---|---|---|---|---|
| R1 | Branch protection on default branch | `GET /repos/{owner}/{repo}/branches/{branch}/protection` | Rule exists with PR reviews and status checks | Direct pushes, force pushes, no approval gate |
| R2 | Repo ruleset active | `GET /repos/{owner}/{repo}/rulesets` | At least one active ruleset | Policy bypass via ruleset gaps |
| R3 | Secret scanning enabled | `GET /repos/{owner}/{repo}` → `security_and_analysis.secret_scanning.status` | `enabled` | Committed secrets undetected |
| R4 | Push protection enabled | `GET /repos/{owner}/{repo}` → `security_and_analysis.secret_scanning_push_protection.status` | `enabled` | Secrets pushed before detection |
| R5 | Code scanning configured | `GET /repos/{owner}/{repo}/code-scanning/alerts` | No 404 (tool configured); zero open critical/high alerts | Undetected code vulnerabilities |
| R6 | Dependabot alerts triaged | `GET /repos/{owner}/{repo}/dependabot/alerts?state=open&severity=critical,high` | Zero open critical or high alerts | Exploitable vulnerable dependencies |
| R7 | Signed commits required | Branch protection `required_signatures.enabled` | `true` | Commit author spoofing risk |
| R8 | CODEOWNERS file present | `CODEOWNERS`, `.github/CODEOWNERS`, or `docs/CODEOWNERS` exists | File found | Unowned code with no review ownership |

## API Quick Reference — Repo Endpoints

```bash
DEFAULT=$(gh api /repos/{owner}/{repo} --jq '.default_branch')

gh api /repos/{owner}/{repo}/branches/$DEFAULT/protection
gh api /repos/{owner}/{repo}/rulesets
gh api /repos/{owner}/{repo} --jq '.security_and_analysis'

gh api "/repos/{owner}/{repo}/code-scanning/alerts?state=open&per_page=100"
gh api "/repos/{owner}/{repo}/dependabot/alerts?state=open&severity=critical,high&per_page=100"

gh api /repos/{owner}/{repo}/branches/$DEFAULT/protection/required_signatures

# CODEOWNERS presence check
gh api /repos/{owner}/{repo}/contents/.github/CODEOWNERS 2>/dev/null \
  || gh api /repos/{owner}/{repo}/contents/CODEOWNERS 2>/dev/null \
  || gh api /repos/{owner}/{repo}/contents/docs/CODEOWNERS 2>/dev/null
```
