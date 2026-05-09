---
name: azure-devops-rest
description: "Azure DevOps REST API patterns — authentication, scopes, pagination, throttling, and endpoint taxonomy for work items, pipelines, repos, and artifacts."
context: fork
compatibility: ["VS Code", "Cursor", "Windsurf", "Claude Code"]
metadata:
  category: "Developer Tools"
  tags: ["azure-devops", "rest-api", "pipelines", "work-items", "automation"]
  maturity: "production"
  audience: ["developers", "devops-engineers"]
allowed-tools: ["bash", "git", "grep", "find"]
---

# Azure DevOps REST API Skill

Patterns for building integrations, scripts, and agents that interact with Azure DevOps
Services or Server via the REST API.

## Reference Files

| File | Contents |
|------|----------|
| [`references/pipelines.md`](references/pipelines.md) | Auth (PAT + OIDC), API versioning, pagination (continuation tokens), throttling, work items, repos, pipelines endpoints |
| [`references/extensions.md`](references/extensions.md) | Artifacts/packages, service hooks, extension development, common pitfalls, review lens |

## Auth Quick Reference

| Method | When to Use |
|--------|------------|
| PAT (Basic auth) | Scripts, local development |
| Managed Identity / `System.AccessToken` | Azure Pipelines, Azure-hosted automation |

Always specify `api-version=7.1`. PATs: expiry ≤ 90 days, stored in Key Vault.

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Wrong Content-Type on PATCH | Use `application/json-patch+json` |
| Missing `api-version` | Always include `?api-version=7.1` |
| Not handling 429 | Check `Retry-After` header; exponential backoff |
| No pagination | Always check `x-ms-continuationtoken` |

## Key Limits

- WIQL: max 20,000 work item IDs
- Batch get: max 200 IDs per request
- Default page size: ~200 items (use `$top` to control)
