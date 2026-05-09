---
name: azure-linux-app-service
description: Deploy and operate Python, Ruby, and Node.js applications on Azure App Service Linux using PaaS patterns, slot swaps, and log streaming.
metadata:
  category: infrastructure
  keywords: "azure, app-service, linux, python, ruby, nodejs, paas, deployment"
  maturity: production
  audience: [backend-engineer, devops-engineer, platform-engineer]
allowed-tools: [bash, azure-cli, git]
---

# Azure Linux App Service

Deploy and operate Python, Ruby, and Node.js web applications on Azure App Service Linux.
Covers startup configuration, deployment slots, health checks, environment variables,
log streaming, and common failure patterns.

## Triggers

Use this skill when:

- Deploying a Python (Flask/FastAPI/Django), Ruby (Rails/Sinatra), or Node.js app to App Service Linux
- Configuring startup commands, runtime versions, or health check endpoints
- Setting up deployment slots and blue-green slot swap workflows
- Diagnosing startup timeouts, wrong runtime version, or missing dependency errors
- Streaming live logs from a running App Service instance
- Choosing between code deploy and container deploy for an existing app

## Inputs

- App Service name, resource group, and target runtime (`python|3.11`, `node|20-lts`, `ruby|3.2`)
- Entry point file or WSGI/Rack module (`myapp:app`, `config.ru`, `server.js`)
- Source: local folder, GitHub repo, or container image
- Environment variables and connection strings to inject as App Settings
- Slot names for staging/production swap pattern (optional)

## Workflow

### 1. Runtime and startup command

Set the Linux runtime and startup command before first deploy:

```bash
az webapp config set \
  --resource-group <rg> --name <app> \
  --linux-fx-version "PYTHON|3.11" \
  --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 myapp:app"
```

Runtime strings per language:

| Language | Example value |
|----------|--------------|
| Python   | `PYTHON\|3.11` |
| Ruby     | `RUBY\|3.2` |
| Node.js  | `NODE\|20-lts` |

Startup command examples:

- Python (Gunicorn): `gunicorn --bind=0.0.0.0 --timeout 600 myapp:app`
- Ruby (Puma): `bundle exec puma -C config/puma.rb`
- Node.js: `node server.js` or `npm start`

### 2. App Settings (environment variables)

Inject secrets and config as App Settings — never bake them into code:

```bash
az webapp config appsettings set \
  --resource-group <rg> --name <app> \
  --settings DATABASE_URL="<value>" SECRET_KEY="<value>" NODE_ENV="production"
```

Use Key Vault references for sensitive values:

```bash
--settings DATABASE_URL="@Microsoft.KeyVault(SecretUri=https://<kv>.vault.azure.net/secrets/<name>/)"
```

### 3. Health check endpoint

Configure health checks so the platform routes traffic away from unhealthy instances:

```bash
az webapp config set \
  --resource-group <rg> --name <app> \
  --generic-configurations '{"healthCheckPath": "/health"}'
```

The `/health` endpoint must return HTTP 200. Path is checked every 2 minutes;
instances failing for 10 minutes are replaced.

### 4. Deployment slots and slot swap

Create a staging slot and deploy there before swapping to production:

```bash
# Create slot
az webapp deployment slot create \
  --resource-group <rg> --name <app> --slot staging

# Deploy to staging
az webapp deploy \
  --resource-group <rg> --name <app> --slot staging \
  --src-path ./app.zip --type zip

# Validate staging, then swap
az webapp deployment slot swap \
  --resource-group <rg> --name <app> \
  --slot staging --target-slot production
```

Mark App Settings as "Deployment slot setting" (sticky) to keep slot-specific
config (e.g., `ASPNETCORE_ENVIRONMENT=Staging`) from being swapped.

### 5. Code deploy vs container deploy

| Criterion | Code deploy | Container deploy |
|-----------|-------------|-----------------|
| Build control | Platform builds on startup | You build the image |
| Cold start | Slower (build on first start) | Faster (pre-built image) |
| Runtime customization | Limited to supported stacks | Full Dockerfile control |
| Best for | Standard stacks, quick iteration | Custom runtimes, OS packages |

For container deploy:

```bash
az webapp config container set \
  --resource-group <rg> --name <app> \
  --docker-custom-image-name <acr>.azurecr.io/<image>:<tag> \
  --docker-registry-server-url https://<acr>.azurecr.io
```

### 6. Log streaming

Stream live logs to diagnose startup or runtime errors:

```bash
az webapp log tail --resource-group <rg> --name <app>
```

Enable detailed logging first if logs are sparse:

```bash
az webapp log config \
  --resource-group <rg> --name <app> \
  --application-logging filesystem \
  --level information \
  --web-server-logging filesystem
```

## Output

- Running App Service with correct runtime, startup command, and App Settings
- Health check path configured and returning 200
- Deployment slot workflow documented and validated
- Log streaming confirmed operational
- Container vs code deploy decision recorded

## Examples

### Python FastAPI on App Service Linux

```bash
az webapp create \
  --resource-group myRG --name myapp \
  --plan myPlan --runtime "PYTHON|3.11"

az webapp config set \
  --resource-group myRG --name myapp \
  --startup-file "gunicorn --bind=0.0.0.0 --timeout 600 main:app"

az webapp config appsettings set \
  --resource-group myRG --name myapp \
  --settings DATABASE_URL="$DB_URL" ENVIRONMENT="production"

az webapp deploy \
  --resource-group myRG --name myapp \
  --src-path ./dist.zip --type zip
```

### Node.js Express with staging slot

```bash
az webapp deployment slot create \
  --resource-group myRG --name myapp --slot staging

az webapp config set \
  --resource-group myRG --name myapp --slot staging \
  --linux-fx-version "NODE|20-lts" \
  --startup-file "node server.js"

az webapp deploy \
  --resource-group myRG --name myapp --slot staging \
  --src-path ./app.zip --type zip

# After validation:
az webapp deployment slot swap \
  --resource-group myRG --name myapp \
  --slot staging --target-slot production
```

## Common Failure Patterns

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Container keeps restarting / 503 on startup | Startup command incorrect or app crashes before binding | Check `az webapp log tail`; verify startup file path and port binding (`0.0.0.0`) |
| `ModuleNotFoundError` on Python app | `requirements.txt` missing or not at repo root | Ensure `requirements.txt` is at root; redeploy with zip including it |
| Wrong Python/Node version | Runtime not explicitly set | Run `az webapp config set --linux-fx-version "PYTHON\|3.11"` |
| Health check failing | Endpoint not yet available at startup | Increase startup timeout or fix health check path |
| App Settings not visible at runtime | Slot-sticky settings deployed to wrong slot | Verify setting stickiness and target slot |
