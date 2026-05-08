using './main.bicep'

param location = 'centralus'
param environment = 'test'
param workloadSuffix = 'demo001'

// Supply at deployment time for Azure SQL Entra admin configuration.
param sqlEntraAdminLogin = 'user@contoso.com'
param sqlEntraAdminObjectId = '00000000-0000-0000-0000-000000000000'

// ─── Secret parameters ─────────────────────────────────────────────────────
//
// On first deploy — or whenever you want to rotate — pass these at the CLI:
//   az deployment group create ... \
//     --parameters ingestApiKey="$(openssl rand -hex 32)" \
//                  sessionSecret="$(openssl rand -hex 32)"
//
// After the first deploy the secrets live in Key Vault. Subsequent deploys can
// omit these params and the app will continue reading them from Key Vault.
// NEVER commit real secret values in this file.
//
// param ingestApiKey = ''   # Key Vault secret: capdash-ingest-api-key
// param sessionSecret = ''  # Key Vault secret: capdash-session-secret

// Use a distinct address space from dev so future peering or shared-network scenarios do not collide.
param vnetAddressPrefix = '10.91.0.0/16'
param appServiceIntegrationSubnetPrefix = '10.91.1.0/24'
param privateEndpointSubnetPrefix = '10.91.2.0/24'
param sqlPublicNetworkAccess = 'Disabled'
param keyVaultPublicNetworkAccess = 'Disabled'

// Preferred for larger estates: grant dashboard/worker RBAC at one or more management groups.
// Example:
// param quotaManagementGroupId = 'Demo-MG'
// param webReaderManagementGroupNames = [
//   'Platform'
// ]
// param webQuotaWriterManagementGroupNames = [
//   'Platform'
// ]
// param workerRbacManagementGroupNames = [
//   'Platform'
// ]
// param assignWorkerComputeRecommendationsRole = true
// param assignWorkerCostManagementReaderRole = true
// param assignWorkerBillingReaderRole = true

// Fallback for smaller customers without management groups.
// Example:
// param webReaderSubscriptionIds = [
//   '00000000-0000-0000-0000-000000000000'
// ]
// param workerSubscriptionRbacSubscriptionIds = [
//   '00000000-0000-0000-0000-000000000000'
// ]

// Optional: enable dashboard Entra sign-in by supplying your app registration values.
// Example:
// param authEnabled = true
// param entraTenantId = '00000000-0000-0000-0000-000000000000'
// param entraClientId = '00000000-0000-0000-0000-000000000000'
// param entraClientSecret = 'replace-with-secret-at-deploy-time'
// param adminGroupId = '00000000-0000-0000-0000-000000000000'
// param authRedirectUri = 'https://<web-app-name>.azurewebsites.net/auth/callback'
