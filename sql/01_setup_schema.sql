-- =====================================================================
-- 01_setup_schema.sql
-- Run AFTER notebooks/01_data_collection.ipynb has pushed the tables.
-- Purpose: clean up column types and check that every table loaded.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS aapl_stock_project;
USE aapl_stock_project;

-- pandas saves dates as DATETIME; the time part (00:00:00) is not needed
ALTER TABLE price_data MODIFY `date` DATE;

-- Row count check for every table (UNION ALL stacks the results)
SELECT 'income_statement'   AS table_name, COUNT(*) AS row_count FROM income_statement
UNION ALL
SELECT 'balance_sheet',       COUNT(*) FROM balance_sheet
UNION ALL
SELECT 'cash_flow',           COUNT(*) FROM cash_flow
UNION ALL
SELECT 'revenue_by_product',  COUNT(*) FROM revenue_by_product
UNION ALL
SELECT 'price_data',          COUNT(*) FROM price_data;
-- Expected: 5 rows for each statement (FY2022-FY2026), 25 rows for products,
-- and ~2,970 trading days x 5 tickers for price_data.

-- Data check: Total Assets = Total Liabilities + Equity (difference should be 0)
SELECT fiscal_year,
       total_assets - (total_liabilities + stockholders_equity) AS difference
FROM balance_sheet
ORDER BY fiscal_year;
