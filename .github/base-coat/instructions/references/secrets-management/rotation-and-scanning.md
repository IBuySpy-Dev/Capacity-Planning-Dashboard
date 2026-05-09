# Secret Rotation and Expiry Scanning

## Rotation Policies

| Secret Type | Frequency | Trigger | Automation |
|---|---|---|---|
| API Keys | 90 days | Scheduled + on request | High (Vault native) |
| Database Passwords | 60 days | Scheduled | High (Vault rotation templates) |
| OAuth/JWT Tokens | 30 days | Before expiry | Automatic (built-in TTL) |
| TLS Certificates | 365 days | Day 30 before expiry | Medium (cert automation) |
| SSH Keys | 180 days | Scheduled | Manual (requires rollover) |
| Container Registry Tokens | 30 days | Scheduled | High (registry-native) |

## Rotation Workflow

```text
1. SCHEDULE
   - Calendar reminder 7 days before rotation due
   - Automated trigger at scheduled time

2. GENERATE NEW SECRET
   - Create new secret in Vault
   - Maintain N+1 versions (old still active, new ready)

3. DEPLOY NEW SECRET
   - Stage new secret in production infrastructure
   - Validate new secret works (health checks)
   - Monitor for errors

4. RETIRE OLD SECRET
   - After verification, disable old secret in Vault
   - Monitor for stale connections (will fail and reconnect)
   - After 24-hour grace period, delete old secret

5. DOCUMENT
   - Record rotation timestamp in audit log
   - Notify stakeholders if high-risk secret rotated
   - Update runbook if manual steps were required
```

## Vault Automation (Terraform)

```hcl
resource "vault_generic_secret" "db_password" {
  path = "secret/database/prod"
  data_json = jsonencode({
    username = "dbuser"
    password = random_password.db_password.result
  })
}

resource "vault_pki_secret_backend_role" "db_rotation" {
  backend         = vault_pki_secret_backend.pki.path
  name            = "database-rotation"
  max_ttl         = "2160h" # 90 days
  generate_lease  = true
  rotation_period = "1440h" # 60 days
}
```

## Daily Expiry Scanning

Run these checks daily (cron or CI scheduled job):

```bash
# 1. Vault secret expiry
vault list secret/
vault read secret/my-api-key | grep lease_duration

# 2. TLS certificate expiry
openssl s_client -connect api.example.com:443 \
  -servername api.example.com 2>/dev/null | \
  openssl x509 -noout -dates

# 3. Dependency vulnerability scan
trivy image --severity HIGH,CRITICAL myimage:latest

# 4. GitHub/GitLab secret list review
gh secret list --repo owner/repo
```

## Alert Thresholds

| Condition | Severity | Action |
|---|---|---|
| Certificate expires in 30 days | Warning | Schedule rotation |
| Certificate expires in 7 days | Alert | Immediate rotation |
| Certificate expires in 1 day | Critical | Emergency rotation |
| Secret access denied (revoked) | Critical | Investigate immediately |
| Secret last rotated > policy age | Warning | Trigger rotation |

## Rotation Runbook (Manual SSH Key Rollover)

1. Generate new key pair: `ssh-keygen -t ed25519 -f new_key`
2. Add `new_key.pub` to all authorized_keys files on target hosts
3. Update Vault/secrets store with new private key
4. Update all services that use the old key to reference the new key
5. Verify connectivity with new key from all consumers
6. Remove old `authorized_keys` entry from all target hosts
7. Delete old private key from Vault after 24-hour grace period
8. Log rotation in audit trail
