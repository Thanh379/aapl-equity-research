-- =====================================================================
-- 06_product_mix.sql
-- Question: Which products drive revenue, and is the mix shifting to Services?
-- Technique: SUM() OVER (PARTITION BY ...) to get each year's total on every row
-- =====================================================================
USE aapl_stock_project;

SELECT fiscal_year,
       product,
       revenue,
       ROUND(revenue / SUM(revenue) OVER (PARTITION BY fiscal_year) * 100, 1) AS share_of_revenue_pct,
       ROUND((revenue - LAG(revenue) OVER (PARTITION BY product ORDER BY fiscal_year))
             / LAG(revenue) OVER (PARTITION BY product ORDER BY fiscal_year) * 100, 1) AS yoy_growth_pct
FROM revenue_by_product
ORDER BY fiscal_year, revenue DESC;
