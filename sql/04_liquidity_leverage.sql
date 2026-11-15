-- =====================================================================
-- 04_liquidity_leverage.sql
-- Question: Can Apple pay its short-term bills, and how much debt does it carry?
-- =====================================================================
USE aapl_stock_project;

SELECT fiscal_year,
       ROUND(current_assets / current_liabilities, 2)               AS current_ratio,
       ROUND((current_assets - inventory) / current_liabilities, 2) AS quick_ratio,
       ROUND(total_debt / stockholders_equity, 2)                    AS debt_to_equity,
       -- Net cash = cash + all marketable securities - total debt ($ millions)
       cash_and_equivalents + marketable_securities_current
           + marketable_securities_noncurrent - total_debt          AS net_cash,
       CASE
           WHEN current_assets IS NULL THEN 'Data Unavailable'
           WHEN current_assets / current_liabilities >= 1.5 THEN 'Highly Liquid'
           WHEN current_assets / current_liabilities >= 1.0 THEN 'Adequate Liquidity'
           ELSE 'Below 1.0 (see note)'
       END AS liquidity_label
FROM balance_sheet
ORDER BY fiscal_year;

-- Interpret liquidity alongside operating cash flow, securities and payment timing.
-- Current marketable securities ARE included in current assets; non-current ones are not.
-- A low current ratio alone neither proves distress nor rules out liquidity risk.
