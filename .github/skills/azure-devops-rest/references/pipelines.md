# Azure DevOps REST API — Pipelines & Core Patterns

## Authentication

### PAT (Personal Access Token)

```bash
TOKEN=$(echo -n ":$PAT" | base64)
curl -H "Authorization: Basic $TOKEN" \
  "https://dev.azure.com/{org}/{project}/_apis/pipelines?api-version=7.1"
```

```powershell
$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
}
Invoke-RestMethod -Uri "https://dev.azure.com/$Org/$Project/_apis/pipelines?api-version=7.1" -Headers $headers
```

### PAT Scopes (Least Privilege)

| Task | Scope |
|------|-------|
| Read work items | `vso.work` |
| Create/update work items | `vso.work_write` |
| Read pipelines | `vso.build` |
| Queue builds | `vso.build_execute` |
| Read repos/code | `vso.code` |
| Create pull requests | `vso.code_write` |
| Read artifacts | `vso.packaging` |

### Managed Identity / OIDC (CI/CD)

```yaml
steps:
  - script: |
      curl -H "Authorization: Bearer $(System.AccessToken)" \
        "https://dev.azure.com/$(System.CollectionUri)/_apis/projects?api-version=7.1"
```

PAT lifecycle: expiry ≤ 90 days, stored in Key Vault, revoke immediately on team member departure.

## API Versioning

Always include `api-version` on every request:

```
https://dev.azure.com/{org}/{project}/_apis/{area}?api-version=7.1
```

Preview features: `7.1-preview.1`. Never rely on default version.

## Pagination (Continuation Tokens)

```python
def get_all_work_items(org, project, query_id, headers):
    items = []
    url = f"https://dev.azure.com/{org}/{project}/_apis/wit/wiql/{query_id}?api-version=7.1"
    while url:
        resp = requests.get(url, headers=headers); resp.raise_for_status()
        items.extend(resp.json().get("workItems", []))
        token = resp.headers.get("x-ms-continuationtoken")
        url = f"{url}&continuationToken={token}" if token else None
    return items
```

Use `$top` to control page size. Always check `x-ms-continuationtoken`.

## Throttling (429 Handling)

```csharp
if (response.StatusCode == HttpStatusCode.TooManyRequests)
{
    var retryAfter = response.Headers.RetryAfter?.Delta ?? TimeSpan.FromSeconds(30);
    await Task.Delay(retryAfter);
    // retry
}
```

Monitor `X-RateLimit-Remaining` proactively. Batch operations where possible.

## Endpoint Taxonomy

### Pipelines / Builds

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List pipelines | GET | `_apis/pipelines` |
| Get pipeline run | GET | `_apis/pipelines/{id}/runs/{runId}` |
| Queue run | POST | `_apis/pipelines/{id}/runs` |
| List build definitions | GET | `_apis/build/definitions` |
| Get build logs | GET | `_apis/build/builds/{buildId}/logs` |

### Work Items

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Get work item | GET | `_apis/wit/workitems/{id}` |
| Create work item | POST | `_apis/wit/workitems/$Task` (PATCH body) |
| Update work item | PATCH | `_apis/wit/workitems/{id}` |
| Run WIQL query | POST | `_apis/wit/wiql` |
| Batch get (≤200) | POST | `_apis/wit/workitemsbatch` |

Work item create/update uses JSON Patch:

```json
[
  { "op": "add", "path": "/fields/System.Title", "value": "New task" },
  { "op": "add", "path": "/fields/System.State", "value": "Active" }
]
```

### Git / Repos

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List repos | GET | `_apis/git/repositories` |
| Create PR | POST | `_apis/git/repositories/{repoId}/pullrequests` |
| Get file | GET | `_apis/git/repositories/{repoId}/items?path=/file.txt` |
