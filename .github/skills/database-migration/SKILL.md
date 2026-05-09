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
