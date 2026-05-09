CREATE TABLE [dbo].[DashboardErrorLog] (
    [errorLogId]           BIGINT         IDENTITY (1, 1) NOT NULL,
    [errorSource]          NVARCHAR (64)  NOT NULL,
    [errorType]            NVARCHAR (128) NOT NULL,
    [errorMessage]         NVARCHAR (2048) NOT NULL,
    [stackTrace]           NVARCHAR (MAX) NULL,
    [occurredAtUtc]        DATETIME2 (7)  NOT NULL,
    [severity]             NVARCHAR (16)  NOT NULL,
    [context]              NVARCHAR (MAX) NULL,
    [affectedRegion]       NVARCHAR (64)  NULL,
    [affectedSku]          NVARCHAR (128) NULL,
    [affectedDesiredCount] INT            NULL,
    [isResolved]           BIT            NOT NULL CONSTRAINT [DF_DashboardErrorLog_IsResolved] DEFAULT (0),
    [resolvedAtUtc]        DATETIME2 (7)  NULL,
    [resolutionNotes]      NVARCHAR (512) NULL,
    [requestId]            NVARCHAR (36)  NULL,
    CONSTRAINT [PK_DashboardErrorLog] PRIMARY KEY CLUSTERED ([errorLogId] ASC)
);
