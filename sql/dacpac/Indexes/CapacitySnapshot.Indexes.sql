-- Covering index for grid filtering by region, family, availability
CREATE NONCLUSTERED INDEX [IX_CapacitySnapshot_RegionFamilyAvailability]
    ON [dbo].[CapacitySnapshot] ([region] ASC, [skuFamily] ASC, [availabilityState] ASC)
    INCLUDE ([capturedAtUtc], [subscriptionId], [subscriptionName], [skuName], [quotaCurrent], [quotaLimit], [vCpu], [memoryGB], [zonesCsv], [subscriptionKey])
    WITH (FILLFACTOR = 90);
GO

-- Latest-first sort
CREATE NONCLUSTERED INDEX [IX_CapacitySnapshot_CapturedAtDesc]
    ON [dbo].[CapacitySnapshot] ([capturedAtUtc] DESC)
    INCLUDE ([region], [skuFamily], [skuName], [subscriptionId], [subscriptionName], [quotaCurrent], [quotaLimit])
    WITH (FILLFACTOR = 90);
GO

-- Subscription-filtered queries
CREATE NONCLUSTERED INDEX [IX_CapacitySnapshot_SubscriptionId]
    ON [dbo].[CapacitySnapshot] ([subscriptionId] ASC)
    INCLUDE ([region], [skuFamily], [skuName], [availabilityState], [quotaCurrent], [quotaLimit], [capturedAtUtc])
    WITH (FILLFACTOR = 90);
GO

-- Family summary queries
CREATE NONCLUSTERED INDEX [IX_CapacitySnapshot_FamilyRegion]
    ON [dbo].[CapacitySnapshot] ([skuFamily] ASC, [region] ASC)
    INCLUDE ([quotaCurrent], [quotaLimit], [subscriptionId], [subscriptionName], [capturedAtUtc])
    WITH (FILLFACTOR = 90);
