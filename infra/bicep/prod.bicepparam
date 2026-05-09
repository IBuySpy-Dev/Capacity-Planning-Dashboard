using './main.bicep'

// ─── Non-secret production parameters ────────────────────────────────────────
param location = 'westus2'
param environment = 'prod'
param workloadSuffix = 'prod01'

// SQL Server Entra admin — group that contains both the deployment SPN and
// the human admin (a-ivega@ibuyspy.net).  Group: grp-sql-capdash-admins
// To update: az ad group show --group grp-sql-capdash-admins --query '{login:displayName, sid:id}'
param sqlEntraAdminLogin = 'grp-sql-capdash-admins'
param sqlEntraAdminObjectId = 'cfc8e389-1ac5-4fab-a0e9-c66be18b0cda'

// Networking (matches existing VNet created in initial deployment)
param vnetAddressPrefix = '10.90.0.0/16'
param appServiceIntegrationSubnetPrefix = '10.90.1.0/24'
param privateEndpointSubnetPrefix = '10.90.2.0/24'

// Private endpoints enabled — public access disabled on SQL and Key Vault
param sqlPublicNetworkAccess = 'Disabled'
param keyVaultPublicNetworkAccess = 'Disabled'

// Entra authentication enabled for all app routes
param authEnabled = true

// ─── Secret parameters — MUST be supplied at deploy time (never commit here) ─
//
// The following params have no default and must be passed on every deployment.
// In GitHub Actions they are sourced from the "production" environment secrets.
// When running manually: az deployment group create ... --parameters prod.bicepparam
//   entraTenantId=<value> entraClientId=<value> entraClientSecret=<value>
//   adminGroupId=<value> ingestApiKey=<value> sessionSecret=<value>
//   quotaManagementGroupId=<tenantId>
//
// param entraTenantId      = '<AZURE_ENTRA_TENANT_ID>'      -- GitHub secret: ENTRA_TENANT_ID
// param entraClientId      = '<AZURE_ENTRA_CLIENT_ID>'      -- GitHub secret: ENTRA_CLIENT_ID
// param entraClientSecret  = '<AZURE_ENTRA_CLIENT_SECRET>'  -- GitHub secret: ENTRA_CLIENT_SECRET
// param adminGroupId       = '<ADMIN_GROUP_OBJECT_ID>'      -- GitHub secret: ADMIN_GROUP_ID
// param ingestApiKey       = '<INGEST_API_KEY>'             -- GitHub secret: INGEST_API_KEY
// param sessionSecret      = '<SESSION_SECRET>'             -- GitHub secret: SESSION_SECRET
//
// quotaManagementGroupId is passed by bicep-deploy.yml from vars.AZURE_MANAGEMENT_GROUP_ID
// (set automatically by bootstrap-github-oidc.ps1 to the tenant root management group).
// This sets the QUOTA_MANAGEMENT_GROUP_ID app setting and triggers post-deploy
// Management Group Reader RBAC assignment to the web app managed identity.
