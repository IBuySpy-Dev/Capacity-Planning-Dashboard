---
description: "Use when writing GitHub Actions workflows that access firewalled Azure resources (Storage, Key Vault, SQL, Cosmos). Covers the single-job runner IP pattern with guaranteed cleanup."
applyTo: "**/*.yml,**/*.yaml"
---

# CI/CD Runner Firewall Management

Use this instruction for any workflow that needs to access Azure resources behind network firewalls.

## Expectations

- All firewall add/work/remove steps **must** be in a **single job** — runner IPs change between jobs.
- The firewall remove step **must** use `if: always()` to ensure cleanup even on failure.
- Use `az` CLI for firewall changes, **not** Terraform — this avoids state drift.
- Wait 15–30 seconds after adding the IP for Azure propagation.
- Log the IP being added and removed for audit trail.

## Pattern

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Get runner IP
        id: ip
        run: echo "runner_ip=$(curl -s https://api.ipify.org)" >> $GITHUB_OUTPUT

      - name: Check firewall status
        id: fw
        run: |
          DEFAULT_ACTION=$(az storage account show -n ${{ env.STORAGE }} -g ${{ env.RG }} --query networkRuleSet.defaultAction -o tsv)
          echo "is_firewalled=$([[ "$DEFAULT_ACTION" == "Deny" ]] && echo true || echo false)" >> $GITHUB_OUTPUT

      - name: Add runner IP to firewall
        if: steps.fw.outputs.is_firewalled == 'true'
        run: |
          az storage account network-rule add -n ${{ env.STORAGE }} -g ${{ env.RG }} --ip-address ${{ steps.ip.outputs.runner_ip }}
          echo "Added ${{ steps.ip.outputs.runner_ip }} to firewall"
          sleep 20  # Wait for Azure propagation

      # === Do work here (Terraform apply, blob ops, secret reads) ===

      - name: Remove runner IP from firewall
        if: always() && steps.fw.outputs.is_firewalled == 'true'
        run: |
          az storage account network-rule remove -n ${{ env.STORAGE }} -g ${{ env.RG }} --ip-address ${{ steps.ip.outputs.runner_ip }} || true
          echo "Removed ${{ steps.ip.outputs.runner_ip }} from firewall"
```

## Rules

- **Check before modifying**: read `defaultAction` first — skip firewall steps if the resource is not firewalled.
- **Same-job guarantee**: never split firewall add and remove across different jobs.
- **`|| true` on remove**: the IP may already be removed if cleanup ran previously; don't fail the workflow.
- **`az` CLI only**: using Terraform for firewall rules causes state drift when rules are added/removed dynamically.
- **Audit logging**: always echo the IP being added and removed.

## Anti-Patterns

```yaml
# WRONG — firewall add in one job, remove in another (different runner IPs!)
jobs:
  setup:
    steps:
      - run: az storage account network-rule add ...
  deploy:
    needs: setup
    steps:
      - run: az storage account network-rule remove ...

# WRONG — no cleanup on failure
- name: Remove IP
  run: az storage account network-rule remove ...
  # Missing: if: always()
```

## Azure SQL Server Firewall

Azure SQL uses a **different API** than Storage/Key Vault. The `publicNetworkAccess` property must be
explicitly enabled before any firewall rule can be added — there is no `defaultAction` equivalent.

**Error signal when missing:** `DenyPublicEndpointEnabled` — the firewall rule add fails even though
you have correct RBAC, because public endpoint access is globally disabled on the server.

```yaml
- name: Open SQL firewall for runner
  run: |
    RUNNER_IP=$(curl -s https://api.ipify.org)
    echo "RUNNER_IP=$RUNNER_IP" >> "$GITHUB_ENV"
    # MUST enable public access first — firewall rules are rejected if this is Disabled
    az sql server update \
      --name "$SQL_SERVER" \
      --resource-group "$RESOURCE_GROUP" \
      --set publicNetworkAccess=Enabled \
      --output none
    az sql server firewall-rule create \
      --resource-group "$RESOURCE_GROUP" \
      --server "$SQL_SERVER" \
      --name "github-runner-${{ github.run_id }}" \
      --start-ip-address "$RUNNER_IP" \
      --end-ip-address "$RUNNER_IP" \
      --output none

- name: Close SQL firewall
  if: always()
  run: |
    az sql server firewall-rule delete \
      --resource-group "$RESOURCE_GROUP" \
      --server "$SQL_SERVER" \
      --name "github-runner-${{ github.run_id }}" \
      --yes 2>/dev/null || true
    # Restore disabled state — must happen even if the rule delete fails
    az sql server update \
      --name "$SQL_SERVER" \
      --resource-group "$RESOURCE_GROUP" \
      --set publicNetworkAccess=Disabled \
      --output none 2>/dev/null || true
```

**Key differences from Storage firewall:**

| | Storage / Key Vault | Azure SQL Server |
|---|---|---|
| Check API | `networkRuleSet.defaultAction` | `publicNetworkAccess` property |
| Pre-condition | Read `defaultAction`, skip if `Allow` | Always enable before adding rule |
| Cleanup | Remove IP rule | Delete rule AND disable `publicNetworkAccess` |
| Error if missing | Firewall blocks connection | `DenyPublicEndpointEnabled` error on rule add |

## GitHub Actions Environment Variable Scoping

**Critical gotcha:** Job-level `if:` conditions are evaluated **before** the `environment:` block is loaded.
This means environment-scoped variables and secrets are **not available** in job guards.

```yaml
# WRONG — environment-scoped var not visible in job if:
jobs:
  deploy:
    environment: production
    if: ${{ vars.AZURE_WEBAPP_NAME != '' }}  # ❌ always empty — env not loaded yet
```

```yaml
# CORRECT — use repo-level variable for the guard
jobs:
  deploy:
    environment: production
    if: ${{ vars.AZURE_WEBAPP_NAME != '' }}  # ✅ works if set at REPO level (not env level)
```

**Rule:** Any variable used in a job-level `if:` guard must be set at **repository level**, not
only in the environment. Set it in both places: repo level for the guard, environment level for
the value used during execution.

## Review Lens

- Is the firewall remove step protected with `if: always()`?
- Are firewall add and remove in the same job?
- Does the workflow check `defaultAction` before modifying firewall rules?
- Is the remove step tolerant of already-removed IPs (`|| true`)?
- For Azure SQL: is `publicNetworkAccess=Enabled` set **before** the firewall rule add?
- For Azure SQL: does cleanup restore `publicNetworkAccess=Disabled`?
- Are job guard variables set at repo level (not just environment level)?
