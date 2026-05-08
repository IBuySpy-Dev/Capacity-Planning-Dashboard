-- Region + model lookup (deduplication partition key)
CREATE NONCLUSTERED INDEX [IX_AIModelAvailability_Region_Model]
    ON [dbo].[AIModelAvailability] ([region] ASC, [modelName] ASC, [capturedAtUtc] DESC);
GO

-- Provider + region + model for provider-aware queries
CREATE NONCLUSTERED INDEX [IX_AIModelAvailability_Provider_Region_Model]
    ON [dbo].[AIModelAvailability] ([provider] ASC, [region] ASC, [modelName] ASC, [modelVersion] ASC, [capturedAtUtc] DESC);
GO

-- CapturedAt for TTL and cleanup queries
CREATE NONCLUSTERED INDEX [IX_AIModelAvailability_CapturedAt]
    ON [dbo].[AIModelAvailability] ([capturedAtUtc] DESC);
