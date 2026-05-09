# Troubleshooting

Common issues and how to resolve them.

---

## Capacity data

### "Failed to retrieve family summary" — `[Ref XXXXXX]`

**Cause:** The API returned an error. The `Ref` ID links to an Application Insights trace.

**Steps:**

1. Search the error in App Insights:
   ```kql
   traces
   | where customDimensions.correlationId == "<ref-from-error>"
   | order by timestamp asc
   ```
2. Common root causes:
   - No ingestion has run → Admin panel → Ingestion → Run Now
   - SQL connection failed → check `/healthz`
   - Filter combination returned no rows → try removing filters

---

### Capacity data is stale / showing old snapshot time

**Cause:** Ingestion hasn't run recently or failed silently.

**Steps:**
1. Admin panel → Ingestion → check **Last Run** timestamp and status
2. If failed, check the error log in Admin panel → Errors
3. Trigger a manual run: Admin panel → Ingestion → Run Now
4. Verify ARM access: the managed identity must have **Reader** on each subscription

---

### Missing subscriptions in the capacity explorer

**Cause:** The App Service managed identity doesn't have Reader on those subscriptions.

**Fix:** Grant Reader role to the managed identity:

```bash
az role assignment create \
  --assignee <managedIdentityPrincipalId> \
  --role Reader \
  --scope /subscriptions/<missing-subscription-id>
```

Then re-run ingestion.

---

## Quota

### `/api/quota/management-groups`: "Failed to retrieve management groups"

**Cause:** `QUOTA_MANAGEMENT_GROUP_ID` is empty or set to an incorrect value, or the managed identity lacks access to the management group.

**Steps:**
1. Verify the env var: Admin panel → Config → look for `QUOTA_MANAGEMENT_GROUP_ID`
2. Get your root management group ID:
   ```bash
   az account management-group list --query "[0].name" -o tsv
   ```
3. Set the env var on the App Service:
   ```bash
   az webapp config appsettings set \
     --name app-capdash-prod \
     --resource-group rg-capdash-prod \
     --settings QUOTA_MANAGEMENT_GROUP_ID=<mg-id>
   ```
4. Grant the managed identity **Reader** on the management group if needed.

---

## Authentication

### Login redirect loop

**Cause:** `AUTH_REDIRECT_URI` doesn't match the registered redirect URI in Entra.

**Fix:**
1. Check the registered URIs: Azure Portal → App registrations → your app → Authentication → Redirect URIs
2. Ensure `AUTH_REDIRECT_URI` env var matches exactly (including trailing slash if present)
3. Add `https://<your-app>.azurewebsites.net/auth/callback` to the registered URIs if missing

---

### "AADSTS50011: The redirect URI specified in the request does not match"

Same as above — redirect URI mismatch.

---

### Users can log in but can't see admin features

**Cause:** User is not in the Entra group specified by `ADMIN_GROUP_ID`.

**Fix:**
1. Verify `ADMIN_GROUP_ID` in Admin panel → Config
2. Add the user to the group in Entra ID
3. The user needs to log out and log back in (session must be refreshed)

---

## Database / SQL

### Health check returns `{ "status": "degraded" }`

**Cause:** App Service cannot connect to Azure SQL.

**Checklist:**
- [ ] `SQL_SERVER` and `SQL_DATABASE` env vars are set correctly
- [ ] Managed identity has **SQL DB Contributor** role on the database
- [ ] SQL server firewall / VNet integration allows traffic from the App Service subnet
- [ ] `SQL_AUTH_MODE=msi` (not `sql`) in production

---

### "Login failed for user 'token-identified principal'"

**Cause:** Managed identity is not added as a SQL user or doesn't have correct database permissions.

**Fix:**

Run as SQL admin:

```sql
CREATE USER [app-capdash-prod] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [app-capdash-prod];
ALTER ROLE db_datawriter ADD MEMBER [app-capdash-prod];
ALTER ROLE db_ddladmin ADD MEMBER [app-capdash-prod];
```

Replace `app-capdash-prod` with your App Service name.

---

## Infrastructure / Deploy

### Bicep deploy fails with `AuthorizationFailed` on `roleAssignments`

**Cause:** The bootstrap SPN doesn't have `User Access Administrator` at subscription scope.

**Fix:** Re-run the bootstrap script — it grants this role:

```powershell
.\scripts\bootstrap-github-oidc.ps1 -TenantId ... -SubscriptionId ... `
  -ResourceGroup rg-capdash-prod -GitHubOrg IBuySpy-Dev `
  -GitHubRepo Capacity-Planning-Dashboard -EnvironmentName production
```

---

### GitHub Actions workflow fails with `AADSTS70021`

**Cause:** The OIDC federated credential subject doesn't match the workflow's `environment` name.

**Fix:** Ensure the federated credential subject in Azure matches exactly:

```
repo:IBuySpy-Dev/Capacity-Planning-Dashboard:environment:production
```

Check with: `az ad app federated-credential list --id <clientId>`
