---
name: database-migration
description: Zero-downtime database migration patterns, blue-green deployments, rollback strategies, and schema versioning for production systems
compatibility: "Requires database access tools. Works with VS Code, CLI, and Copilot Coding Agent."
metadata:
  category: "data"
  keywords: "database, migration, flyway, liquibase, zero-downtime, blue-green"
  model-tier: "standard"
allowed-tools: "search/codebase bash sql"
---

# Database Migration

Zero-downtime database migration patterns, schema versioning, and rollback strategies for
production systems.

## Quick Start

1. Use the **expand-contract** pattern for all schema changes — never drop columns in the same
   deploy that stops writing to them.
2. Version migrations with Flyway (`V{n}__{desc}.sql`) and always write a matching undo script.
3. Validate migrations against staging at production data volume before touching production.
4. Keep Blue as rollback target for ≥30 days after a blue-green cutover.
5. Run `flyway validate` in CI before every `flyway migrate`.

## Reference Files

| File | Contents |
|------|----------|
| [`references/zero-downtime-patterns.md`](references/zero-downtime-patterns.md) | Expand-contract phases, blue-green cutover steps, rollback strategies (PITR, dual-write, canary) |
| [`references/schema-versioning.md`](references/schema-versioning.md) | Flyway project structure, migration file format, rollback scripts, CI/CD integration YAML |
| [`references/operations-checklist.md`](references/operations-checklist.md) | Pre-migration checklist, monitoring metrics, long-running transaction query |

## Key Patterns

- **Expand-contract**: Add column → migrate data → remove old column across 3 separate deploys
- **Blue-green**: Two identical DB instances; switch traffic after 24–48 h validation
- **Dual-write fallback**: Write to both DBs; reads from primary; zero data loss rollback
- **Flyway undo**: `U{version}__rollback.sql` paired with every `V{version}__migrate.sql`

## Entra-Only SQL Authentication

Use Microsoft Entra ID (formerly Azure AD) as the sole authentication mechanism for
Azure SQL — no SQL logins, no passwords.

### Create an Entra user from external provider

Run this in the target database while connected as an Entra admin:

```sql
CREATE USER [username-or-spn-display-name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [username-or-spn-display-name];
ALTER ROLE db_datawriter ADD MEMBER [username-or-spn-display-name];
```

The `FROM EXTERNAL PROVIDER` clause resolves the identity via SID lookup against
Entra ID. The display name must match the Entra object (user UPN or service
principal display name) exactly.

### Managed identity connection string

No password. Set `Authentication=Active Directory Managed Identity` and omit `Password`:

```text
Server=<server>.database.windows.net;Database=<db>;
Authentication=Active Directory Managed Identity;
User Id=<client-id-of-user-assigned-identity>;
```

For system-assigned managed identity, omit `User Id`:

```text
Server=<server>.database.windows.net;Database=<db>;
Authentication=Active Directory Managed Identity;
```

### Service principal vs managed identity

| Criterion | Service principal | Managed identity |
|-----------|------------------|-----------------|
| Secret rotation | Required (client secret or cert) | None — platform-managed |
| Scope | Cross-tenant, external CI/CD | Same Azure tenant only |
| Best for | GitHub Actions, external pipelines | App Service, AKS workloads, Azure Functions |
| Overhead | Secret lifecycle management | Zero credential overhead |

Prefer managed identity for any workload running inside Azure.
Use a service principal only when the caller is outside Azure (e.g., a developer
laptop, an on-premises pipeline, or a third-party SaaS).

### Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Principal '…' could not be found` | SID not yet propagated from Entra to SQL | Wait 1–2 minutes after creating the Entra object; retry `CREATE USER` |
| `Login failed for user '<token-identified principal>'` | Entra admin not set on the SQL server | Set an Entra admin: `az sql server ad-admin create …` |
| `Cannot open server … requested by the login` | Client IP not in SQL firewall rules | Add the caller's IP or allow Azure services: `az sql server firewall-rule create --start-ip 0.0.0.0 --end-ip 0.0.0.0` |
| `AADSTS700016: Application not found` | Wrong client ID or app not in the correct tenant | Verify `User Id` matches the managed identity client ID, not the object ID |
