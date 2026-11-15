-- =====================================================================
-- 05_cash_returns.sql
-- Question: How much of its Free Cash Flow does Apple give back to shareholders?
-- Technique: JOIN two tables on fiscal_year
-- =====================================================================
USE aapl_stock_project;

SELECT cf.fiscal_year,
       cf.free_cash_flow,
       ROUND(cf.free_cash_flow / i.total_revenue * 100, 2)     AS fcf_margin_pct,
       -cf.dividends_paid                                      AS dividends,
       -cf.share_repurchases                                   AS buybacks,
       -(cf.dividends_paid + cf.share_repurchases)             AS total_returned,
       ROUND(-(cf.dividends_paid + cf.share_repurchases) / cf.free_cash_flow * 100, 1)
                                                               AS pct_of_fcf_returned
FROM cash_flow AS cf
JOIN income_statement AS i
  ON cf.fiscal_year = i.fiscal_year
ORDER BY cf.fiscal_year;

-- Dividends and buybacks are stored as negative numbers (cash going out),
-- so we put a minus sign in front to show them as positive amounts.
