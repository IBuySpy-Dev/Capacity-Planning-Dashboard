# Azure DevOps REST API — Artifacts, Extensions & Pitfalls

## Artifacts / Packages

| Operation | Method | Endpoint |
|-----------|--------|----------|
| List feeds | GET | `_apis/packaging/feeds` |
| List packages | GET | `_apis/packaging/feeds/{feedId}/packages` |
| Get package versions | GET | `_apis/packaging/feeds/{feedId}/packages/{packageId}/versions` |

## Service Hooks

Subscribe to ADO events and push notifications to external systems:

```bash
curl -X POST \
  "https://dev.azure.com/{org}/_apis/hooks/subscriptions?api-version=7.1" \
  -H "Authorization: Basic $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "publisherId": "tfs",
    "eventType": "build.complete",
    "consumerId": "webHooks",
    "consumerActionId": "httpRequest",
    "publisherInputs": { "projectId": "{project-id}" },
    "consumerInputs": { "url": "https://my-webhook.example.com" }
  }'
```

## Extension Development

Extensions use the VSS SDK to add custom UI, hubs, and actions to Azure DevOps.

```typescript
import * as SDK from "azure-devops-extension-sdk";

SDK.init().then(() => {
    SDK.register("my-contribution-id", {
        execute: async (actionContext) => {
            const workItemTrackingClient = await SDK.getService("ms.vss-work-web.work-item-form");
            // interact with work item
        }
    });
});
```

Key extension contribution types: `ms.vss-work-web.work-item-form-contribution`,
`ms.vss-web.hub`, `ms.vss-build-web.build-results-tab`.

## Common Pitfalls

| Pitfall | Detail |
|---------|--------|
| Wrong Content-Type on PATCH | Work item PATCH requires `Content-Type: application/json-patch+json` |
| URL-encoding spaces | Project names with spaces need `%20` encoding |
| Org vs collection URL | Services: `dev.azure.com/{org}`, Server: `{server}/{collection}` |
| WIQL limits | Max 20,000 work item IDs from WIQL — use `$top` + pagination |
| Batch limits | `workitemsbatch` accepts ≤ 200 IDs per request |
| Default api-version | Always specify `api-version` — default can change |

## Review Lens

- Is `api-version` specified on every request?
- Are PAT scopes the minimum required?
- Is pagination handled (continuation tokens checked)?
- Are 429 responses handled with proper backoff?
- Is `Content-Type: application/json-patch+json` used for PATCH operations?
- Are PATs stored in Key Vault or GitHub Secrets (never in source)?
