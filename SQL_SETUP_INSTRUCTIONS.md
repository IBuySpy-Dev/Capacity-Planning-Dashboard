# SQL Managed Identity Setup - Manual Steps

## Problem
The application is failing to access the SQL database because the managed identity is not authorized as a database user.

## Solution
Create a contained database user for the App Service managed identity with appropriate role grants.

## Steps

### 1. Open Azure Portal SQL Query Editor
- Navigate to: https://portal.azure.com
- Search for "SQL servers" and select "sql-capdash-prod-prod01"
- Click on database "sqldb-capdash-prod"
- In the left sidebar under "Development", click "Query editor (preview)"
- Sign in when prompted (use your @ibuyspy.net account)

### 2. Run the SQL Setup Commands

Copy and paste ALL of these commands into the Query editor and click "Run":

`sql
-- Create database user for managed identity
CREATE USER [app-capdash-prod-prod01] FROM EXTERNAL PROVIDER;

-- Grant database reader role (for SELECT queries)
ALTER ROLE db_datareader ADD MEMBER [app-capdash-prod-prod01];

-- Grant database writer role (for INSERT/UPDATE/DELETE queries)
ALTER ROLE db_datawriter ADD MEMBER [app-capdash-prod-prod01];

-- Grant DDL admin role (required for schema initialization DDL: CREATE TABLE, ALTER TABLE, CREATE INDEX)
ALTER ROLE db_ddladmin ADD MEMBER [app-capdash-prod-prod01];
`

### 3. Verify Success
- All four commands should execute without errors
- You should see: "(4 rows affected)"

### 4. Restart the App Service
Run this command in PowerShell/terminal:

`powershell
az webapp restart --resource-group rg-capdash-prod --name app-capdash-prod-prod01
`

### 5. Test the API
Once the app restarts, test the API:

`powershell
$token = az account get-access-token --resource https://app-capdash-prod-prod01.azurewebsites.net --query accessToken -o tsv
curl -H "Authorization: Bearer $token" https://app-capdash-prod-prod01.azurewebsites.net/api/subscriptions
`

Expected response: HTTP 200 with JSON data (not HTTP 500 error)

## Troubleshooting

If you get "User already exists" error:
- The user was already created - no action needed, proceed to step 4

If the API still fails after restart:
- Check Application Insights logs for the exact error
- Verify the managed identity was created in the App Service (Settings > Identity)

## References
- Issue: #9 - SQL managed identity contained database user not configured
- Related: #8 - API Error - subscription retrieval failing
