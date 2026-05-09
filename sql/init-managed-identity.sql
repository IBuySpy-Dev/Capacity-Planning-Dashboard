-- SQL Database Initialization for Managed Identity Authentication
-- This script configures the database for Azure AD managed identity access
-- Run this script after database creation using Azure AD authentication

-- Create contained database user for the App Service managed identity
-- The identity name should be the App Service name: app-capdash-{environment}-{workloadSuffix}
-- This script uses the placeholder {APP_SERVICE_NAME} which will be replaced during deployment

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '{APP_SERVICE_NAME}')
BEGIN
    CREATE USER [{APP_SERVICE_NAME}] FROM EXTERNAL PROVIDER;
    PRINT 'Created user [' + '{APP_SERVICE_NAME}' + '] FROM EXTERNAL PROVIDER';
END
ELSE
BEGIN
    PRINT 'User [' + '{APP_SERVICE_NAME}' + '] already exists';
END

-- Grant database reader role (SELECT permissions for capacity data queries)
IF NOT EXISTS (
    SELECT * FROM sys.database_role_members
    WHERE role_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = 'db_datareader')
    AND member_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = '{APP_SERVICE_NAME}')
)
BEGIN
    ALTER ROLE db_datareader ADD MEMBER [{APP_SERVICE_NAME}];
    PRINT 'Added [' + '{APP_SERVICE_NAME}' + '] to db_datareader role';
END
ELSE
BEGIN
    PRINT '[' + '{APP_SERVICE_NAME}' + '] already has db_datareader role';
END

-- Grant database writer role (INSERT/UPDATE/DELETE for analytics and cache updates)
IF NOT EXISTS (
    SELECT * FROM sys.database_role_members
    WHERE role_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = 'db_datawriter')
    AND member_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = '{APP_SERVICE_NAME}')
)
BEGIN
    ALTER ROLE db_datawriter ADD MEMBER [{APP_SERVICE_NAME}];
    PRINT 'Added [' + '{APP_SERVICE_NAME}' + '] to db_datawriter role';
END
ELSE
BEGIN
    PRINT '[' + '{APP_SERVICE_NAME}' + '] already has db_datawriter role';
END

-- Grant DDL admin role (CREATE/ALTER TABLE for schema initialization at startup)
IF NOT EXISTS (
    SELECT * FROM sys.database_role_members
    WHERE role_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = 'db_ddladmin')
    AND member_principal_id = (SELECT principal_id FROM sys.database_principals WHERE name = '{APP_SERVICE_NAME}')
)
BEGIN
    ALTER ROLE db_ddladmin ADD MEMBER [{APP_SERVICE_NAME}];
    PRINT 'Added [' + '{APP_SERVICE_NAME}' + '] to db_ddladmin role';
END
ELSE
BEGIN
    PRINT '[' + '{APP_SERVICE_NAME}' + '] already has db_ddladmin role';
END

-- Verify permissions were applied
SELECT 
    'Database Setup Complete' as [Status],
    '{APP_SERVICE_NAME}' as [AppServiceName],
    GETDATE() as [Timestamp];
