CREATE TABLE [dbo].[QuotaApplyRequestLog] (
    [requestLogId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [createdAtUtc]  DATETIME2 (7)  NOT NULL,
    [requestedBy]   NVARCHAR (256) NOT NULL,
    [operationId]   NVARCHAR (128) NOT NULL,
    [state]         NVARCHAR (64)  NOT NULL,
    [payloadJson]   NVARCHAR (MAX) NOT NULL,
    [resultJson]    NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_QuotaApplyRequestLog] PRIMARY KEY CLUSTERED ([requestLogId] ASC)
);
