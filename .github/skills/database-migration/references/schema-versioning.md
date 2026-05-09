# Schema Versioning with Flyway

## Project Structure

```
migrations/
├── sql/
│   ├── V1__initial_schema.sql
│   ├── V4__migrate_email.sql
│   └── U4__rollback_email_migration.sql
└── flyway.conf
```

## Migration File Format

Naming: `V{version}__{description}.sql` | Rollback: `U{version}__{description}.sql`

```sql
-- V4__migrate_email_to_normalized.sql
ALTER TABLE users ADD COLUMN email_normalized VARCHAR(255);
CREATE INDEX idx_users_email_normalized ON users(email_normalized);
INSERT INTO migration_log (version, step, status)
VALUES (4, 'expand_email_normalized', 'COMPLETED');
```

```sql
-- U4__rollback_email_migration.sql
ALTER TABLE users DROP COLUMN email_normalized;
DROP INDEX idx_users_email_normalized ON users;
DELETE FROM migration_log WHERE version = 4;
```

## Flyway Commands

```bash
flyway info      # Check current schema version
flyway validate  # Validate migrations
flyway migrate   # Run pending migrations
flyway undo      # Rollback to previous version
```

## CI/CD Integration

```yaml
# .github/workflows/db-migrate.yml
name: Database Migration
on:
  push:
    branches: [main]
    paths: ['migrations/**']

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Validate migrations
        run: ./flyway validate

      - name: Migrate production
        env:
          FLYWAY_URL: ${{ secrets.DB_URL }}
          FLYWAY_USER: ${{ secrets.DB_USER }}
          FLYWAY_PASSWORD: ${{ secrets.DB_PASSWORD }}
        run: ./flyway migrate

      - name: Verify
        run: sqlcmd -Q "SELECT COUNT(*) FROM migration_log"
```
