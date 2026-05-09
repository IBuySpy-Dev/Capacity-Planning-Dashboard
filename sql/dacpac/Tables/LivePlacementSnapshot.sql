CREATE TABLE [dbo].[LivePlacementSnapshot] (
    [livePlacementSnapshotId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [capturedAtUtc]           DATETIME2 (7)  NOT NULL,
    [desiredCount]            INT            NOT NULL,
    [region]                  NVARCHAR (64)  NOT NULL,
    [skuName]                 NVARCHAR (128) NOT NULL,
    [livePlacementScore]      NVARCHAR (64)  NOT NULL,
    [livePlacementAvailable]  BIT            NULL,
    [livePlacementRestricted] BIT            NULL,
    [warningMessage]          NVARCHAR (512) NULL,
    CONSTRAINT [PK_LivePlacementSnapshot] PRIMARY KEY CLUSTERED ([livePlacementSnapshotId] ASC)
);
