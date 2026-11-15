-- =====================================================================
-- 03_margin_trend.sql
-- Question: Is Apple becoming more or less profitable each year?
-- A fixed scale ("margin > 25% = strong") is useless for Apple because it is
-- always above it, so we classify the CHANGE in operating margin instead.
-- Technique: 2 CTEs + LAG() + CASE WHEN
-- =====================================================================
USE aapl_stock_project;

WITH margins AS (
    SELECT fiscal_year,
           ROUND(gross_profit     / total_revenue * 100, 2) AS gross_margin_pct,
           ROUND(operating_income / total_revenue * 100, 2) AS operating_margin_pct,
           ROUND(net_income       / total_revenue * 100, 2) AS net_margin_pct
    FROM income_statement
),
margin_change AS (
    SELECT *,
           LAG(operating_margin_pct) OVER (ORDER BY fiscal_year) AS prev_operating_margin
    FROM margins
)
SELECT fiscal_year,
       gross_margin_pct,
       operating_margin_pct,
       net_margin_pct,
       ROUND(operating_margin_pct - prev_operating_margin, 2) AS margin_gap,
       CASE
           WHEN prev_operating_margin IS NULL THEN 'Insufficient Data'      -- NULL check goes first
           WHEN operating_margin_pct - prev_operating_margin > 1 THEN 'Improving Efficiency'
           WHEN operating_margin_pct - prev_operating_margin BETWEEN -1 AND 1 THEN 'Stable'
           ELSE 'Margin Compression'
       END AS margin_trend
FROM margin_change
ORDER BY fiscal_year;
