# Scripts Inventory Map

## Purpose

This document inventories the mixed-language helpers in `scripts/`, groups them by responsibility, and highlights where behavior is duplicated or overlaps.

Some scripts are cross-listed when they clearly serve more than one category (for example, SQL bootstrap helpers that are both identity-setup and database bootstrap tools).

## Verification Criteria

- Inventory covers every file currently present in `scripts/` on this checkout.
- Each entry includes filename, language, purpose, prerequisites, and a usage example.
- Duplicate and overlapping helpers are called out explicitly.

## Language Legend

- **PS** — PowerShell
- **Node** — Node.js script
- **Bash** — POSIX shell script
- **Python** — Python script

## Azure / Identity Bootstrap

| Filename | Language | Purpose | Prerequisites | Usage example |
|---|---|---|---|---|
| `bootstrap-and-deploy.ps1` | PS | Orchestrates GitHub OIDC bootstrap, Conditional Access checks, and deployment flow. | PowerShell 7+, Azure CLI, GitHub CLI, Azure and GitHub auth. | `.\scripts\bootstrap-and-deploy.ps1 -SkipOIDC -SkipCAPolicy -TriggerDeployment -WaitForDeployment` |
| `bootstrap-ca-policy.ps1` | PS | Diagnoses or configures Entra Conditional Access exceptions so GitHub OIDC token exchange can work. | PowerShell 7+, Azure CLI, permissions to review or change Entra Conditional Access policies. | `.\scripts\bootstrap-ca-policy.ps1 -Mode check -TenantId "<tenant-id>"` |
| `bootstrap-github-oidc.ps1` | PS | Creates an Azure service principal and federated credentials for GitHub Actions OIDC. | PowerShell 7+, Azure CLI, GitHub CLI, Azure permissions to create app/service principals. | `.\scripts\bootstrap-github-oidc.ps1 -SubscriptionId "<subscription-id>" -ResourceGroupName "rg-capdash-prod" -GitHubOrganization "IBuySpy-Dev" -GitHubRepository "Capacity-Planning-Dashboard"` |
| `bootstrap-sql-managed-identity.ps1` | PS | Configures Azure SQL access for an App Service managed identity and runs SQL bootstrap steps. | PowerShell 7+, Azure CLI, `sqlcmd`, rights to manage SQL Server identity and database access. | `.\scripts\bootstrap-sql-managed-identity.ps1 -AppServiceName "app-capdash-prod" -SqlServerName "sql-capdash-prod" -SqlDatabaseName "sqldb-capdash-prod" -ResourceGroup "rg-capdash-prod" -SubscriptionId "<subscription-id>"` |
| `New-EntraApp.ps1` | PS | Creates a multi-tenant Entra app registration for dashboard sign-in and outputs local auth settings. | PowerShell 7+, Microsoft Graph PowerShell SDK, Graph permissions to create app registrations. | `.\scripts\New-EntraApp.ps1 -ProductionRedirectUri "https://<web-app-name>.azurewebsites.net/auth/callback"` |
| `grant-quota-rbac.ps1` | PS | Assigns the **GroupQuota Request Operator** role across subscriptions and optionally a management group. | PowerShell 7+, Azure CLI, RBAC permissions to create role assignments. | `.\scripts\grant-quota-rbac.ps1 -PrincipalObjectId "<principal-object-id>" -ManagementGroupId "<management-group-id>" -AssignManagementGroupRole` |

## Database

| Filename | Language | Purpose | Prerequisites | Usage example |
|---|---|---|---|---|
| `apply-database-upgrade.ps1` | PS | Applies a selected SQL upgrade file to a target database with `sqlcmd`. | PowerShell 7+, `sqlcmd`, Azure CLI or another supported Entra auth method. | `.\scripts\apply-database-upgrade.ps1 -SqlServer "<server>.database.windows.net" -SqlDatabase "<database>" -SqlFile "sql\migrations\20260427-add-paas-availability-and-ui-settings.sql"` |
| `apply-migration.ps1` | PS | Applies a single SQL migration file with either SQL auth or Entra auth. | PowerShell 7+, `sqlcmd`; Azure CLI if using `-UseEntra`. | `.\scripts\apply-migration.ps1 -SqlServer "<server>" -SqlDatabase "<database>" -MigrationFile "sql\migrations\001.sql" -UseEntra` |
| `apply-schema.ps1` | PS | Applies the base schema file to a database. | PowerShell 7+, `sqlcmd`; Azure CLI if using `-UseEntra`. | `.\scripts\apply-schema.ps1 -SqlServer "<server>" -SqlDatabase "<database>" -UseEntra` |
| `bootstrap-sql-managed-identity.ps1` | PS | Configures SQL managed identity access and executes SQL initialization steps for the app. | PowerShell 7+, Azure CLI, `sqlcmd`, SQL and Entra permissions. | `.\scripts\bootstrap-sql-managed-identity.ps1 -AppServiceName "app-capdash-prod" -SqlServerName "sql-capdash-prod" -SqlDatabaseName "sqldb-capdash-prod" -ResourceGroup "rg-capdash-prod" -SubscriptionId "<subscription-id>"` |
| `ensure-subscriptions-table.js` | Node | Creates `dbo.Subscriptions` when missing and backfills it from `dbo.CapacitySnapshot`. | Node.js, `npm install`, Azure CLI login, `SQL_SERVER` and `SQL_DATABASE` environment variables. | `$env:SQL_SERVER="<server>"; $env:SQL_DATABASE="<database>"; node scripts/ensure-subscriptions-table.js` |
| `initialize-database.ps1` | PS | Runs `schema.sql`, all migrations, and runtime role grants for an app identity. | PowerShell 7+, `sqlcmd`, Azure CLI login or supported Entra auth. | `.\scripts\initialize-database.ps1 -SqlServer "<server>" -SqlDatabase "<database>" -AppIdentityName "app-capdash-prod"` |
| `inspect-db.js` | Node | Prints summary counts and sample rows from key capacity tables and views. | Node.js, `npm install`, Azure CLI login, `SQL_SERVER` and `SQL_DATABASE` environment variables. | `$env:SQL_SERVER="<server>"; $env:SQL_DATABASE="<database>"; node scripts/inspect-db.js` |
| `load-sample-data.ps1` | PS | Inserts sample rows into `dbo.CapacitySnapshot` for local or test validation. | PowerShell 7+, `sqlcmd`; Azure CLI if using `-UseEntra`. | `.\scripts\load-sample-data.ps1 -SqlServer "<server>" -SqlDatabase "<database>" -UseEntra` |
| `optimize-capacitylatest-view.js` | Node | Recreates `dbo.CapacityLatest` as a latest-capture view and prints row counts. | Node.js, `npm install`, Azure CLI login, `SQL_SERVER` and `SQL_DATABASE` environment variables. | `$env:SQL_SERVER="<server>"; $env:SQL_DATABASE="<database>"; node scripts/optimize-capacitylatest-view.js` |
| `run-migration.js` | Node | Runs a migration file through the app's SQL connection configuration. | Node.js, `npm install`, `.env` or environment variables for SQL connection. | `node scripts/run-migration.js sql/migrations/001.sql` |
| `run-migration.py` | Python | Executes a migration file with Azure CLI token auth and `pyodbc`. | Python 3, `pyodbc`, Azure CLI login, ODBC Driver 17 for SQL Server. | `python scripts/run-migration.py sql/migrations/001.sql <server> <database>` |

## Deployment

| Filename | Language | Purpose | Prerequisites | Usage example |
|---|---|---|---|---|
| `deploy-infra.ps1` | PS | Deploys dashboard infrastructure with Bicep or Terraform, then optionally deploys app packages and bootstraps the database. | PowerShell 7+, Azure CLI, Bicep or Terraform toolchain depending on `-Provider`, deployment permissions. | `.\scripts\deploy-infra.ps1 -Provider Bicep -ResourceGroupName "rg-capdash-dev" -WorkloadSuffix "dev01" -SqlEntraAdminLogin "<admin-upn-or-group>" -SqlEntraAdminObjectId "<object-id>"` |
| `deploy-worker.ps1` | PS | Packages the Azure Functions worker app and deploys it with zip deploy. | PowerShell 7+, Azure CLI, Function App already provisioned. | `.\scripts\deploy-worker.ps1 -ResourceGroupName "rg-capdash-dev" -FunctionAppName "func-capdash-dev-dev01-appsvc"` |
| `destroy-infra.ps1` | PS | Tears down deployed infrastructure by deleting the resource group or running `terraform destroy`. | PowerShell 7+, Azure CLI, Terraform CLI for `-Provider Terraform`. | `.\scripts\destroy-infra.ps1 -Provider Bicep -ResourceGroupName "rg-capdash-dev"` |
| `invoke-from-clean-main.ps1` | PS | Runs another script from a clean detached worktree based on `github/main` or another ref. | PowerShell 7+, Git, target script present in the repo. | `.\scripts\invoke-from-clean-main.ps1 -ScriptRelativePath "scripts/deploy-infra.ps1" -ForwardedArguments @('-Provider','Bicep')` |

## Governance / Guards

| Filename | Language | Purpose | Prerequisites | Usage example |
|---|---|---|---|---|
| `assert-internal-github-target.ps1` | PS | Blocks GitHub write operations unless the target repository belongs to an allowed organization. | PowerShell 7+. | `.\scripts\assert-internal-github-target.ps1 -Repository "IBuySpy-Dev/Capacity-Planning-Dashboard"` |
| `assert-internal-github-target.sh` | Bash | Bash equivalent of the internal GitHub organization allowlist guard. | Bash. | `bash scripts/assert-internal-github-target.sh IBuySpy-Dev/Capacity-Planning-Dashboard` |
| `validate-repo-target.ps1` | PS | Blocks GitHub write operations unless the exact `owner/repo` target is allowlisted. | PowerShell 7+. | `.\scripts\validate-repo-target.ps1 -Target "ivegamsft/Capacity-Planning-Dashboard"` |
| `validate-repo-target.sh` | Bash | Bash equivalent of the exact repository allowlist guard. | Bash. | `bash scripts/validate-repo-target.sh ivegamsft/Capacity-Planning-Dashboard` |

## Testing / Development

> Note: the issue description mentioned `start-e2e-server.js`, but that file is not present in the checked-out `scripts/` directory, so it is not part of the verified inventory below.

| Filename | Language | Purpose | Prerequisites | Usage example |
|---|---|---|---|---|
| `benchmark-placement-score.js` | Node | Benchmarks direct REST placement scoring against the PowerShell-based placement workflow. | Node.js, `npm install`, Azure CLI login, PowerShell available for the comparison path. | `node scripts/benchmark-placement-score.js --subscription <subscription-id> --regions centralus,eastus --sku Standard_D4s_v5 --desired-count 5` |
| `inspect-skus.js` | Node | Explores SKU- and family-related columns and values in the capacity database. | Node.js, `npm install`, Azure CLI login, `SQL_SERVER` and `SQL_DATABASE` environment variables. | `$env:SQL_SERVER="<server>"; $env:SQL_DATABASE="<database>"; node scripts/inspect-skus.js` |

## Duplicate Helpers

### Same logic in multiple languages

| PowerShell | Bash | Notes |
|---|---|---|
| `assert-internal-github-target.ps1` | `assert-internal-github-target.sh` | Same internal-organization allowlist check for GitHub write targets. |
| `validate-repo-target.ps1` | `validate-repo-target.sh` | Same exact-repository allowlist check for GitHub write targets. |

### Same goal across multiple runtimes

| Scripts | Shared responsibility |
|---|---|
| `run-migration.js`, `run-migration.py`, `apply-migration.ps1` | Apply a single SQL migration file. The main difference is runtime and auth model. |

## Overlapping Functionality

| Scripts | Overlap |
|---|---|
| `apply-schema.ps1` and `initialize-database.ps1` | Both handle schema setup; `initialize-database.ps1` is the broader bootstrap path because it also runs migrations and grants roles. |
| `apply-database-upgrade.ps1`, `apply-migration.ps1`, and `run-migration.*` | All execute SQL files against a database. `apply-database-upgrade.ps1` is upgrade-oriented, while the others are generic migration runners. |
| `inspect-db.js` and `inspect-skus.js` | Both are read-only SQL inspection utilities; one focuses on overall database state, the other on SKU taxonomy. |
| `bootstrap-github-oidc.ps1`, `bootstrap-ca-policy.ps1`, and `bootstrap-and-deploy.ps1` | The first two are focused bootstrap helpers; `bootstrap-and-deploy.ps1` orchestrates them and adds deployment flow. |
| `deploy-infra.ps1` and `deploy-worker.ps1` | `deploy-infra.ps1` can orchestrate app deployment end-to-end, while `deploy-worker.ps1` targets only the worker package step. |
| `assert-internal-github-target.*` and `validate-repo-target.*` | Both guard GitHub write targets, but one validates by organization and the other by exact repository. |

## Suggested Reading Order

1. Start with the category matching your task.
2. Prefer the focused helper before the orchestrator when testing a single concern.
3. Use the duplicate and overlap tables before adding another script with similar behavior.
