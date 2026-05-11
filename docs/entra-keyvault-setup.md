# Entra client secret Key Vault setup

Use this flow to stop passing `ENTRA_CLIENT_SECRET` as a raw GitHub secret during Bicep deployment.

## Automated Setup via Bootstrap

Use the scripts to create the Entra app, store the client secret in Key Vault, and push the URI into GitHub variables.

### 1. Create the Entra app and store the secret in Key Vault

```powershell
.\scripts\New-EntraApp.ps1 `
  -ProductionRedirectUri 'https://<web-app-name>.azurewebsites.net/auth/callback' `
  -KeyVaultName 'kv-capdash-prod-prod01'
```

The script stores the secret as `capdash-entra-client-secret` and prints `ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI`.

### 2. Pass the URI to bootstrap OIDC setup

```powershell
.\scripts\bootstrap-github-oidc.ps1 `
  -SubscriptionId '<subscription-id>' `
  -ResourceGroupName 'rg-capdash-prod' `
  -GitHubOrganization 'IBuySpy-Dev' `
  -GitHubRepository 'Capacity-Planning-Dashboard' `
  -EntraClientSecretKvUri 'https://kv-capdash-prod-prod01.vault.azure.net/secrets/capdash-entra-client-secret/<version>'
```

Bootstrap sets the repository variable `ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI`, which `bicep-deploy.yml` passes through to Bicep. Keep the manual steps below as a fallback if you do not want bootstrap to create the variable for you.

## Manual Setup

If you prefer to manage Key Vault manually, use the steps below instead of the automated bootstrap flow.

### 1. Store the secret in Key Vault

```bash
az keyvault secret set --vault-name kv-capdash-prod-prod01 --name capdash-entra-client-secret --value <secret>
```

### 2. Set the GitHub repository variable

```bash
gh variable set ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI --body "https://kv-capdash-prod-prod01.vault.azure.net/secrets/capdash-entra-client-secret"
```

`bicep-deploy.yml` now passes this URI as `entraClientSecretKvUri`. When present, Bicep emits the App Service Key Vault reference without needing the raw secret value.

## Deploy and verify

1. Run the next `bicep-deploy.yml` deployment.
2. Open the App Service configuration in Azure Portal.
3. Confirm `ENTRA_CLIENT_SECRET` is set to an `@Microsoft.KeyVault(...)` reference.
4. Confirm Entra sign-in still works after deployment.

## Fallback behavior

If `ENTRA_CLIENT_SECRET_KEYVAULT_SECRET_URI` is empty, deployment still falls back to the existing `entraClientSecret`/`ENTRA_CLIENT_SECRET` path.
