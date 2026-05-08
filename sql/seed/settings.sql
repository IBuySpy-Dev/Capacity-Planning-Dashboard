-- Idempotent seed data for DashboardSetting defaults.
-- Uses MERGE so it is safe to re-run at any time without duplicating rows.

MERGE [dbo].[DashboardSetting] AS [target]
USING (VALUES
    ('schedule.aiModelCatalog.intervalMinutes', '1440'),
    ('ingest.openai.enabled',                   'false'),
    ('ingest.ai.enabled',                        'false'),
    ('ingest.ai.providerQuota.enabled',          'false'),
    ('ingest.openai.modelCatalog.enabled',        'true'),
    ('ingest.ai.modelCatalog.enabled',            'true'),
    ('ui.showSqlPreview',                         'true')
) AS [source] ([settingKey], [settingValue])
ON [target].[settingKey] = [source].[settingKey]
-- Insert missing defaults; do NOT overwrite values that have been changed by operators.
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([settingKey], [settingValue], [updatedAtUtc])
    VALUES ([source].[settingKey], [source].[settingValue], SYSUTCDATETIME());
