CREATE VIEW [dbo].[AIModelAvailabilityLatest]
AS
    WITH Ranked AS (
        SELECT
            capturedAtUtc,
            subscriptionId,
            region,
            provider,
            modelName,
            modelVersion,
            deploymentTypes,
            finetuneCapable,
            deprecationDate,
            skuName,
            modelFormat,
            isDefault,
            capabilities,
            ROW_NUMBER() OVER (
                PARTITION BY region, provider, modelName, modelVersion
                ORDER BY capturedAtUtc DESC
            ) AS rn
        FROM dbo.AIModelAvailability
    )
    SELECT
        capturedAtUtc,
        subscriptionId,
        region,
        provider,
        modelName,
        modelVersion,
        deploymentTypes,
        finetuneCapable,
        deprecationDate,
        skuName,
        modelFormat,
        isDefault,
        capabilities
    FROM Ranked
    WHERE rn = 1;
