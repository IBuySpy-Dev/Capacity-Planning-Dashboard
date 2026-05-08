CREATE TABLE [dbo].[DashboardSetting] (
    [settingKey]   NVARCHAR (128) NOT NULL,
    [settingValue] NVARCHAR (MAX) NOT NULL,
    [updatedAtUtc] DATETIME2 (7)  NOT NULL CONSTRAINT [DF_DashboardSetting_UpdatedAtUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_DashboardSetting] PRIMARY KEY CLUSTERED ([settingKey] ASC)
);
