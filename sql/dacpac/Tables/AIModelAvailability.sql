CREATE TABLE [dbo].[AIModelAvailability] (
    [availabilityId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [capturedAtUtc]    DATETIME2 (7)  NOT NULL,
    [subscriptionId]   NVARCHAR (64)  NOT NULL,
    [region]           NVARCHAR (64)  NOT NULL,
    [provider]         NVARCHAR (128) NOT NULL CONSTRAINT [DF_AIModelAvailability_Provider] DEFAULT ('Unknown'),
    [modelName]        NVARCHAR (128) NOT NULL,
    [modelVersion]     NVARCHAR (64)  NULL,
    [deploymentTypes]  NVARCHAR (512) NULL,
    [finetuneCapable]  BIT            NOT NULL CONSTRAINT [DF_AIModelAvailability_FinetuneCapable] DEFAULT (0),
    [deprecationDate]  DATETIME2 (7)  NULL,
    [skuName]          NVARCHAR (128) NULL,
    [modelFormat]      NVARCHAR (64)  NULL,
    [isDefault]        BIT            NOT NULL CONSTRAINT [DF_AIModelAvailability_IsDefault] DEFAULT (0),
    [capabilities]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_AIModelAvailability] PRIMARY KEY CLUSTERED ([availabilityId] ASC)
);
