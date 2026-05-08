-- For capturedAtUtc DESC queries on CapacityScoreSnapshot
CREATE NONCLUSTERED INDEX [IX_CapacityScoreSnapshot_CapturedRegionSku]
    ON [dbo].[CapacityScoreSnapshot] ([capturedAtUtc] DESC, [region] ASC, [skuName] ASC);
GO

-- For region/family/sku coverage queries
CREATE NONCLUSTERED INDEX [IX_CapacityScoreSnapshot_RegionSku]
    ON [dbo].[CapacityScoreSnapshot] ([region] ASC, [skuFamily] ASC, [skuName] ASC)
    INCLUDE ([capturedAtUtc], [score], [reason], [utilizationPct])
    WITH (FILLFACTOR = 90);
