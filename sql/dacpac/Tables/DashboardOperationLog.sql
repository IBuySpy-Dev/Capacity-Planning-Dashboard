CREATE TABLE [dbo].[DashboardOperationLog] (
    [operationLogId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [operationType]           NVARCHAR (64)   NOT NULL,
    [operationName]           NVARCHAR (128)  NOT NULL,
    [status]                  NVARCHAR (16)   NOT NULL,
    [triggerSource]           NVARCHAR (32)   NOT NULL,
    [startedAtUtc]            DATETIME2 (7)   NOT NULL,
    [completedAtUtc]          DATETIME2 (7)   NULL,
    [durationMs]              INT             NULL,
    [rowsAffected]            INT             NULL,
    [subscriptionCount]       INT             NULL,
    [requestedDesiredCount]   INT             NULL,
    [effectiveDesiredCount]   INT             NULL,
    [regionPreset]            NVARCHAR (64)   NULL,
    [note]                    NVARCHAR (512)  NULL,
    [errorMessage]            NVARCHAR (2048) NULL,
    CONSTRAINT [PK_DashboardOperationLog] PRIMARY KEY CLUSTERED ([operationLogId] ASC)
);
