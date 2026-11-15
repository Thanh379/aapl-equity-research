-- =====================================================================
-- 02_growth_analysis.sql
-- Question: How fast are Apple's revenue, net income and EPS growing?
-- Technique: CTE + LAG() window function
-- =====================================================================
USE aapl_stock_project;

WITH growth AS (
    SELECT fiscal_year,
           total_revenue,
           net_income,
           diluted_eps,
           LAG(total_revenue) OVER (ORDER BY fiscal_year) AS prev_revenue,
           LAG(net_income)    OVER (ORDER BY fiscal_year) AS prev_net_income,
           LAG(diluted_eps)   OVER (ORDER BY fiscal_year) AS prev_eps
    FROM income_statement
)
SELECT fiscal_year,
       total_revenue,
       ROUND((total_revenue - prev_revenue) / prev_revenue * 100, 2) AS revenue_growth_pct,
       net_income,
       ROUND((net_income - prev_net_income) / prev_net_income * 100, 2) AS net_income_growth_pct,
       diluted_eps,
       ROUND((diluted_eps - prev_eps) / prev_eps * 100, 2) AS eps_growth_pct
FROM growth
ORDER BY fiscal_year;

-- Insight: EPS grows faster than net income because buybacks shrink the share count
-- (16.3B diluted shares in FY2022 -> 14.7B in FY2026).
