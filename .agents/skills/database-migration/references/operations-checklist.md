# Migration Operations Checklist & Monitoring

## Pre-Migration Checklist

- [ ] Backup production database
- [ ] Test on staging (same data volume)
- [ ] Calculate duration (backfill + testing)
- [ ] Schedule during low-traffic window
- [ ] Disable auto-scaling during migration
- [ ] Have DBA on-call for rollback
- [ ] Document rollback procedure
- [ ] Prepare status communication template

## Monitoring During Migration

| Metric | Target | Tool |
|--------|--------|------|
| Connection pool utilization | <80% | APM |
| Query latency (p95) | <200ms | Azure Monitor |
| Lock wait time | <1s | sys.dm_exec_requests |
| Transaction log usage | <80% | SQL Server DMV |

## Query: Monitor Long-Running Transactions

```sql
SELECT
    session_id, command, status,
    DATEDIFF(SECOND, start_time, GETUTCDATE()) AS duration_seconds,
    percent_complete
FROM sys.dm_exec_requests
WHERE status = 'running'
ORDER BY start_time;
```

## References

- Flyway: <https://flywaydb.org/>
- Liquibase: <https://www.liquibase.org/>
- Blue-Green Deployments: <https://martinfowler.com/bliki/BlueGreenDeployment.html>
