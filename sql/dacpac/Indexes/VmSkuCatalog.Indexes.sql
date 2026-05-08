-- SKU catalog lookup by family
CREATE NONCLUSTERED INDEX [IX_VmSkuCatalog_Family]
    ON [dbo].[VmSkuCatalog] ([skuFamily] ASC, [skuName] ASC);
