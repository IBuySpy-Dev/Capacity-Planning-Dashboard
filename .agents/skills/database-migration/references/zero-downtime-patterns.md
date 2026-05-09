# Zero-Downtime Migration Patterns

## Expand-Contract Pattern

Separates schema changes from data migration to ensure zero downtime.

**Phase 1: Expand** — Add new infrastructure without removing old

```sql
ALTER TABLE users ADD COLUMN email_normalized VARCHAR(255);
UPDATE users SET email_normalized = LOWER(email) WHERE email_normalized IS NULL LIMIT 10000;
```

**Phase 2: Migrate** — Switch application to new schema

```sql
UPDATE users SET email_normalized = LOWER(email) WHERE email_normalized IS NULL;
-- Deploy application: reads/writes from new column only
-- Monitor for 24-48 hours
```

**Phase 3: Contract** — Remove old schema

```sql
ALTER TABLE users DROP COLUMN email;
```

| Property | Value |
|----------|-------|
| Downtime | **Zero** |
| Rollback | Simple (revert code, keep old column) |
| Duration | Hours to days |
| Tools | Flyway, Liquibase, custom scripts |

## Blue-Green Database Deployments

Run two identical database instances; switch traffic after validation.

```
┌──────────────┐         ┌──────────────┐
│  Blue DB     │         │  Green DB    │
│  (Current)   │         │  (Staging)   │
│ v4 Schema    │         │  v5 Schema   │
└──────────────┘         └──────────────┘
     100% traffic             0% traffic
```

### Cutover Steps

1. Provision Green (identical to Blue)
2. Restore backup to Green + apply migrations
3. Validate against Green (row counts, data integrity, performance)
4. Redirect traffic to Green
5. Monitor 24-48 hours
6. Keep Blue as rollback target for 30 days
7. Decommission Blue

### Cost Optimization

```
Week 1-2: Both instances (full cost)
Week 3-4: Scale Blue down to minimal SKU (~$5/day)
After:    Decommission Blue
```

## Rollback Strategies

### Point-in-Time Restore (Fast)

```sql
RESTORE DATABASE appdb FROM BACKUP appdb_v4.bak WITH RECOVERY
```

**Pros**: Fast (minutes) | **Cons**: Loses transactions during migration | **Best for**: Small windows (<1 hour)

### Dual-Write Fallback

```python
def query(sql):
    try:
        return self.primary.execute(sql)
    except:
        logger.warn("Primary failed, using fallback")
        return self.fallback.execute(sql)
```

**Pros**: Zero data loss | **Cons**: Complexity | **Best for**: High-reliability systems

### Feature Flag + Canary

```
100% → v5 (deployment day)
 75% → v5, 25% → v4 (hour 1)
 50% → v5, 50% → v4 (hour 2)
  0% → v5, 100% → v4 (rollback complete)
```
