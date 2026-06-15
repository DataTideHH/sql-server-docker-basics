/*
    03_data_quality_checks.sql

    Purpose:
    Demonstrate basic data quality checks for Data/BI workflows in Microsoft SQL Server.

    This script is intentionally self-contained.
    It uses a temporary example table so it can be run in a local SQL Server
    training environment without depending on an existing business database.

    What this demonstrates:
    - row count check
    - NULL checks
    - duplicate checks
    - simple value range checks
    - why these checks matter before reporting, dashboards or BI interpretation

    Context:
    In Data/BI work, incorrect dashboards often start with unvalidated source data.
    Before building reports, KPIs or Power BI models, basic checks help identify
    missing values, duplicates and implausible measures.
*/

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#SalesOrdersQualityDemo') IS NOT NULL
BEGIN
    DROP TABLE #SalesOrdersQualityDemo;
END;

CREATE TABLE #SalesOrdersQualityDemo
(
    order_id      INT          NOT NULL,
    customer_id   INT          NULL,
    order_date    DATE         NULL,
    product_group VARCHAR(50)  NULL,
    quantity      INT          NULL,
    net_amount    DECIMAL(10,2) NULL
);

INSERT INTO #SalesOrdersQualityDemo
    (order_id, customer_id, order_date, product_group, quantity, net_amount)
VALUES
    (1001, 501, '2026-06-01', 'Hardware', 2, 199.90),
    (1002, 502, '2026-06-01', 'Software', 1,  49.90),
    (1003, 503, '2026-06-02', 'Hardware', 5, 499.50),
    (1004, NULL, '2026-06-03', 'Services', 1, 129.00),   -- missing customer_id
    (1005, 504, NULL,         'Hardware', 3, 299.70),    -- missing order_date
    (1006, 505, '2026-06-04', NULL,       2, 159.80),    -- missing product_group
    (1007, 506, '2026-06-05', 'Software', 0,  89.90),    -- invalid quantity
    (1008, 507, '2026-06-06', 'Services', 1, -10.00),    -- invalid net_amount
    (1008, 507, '2026-06-06', 'Services', 1, -10.00);    -- duplicate order_id

PRINT 'Data quality check demo for SQL Server';
PRINT '=======================================';

-- 1. Basic row count
-- Why it matters:
-- A row count is the simplest baseline check. It helps confirm that data was loaded
-- and provides a reference point for later transformations or exports.
SELECT
    COUNT(*) AS total_rows
FROM #SalesOrdersQualityDemo;

-- 2. NULL checks for important business/reporting fields
-- Why it matters:
-- Missing keys, dates or categories can break joins, filters, aggregations and KPIs.
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS missing_order_date,
    SUM(CASE WHEN product_group IS NULL THEN 1 ELSE 0 END) AS missing_product_group,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS missing_quantity,
    SUM(CASE WHEN net_amount IS NULL THEN 1 ELSE 0 END) AS missing_net_amount
FROM #SalesOrdersQualityDemo;

-- 3. Duplicate check for a business key
-- Why it matters:
-- Duplicate business keys can inflate revenue, quantities and order counts in reports.
SELECT
    order_id,
    COUNT(*) AS row_count
FROM #SalesOrdersQualityDemo
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. Simple value range checks
-- Why it matters:
-- Implausible quantities or negative values can distort KPI calculations and visualizations.
SELECT
    order_id,
    customer_id,
    order_date,
    product_group,
    quantity,
    net_amount,
    CASE
        WHEN quantity IS NULL THEN 'missing quantity'
        WHEN quantity <= 0 THEN 'quantity must be greater than zero'
        WHEN quantity > 1000 THEN 'quantity unusually high'
        WHEN net_amount IS NULL THEN 'missing net amount'
        WHEN net_amount < 0 THEN 'net amount must not be negative'
        ELSE 'ok'
    END AS quality_flag
FROM #SalesOrdersQualityDemo
WHERE
    quantity IS NULL
    OR quantity <= 0
    OR quantity > 1000
    OR net_amount IS NULL
    OR net_amount < 0;

-- 5. Compact quality summary for BI/reporting preparation
-- Why it matters:
-- A compact summary can be used as a checklist before building reports or dashboards.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_order_id_rows,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS missing_customer_id_rows,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS missing_order_date_rows,
    SUM(CASE WHEN product_group IS NULL THEN 1 ELSE 0 END) AS missing_product_group_rows,
    SUM(CASE WHEN quantity IS NULL OR quantity <= 0 THEN 1 ELSE 0 END) AS invalid_quantity_rows,
    SUM(CASE WHEN net_amount IS NULL OR net_amount < 0 THEN 1 ELSE 0 END) AS invalid_net_amount_rows
FROM #SalesOrdersQualityDemo;

DROP TABLE #SalesOrdersQualityDemo;
