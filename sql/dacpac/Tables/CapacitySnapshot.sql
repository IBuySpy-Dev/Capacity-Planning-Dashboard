CREATE TABLE [dbo].[CapacitySnapshot] (
    [snapshotId]          BIGINT           IDENTITY (1, 1) NOT NULL,
    [capturedAtUtc]       DATETIME2 (7)    NOT NULL,
    [sourceType]          NVARCHAR (50)    NOT NULL,
    [subscriptionKey]     NVARCHAR (64)    NULL,
    [subscriptionId]      NVARCHAR (64)    NULL,
    [subscriptionName]    NVARCHAR (256)   NULL,
    [region]              NVARCHAR (64)    NOT NULL,
    [skuName]             NVARCHAR (128)   NOT NULL,
    [skuFamily]           NVARCHAR (128)   NOT NULL,
    [vCpu]                INT              NULL,
    [memoryGB]            DECIMAL (10, 2)  NULL,
    [zonesCsv]            NVARCHAR (256)   NULL,
    [availabilityState]   NVARCHAR (32)    NOT NULL,
    [quotaCurrent]        INT              NOT NULL,
    [quotaLimit]          INT              NOT NULL,
    [monthlyCostEstimate] DECIMAL (18, 2)  NULL,
    CONSTRAINT [PK_CapacitySnapshot] PRIMARY KEY CLUSTERED ([snapshotId] ASC)
);
