CREATE TABLE [dbo].[Subscriptions] (
    [subscriptionId]   NVARCHAR (64)  NOT NULL,
    [subscriptionName] NVARCHAR (256) NOT NULL,
    [updatedAtUtc]     DATETIME2 (7)  NOT NULL CONSTRAINT [DF_Subscriptions_UpdatedAtUtc] DEFAULT GETUTCDATE(),
    CONSTRAINT [PK_Subscriptions] PRIMARY KEY CLUSTERED ([subscriptionId] ASC)
);
