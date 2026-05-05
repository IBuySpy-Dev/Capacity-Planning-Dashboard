# GitHub Actions CI/CD Deployment

This repository uses GitHub Actions to automate building, testing, and deploying the Capacity Planning Dashboard to Azure.

## Workflow: Deploy Capacity Dashboard

**File**: `.github/workflows/deploy.yml`

### Triggers

#### Automatic Deployment (Push to Main)
```yaml
on:
  push:
    branches: [ main ]
```
When you push commits to the `main` branch, the workflow automatically:
1. Checks out the code
2. Runs tests
3. Builds the deployment package
4. Deploys to Azure App Service

#### Manual Deployment (Workflow Dispatch)
```yaml
workflow_dispatch:
  inputs:
    environment:
      description: 'Environment to deploy to'
      default: 'prod'
      options: [dev, staging, prod]
```
Manually trigger deployment from the GitHub UI:
- Go to **Actions** → **Deploy Capacity Dashboard** → **Run workflow**
- Select target environment
- Click **Run workflow**

### Jobs

#### 1. Build and Test (`build-and-test`)
- **Runs on**: Ubuntu Latest
- **Steps**:
  - Checkout code
  - Setup Node.js 22
  - Install dependencies (`npm ci`)
  - Run tests (`npm test`)

**Status**: Must pass before deployment

#### 2. Auto-Deploy (`deploy`)
- **Runs on**: Ubuntu Latest
- **Trigger**: Automatic on push to main (after tests pass)
- **Steps**:
  - Checkout code
  - Azure Login
  - Setup Node.js 22
  - Install dependencies
  - Create deployment package (zip)
  - Deploy to Azure App Service
  - Verify deployment

#### 3. Manual Deploy (`deploy-manual`)
- **Runs on**: Ubuntu Latest
- **Trigger**: Manual workflow_dispatch
- **Steps**: Same as auto-deploy, includes post-deployment verification

### Required Secrets

Configure these secrets in your GitHub repository settings:

| Secret | Description | Example |
|--------|-------------|---------|
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID | `844eabcc-dc96-453b-8d45-bef3d566f3f8` |
| `AZURE_RESOURCE_GROUP` | Azure resource group name | `rg-capdash-prod` |
| `AZURE_WEBAPP_NAME` | Azure App Service name | `app-capdash-prod-prod01` |
| `AZURE_CREDENTIALS` | Azure login credentials (JSON format) | Output from `az ad sp create-for-rbac` |

### Setup Instructions

#### 1. Create Azure Service Principal

```bash
az ad sp create-for-rbac \
  --name "GitHubActions-CapDash" \
  --role Contributor \
  --scopes /subscriptions/YOUR-SUBSCRIPTION-ID \
  --json-auth > azure-credentials.json
```

#### 2. Add Secrets to GitHub

1. Go to repository **Settings** → **Secrets and variables** → **Actions**
2. Add each secret from the table above
3. For `AZURE_CREDENTIALS`, paste the entire JSON output from the service principal creation

#### 3. Grant Permissions (if needed)

If deployments fail with permission errors, add role assignments:

```bash
# For your currently authenticated user (you)
az role assignment create \
  --assignee-object-id YOUR-USER-ID \
  --role "User Access Administrator" \
  --scope /subscriptions/YOUR-SUBSCRIPTION-ID
```

### Environment Variables (Configured in Workflow)

```yaml
AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
AZURE_RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}
AZURE_WEBAPP_NAME: ${{ secrets.AZURE_WEBAPP_NAME }}
AZURE_LOCATION: 'westus2'
```

### Deployment Package Contents

The workflow creates a zip package with:
- `package.json` & `package-lock.json` (dependencies)
- `server.js` & `app.js` (Node.js application)
- `index.html` & `styles.css` (UI assets)
- `web.config` (IIS configuration)
- `react/` directory (React components)
- `src/` directory (source code)
- `tools/` directory (utility scripts)

### Monitoring

#### View Workflow Status
1. Go to **Actions** tab in repository
2. Click **Deploy Capacity Dashboard**
3. Select a workflow run to see details

#### Check Deployment Logs
1. Click on a workflow run
2. Click on the job (e.g., `deploy`)
3. Expand each step to view logs

#### App Deployment Logs (Azure)
```bash
az webapp log tail --resource-group rg-capdash-prod --name app-capdash-prod-prod01
```

### Rollback

If deployment fails:

1. **Revert the commit** (if needed)
   ```bash
   git revert HEAD
   git push origin main
   ```

2. **Manual rollback** (return to working slot)
   ```bash
   az webapp deployment slot swap \
     --resource-group rg-capdash-prod \
     --name app-capdash-prod-prod01 \
     --slot staging
   ```

### Troubleshooting

| Error | Solution |
|-------|----------|
| `AZURE_CREDENTIALS` not found | Add secret to GitHub Settings |
| Deployment fails with `ResourceNotFound` | Verify `AZURE_RESOURCE_GROUP` and `AZURE_WEBAPP_NAME` secrets |
| Tests fail during build | Fix failing tests locally before pushing |
| Package creation fails | Ensure all required files exist in repo root |

### Best Practices

1. **Always run tests locally first**
   ```bash
   npm test
   ```

2. **Use meaningful commit messages** with conventional commit format:
   ```
   feat(api): add new endpoint
   fix(ui): resolve styling issue
   ```

3. **Create feature branches** before making changes
   ```bash
   git checkout -b feature/your-feature
   ```

4. **Create Pull Requests** for code review before merging to main

5. **Monitor deployment status** in the Actions tab

### Advanced Configuration

#### Deploy to Staging First

To add a staging environment deployment slot:

1. Create staging slot in Azure:
   ```bash
   az webapp deployment slot create \
     --resource-group rg-capdash-prod \
     --name app-capdash-prod-prod01 \
     --slot staging
   ```

2. Update workflow to deploy to staging first, then swap with production after manual approval

#### Performance Optimization

- Node.js caching: Already configured with `cache: 'npm'`
- Parallel jobs: Can be added for multiple environment deployments
- Build artifacts: Consider uploading build logs as artifacts

### Related Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Web Apps Deploy Action](https://github.com/Azure/webapps-deploy)
- [Azure Login Action](https://github.com/Azure/login)
- [Node.js Setup Action](https://github.com/actions/setup-node)
