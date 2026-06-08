/*
01_basic_checks.sql

Basic SQL Server checks for the local Docker-based learning environment.

Run this script in DataGrip after connecting to the local SQL Server container.
*/

-- Show SQL Server version
SELECT @@VERSION AS sql_server_version;
GO

-- Show current database
SELECT DB_NAME() AS current_database;
GO

-- List available databases
SELECT
    name,
    database_id,
    create_date
FROM sys.databases
ORDER BY name;
GO

-- Show current login and user context
SELECT
    SYSTEM_USER AS system_user_name,
    CURRENT_USER AS current_database_user,
    SUSER_SNAME() AS login_name;
GO

-- List user tables in the current database
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO
