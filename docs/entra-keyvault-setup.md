# Entra client secret Key Vault setup

Use this flow to stop passing `ENTRA_CLIENT_SECRET` as a raw GitHub secret during Bicep deployment.

## 1. Store the secret in Key Vault

```bash
az keyvault secret set --vault-name kv-capdash-prod-prod01 --name capdash-entra-client-secret --value <secret>
```

## 2. Set the GitHub repository variable

```bash
gh variable set ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI --body "https://kv-capdash-prod-prod01.vault.azure.net/secrets/capdash-entra-client-secret"
```

`bicep-deploy.yml` now passes this URI as `entraClientSecretKvUri`. When present, Bicep emits the App Service Key Vault reference without needing the raw secret value.

## 3. Deploy and verify

1. Run the next `bicep-deploy.yml` deployment.
2. Open the App Service configuration in Azure Portal.
3. Confirm `ENTRA_CLIENT_SECRET` is set to an `@Microsoft.KeyVault(...)` reference.
4. Confirm Entra sign-in still works after deployment.

## Fallback behavior

If `ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI` is empty, deployment still falls back to the existing `entraClientSecret`/`ENTRA_CLIENT_SECRET` path.
