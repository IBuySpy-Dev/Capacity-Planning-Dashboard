-- For querying live placement results by desired count, captured time, region, and SKU
CREATE NONCLUSTERED INDEX [IX_LivePlacementSnapshot_DesiredCapturedRegionSku]
    ON [dbo].[LivePlacementSnapshot] ([desiredCount] ASC, [capturedAtUtc] DESC, [region] ASC, [skuName] ASC);
