-- For listing errors by recency, source, and severity
CREATE NONCLUSTERED INDEX [IX_DashboardErrorLog_OccurredAt]
    ON [dbo].[DashboardErrorLog] ([occurredAtUtc] DESC, [errorSource] ASC, [severity] ASC);
GO

-- Filtered index for unresolved errors only (common admin panel query)
CREATE NONCLUSTERED INDEX [IX_DashboardErrorLog_Unresolved]
    ON [dbo].[DashboardErrorLog] ([isResolved] ASC, [occurredAtUtc] DESC)
    WHERE ([isResolved] = 0);
