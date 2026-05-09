CREATE TABLE [dbo].[VmSkuCatalog] (
    [skuFamily]    NVARCHAR (128)  NOT NULL,
    [skuName]      NVARCHAR (128)  NOT NULL,
    [vCpu]         INT             NULL,
    [memoryGB]     DECIMAL (10, 2) NULL,
    [firstSeenUtc] DATETIME2 (7)   NOT NULL CONSTRAINT [DF_VmSkuCatalog_FirstSeenUtc] DEFAULT SYSUTCDATETIME(),
    [lastSeenUtc]  DATETIME2 (7)   NOT NULL CONSTRAINT [DF_VmSkuCatalog_LastSeenUtc] DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_VmSkuCatalog] PRIMARY KEY CLUSTERED ([skuFamily] ASC, [skuName] ASC)
);
