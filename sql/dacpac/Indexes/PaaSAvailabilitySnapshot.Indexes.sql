-- Service + capturedAt for latest-snapshot queries
CREATE NONCLUSTERED INDEX [IX_PaaSAvailabilitySnapshot_ServiceCaptured]
    ON [dbo].[PaaSAvailabilitySnapshot] ([requestedService] ASC, [capturedAtUtc] DESC, [service] ASC, [region] ASC);
