CREATE TABLE [dbo].[CapacityScoreSnapshot] (
    [scoreSnapshotId]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [capturedAtUtc]              DATETIME2 (7)  NOT NULL,
    [region]                     NVARCHAR (64)  NOT NULL,
    [skuName]                    NVARCHAR (128) NOT NULL,
    [skuFamily]                  NVARCHAR (128) NOT NULL,
    [subscriptionCount]          INT            NOT NULL,
    [okRows]                     INT            NOT NULL,
    [limitedRows]                INT            NOT NULL,
    [constrainedRows]            INT            NOT NULL,
    [totalQuotaAvailable]        INT            NOT NULL,
    [utilizationPct]             INT            NOT NULL,
    [score]                      NVARCHAR (16)  NOT NULL,
    [reason]                     NVARCHAR (512) NOT NULL,
    [latestSourceCapturedAtUtc]  DATETIME2 (7)  NULL,
    CONSTRAINT [PK_CapacityScoreSnapshot] PRIMARY KEY CLUSTERED ([scoreSnapshotId] ASC)
);
