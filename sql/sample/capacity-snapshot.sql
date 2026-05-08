-- Synthetic sample data for development and demonstration purposes.
-- DO NOT run in production.
--
-- Inserts 10 representative CapacitySnapshot rows covering three Azure regions,
-- two SKU families (Ddsv5, Msv2), and a mix of availability states.

SET NOCOUNT ON;

DECLARE @capturedAt DATETIME2(7) = SYSUTCDATETIME();

INSERT INTO [dbo].[CapacitySnapshot]
    ([capturedAtUtc], [sourceType], [subscriptionKey], [subscriptionId], [subscriptionName],
     [region], [skuName], [skuFamily], [vCpu], [memoryGB], [availabilityState], [quotaCurrent], [quotaLimit])
VALUES
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'eastus',        'Standard_D4ds_v5',  'Ddsv5', 4,   16.0,   'Available',    10, 100),
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'eastus',        'Standard_D8ds_v5',  'Ddsv5', 8,   32.0,   'Available',    20, 200),
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'eastus',        'Standard_D16ds_v5', 'Ddsv5', 16,  64.0,   'Limited',       5,  50),
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'westus2',       'Standard_D4ds_v5',  'Ddsv5', 4,   16.0,   'Available',    15, 100),
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'westus2',       'Standard_D8ds_v5',  'Ddsv5', 8,   32.0,   'Constrained',   2,  50),
    (@capturedAt, 'sample-data', 'sample-sub-001', 'aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001', 'westeurope',    'Standard_D4ds_v5',  'Ddsv5', 4,   16.0,   'Available',    30, 100),
    (@capturedAt, 'sample-data', 'sample-sub-002', 'bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb', 'Sample Dev Sub 002', 'eastus',        'Standard_M8ms_v2',  'Msv2',  8,  218.75,  'Available',     4,  20),
    (@capturedAt, 'sample-data', 'sample-sub-002', 'bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb', 'Sample Dev Sub 002', 'eastus',        'Standard_M16ms_v2', 'Msv2',  16, 437.5,   'Limited',       1,  10),
    (@capturedAt, 'sample-data', 'sample-sub-002', 'bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb', 'Sample Dev Sub 002', 'westus2',       'Standard_M8ms_v2',  'Msv2',  8,  218.75,  'Constrained',   0,  10),
    (@capturedAt, 'sample-data', 'sample-sub-002', 'bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb', 'Sample Dev Sub 002', 'westeurope',    'Standard_M8ms_v2',  'Msv2',  8,  218.75,  'Available',     6,  20);

-- Companion subscription entries
MERGE [dbo].[Subscriptions] AS t
USING (VALUES
    ('aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa', 'Sample Dev Sub 001'),
    ('bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb', 'Sample Dev Sub 002')
) AS s ([subscriptionId], [subscriptionName])
ON t.[subscriptionId] = s.[subscriptionId]
WHEN NOT MATCHED THEN
    INSERT ([subscriptionId], [subscriptionName]) VALUES (s.[subscriptionId], s.[subscriptionName])
WHEN MATCHED THEN
    UPDATE SET [subscriptionName] = s.[subscriptionName], [updatedAtUtc] = GETUTCDATE();
