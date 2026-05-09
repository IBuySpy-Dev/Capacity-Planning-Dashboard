# GitHub Repository Secrets Setup

This document describes every secret that must be configured in repository
settings for Base Coat's GitHub Actions workflows to run correctly.

Navigate to: **Settings → Secrets and variables → Actions → New repository secret**

---

## Required Secrets

### `COPILOT_GITHUB_TOKEN`

**Used by:** `issue-triage.lock.yml`, `code-review-agent.lock.yml`,
`security-analyst.lock.yml`, `retro-facilitator.lock.yml`,
`self-healing-ci.lock.yml`, `release-impact-advisor.lock.yml`

**Purpose:** Authenticates the GitHub Agentic Workflow (gh-aw) agent containers.
Without this secret the agentic lock-file workflows will fail to start.

**How to create:**

1. Go to <https://github.com/settings/tokens> (your personal account)
2. Click **Generate new token (classic)**
3. Name it `basecoat-copilot-agent`
4. Set expiration to **90 days** (rotate on expiry)
5. Select scopes:
   - `repo` (full control of private repositories)
   - `workflow`
   - `read:org`
6. Click **Generate token** and copy the value immediately
7. In the repository: **Settings → Secrets and variables → Actions**
8. Click **New repository secret**, name it `COPILOT_GITHUB_TOKEN`, paste value

**Rotation schedule:** Rotate every 90 days. Set a calendar reminder.
When rotating, generate a new token *before* the old one expires, update
the secret, then revoke the old token.

---

### `GH_AW_GITHUB_TOKEN`

**Used by:** All `*.lock.yml` agentic workflow files

**Purpose:** Grants the agentic workflow read access to repository contents
during agent execution (separate from `COPILOT_GITHUB_TOKEN` for least-privilege
isolation).

**How to create:** Same steps as `COPILOT_GITHUB_TOKEN` above, but select
only `repo:read` scope. Name the token `basecoat-gh-aw`.

---

### `GH_AW_GITHUB_MCP_SERVER_TOKEN`

**Used by:** `issue-triage.lock.yml`, `code-review-agent.lock.yml`

**Purpose:** Authenticates the GitHub MCP server sidecar used by the gh-aw
agent to call GitHub APIs from within the agent container.

**How to create:** A fine-grained PAT scoped to this repository with:

- **Repository permissions:** Issues (read/write), Pull requests (read/write),
  Contents (read)
- Name it `basecoat-mcp-server`

---

### `STAGING_API_TOKEN`

**Used by:** `performance-baseline-pr-check.yml`

**Purpose:** API token for the staging deployment used by k6 performance tests.

**Note:** This workflow is a pre-existing non-blocking failure when the staging
deployment is not provisioned. CI will report it as failing on every PR; this
does not block merges since branch protection is not enforced on `main`.

---

## Optional Secrets

### `SLACK_WEBHOOK_URL`

**Used by:** Release notification step (if added in future)

Not currently wired up. Reserve the name if Slack integration is planned.

---

## Validating Secrets

After setting all secrets, trigger a manual workflow run to confirm:

```bash
gh workflow run issue-triage.yml --repo IBuySpy-Shared/basecoat
```

Check the Actions tab for green status on the `triage` job. If it fails with
`secret not found`, verify the secret name matches exactly (case-sensitive).

---

## See Also

- [Operational Runbook](OPERATIONAL_RUNBOOK.md)
- [Enterprise Security Hardening](ENTERPRISE_SECURITY_HARDENING.md)
- [GitHub Agentic Workflows docs](https://github.github.com/gh-aw/introduction/overview/)
