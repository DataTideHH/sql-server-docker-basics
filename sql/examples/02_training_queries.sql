/*
02_training_queries.sql

Simple SQL Server query patterns for learning and portfolio documentation.

These examples are intentionally generic. Adapt table and column names to the
training database you are currently using.
*/

-- 1. Inspect all user tables in the current database
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;
GO

-- 2. Inspect columns for all user tables
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;
GO

-- 3. Count rows per user table using dynamic SQL helper output
SELECT
    'SELECT '''
    + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    + ''' AS table_name, COUNT(*) AS row_count FROM '
    + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    + ';' AS generated_count_query
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
GO

-- 4. Example pattern: select the first rows from a table
-- Replace dbo.ExampleTable with an existing table in your training database.

-- SELECT TOP (10)
--     *
-- FROM dbo.ExampleTable;
-- GO

-- 5. Example pattern: grouped aggregation
-- Replace table and column names with real training database objects.

-- SELECT
--     CategoryColumn,
--     COUNT(*) AS row_count
-- FROM dbo.ExampleTable
-- GROUP BY CategoryColumn
-- ORDER BY row_count DESC;
-- GO

-- 6. Example pattern: simple join
-- Replace table and key names with real training database objects.

-- SELECT TOP (20)
--     a.PrimaryKeyColumn,
--     a.SomeValue,
--     b.RelatedValue
-- FROM dbo.TableA AS a
-- JOIN dbo.TableB AS b
--     ON a.ForeignKeyColumn = b.PrimaryKeyColumn
-- ORDER BY a.PrimaryKeyColumn;
-- GO
