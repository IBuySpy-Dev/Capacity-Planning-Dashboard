-- For listing operations by recency, type, and status
CREATE NONCLUSTERED INDEX [IX_DashboardOperationLog_StartedAt]
    ON [dbo].[DashboardOperationLog] ([startedAtUtc] DESC, [operationType] ASC, [status] ASC);
