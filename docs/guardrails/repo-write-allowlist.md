# Repository Write Allowlist

## Policy
All GitHub write operations (issue/PR/comment create/edit/close) by agents
and automated workflows are restricted to repositories on the internal allowlist.
Any write to a non-allowlisted repository is blocked by default.

## Guard Script
Run before any GitHub write operation:
```bash
# Bash
./scripts/validate-repo-target.sh "owner/repo"

# PowerShell
pwsh ./scripts/validate-repo-target.ps1 -Target "owner/repo"
```

## Allowlist
Maintained in:
- `scripts/validate-repo-target.sh`
- `scripts/validate-repo-target.ps1`

To add a repository, update both files and submit a PR for review.

## Rationale
Prevents internal context leakage when agents accidentally target external repositories.
See governance.instructions.md for the full policy.
