-- =====================================================================
-- 07_price_vs_earnings.sql
-- Question: Is the stock price rising faster than earnings? (P/E expansion)
-- Problem: price_data is DAILY but income_statement is YEARLY.
-- Solution: group the daily prices into Apple fiscal years first, then JOIN.
-- Apple's fiscal year ends in late September, so October-December belong
-- to the NEXT fiscal year (e.g. Nov 2025 = FY2026).
-- =====================================================================
USE aapl_stock_project;

WITH yearly_price AS (
    SELECT YEAR(`date`) + CASE WHEN MONTH(`date`) >= 10 THEN 1 ELSE 0 END AS fiscal_year,
           ROUND(AVG(`close`), 2) AS avg_close
    FROM price_data
    WHERE ticker = 'AAPL'
    GROUP BY fiscal_year
)
SELECT p.fiscal_year,
       p.avg_close,
       i.diluted_eps,
       ROUND(p.avg_close / i.diluted_eps, 1) AS avg_pe_ratio
FROM yearly_price AS p
JOIN income_statement AS i
  ON p.fiscal_year = i.fiscal_year
ORDER BY p.fiscal_year;

-- Bonus: annual return of each ticker (last close of the calendar year vs first close)
WITH ranked AS (
    SELECT ticker, YEAR(`date`) AS yr, `close`,
           ROW_NUMBER() OVER (PARTITION BY ticker, YEAR(`date`) ORDER BY `date` ASC)  AS first_day,
           ROW_NUMBER() OVER (PARTITION BY ticker, YEAR(`date`) ORDER BY `date` DESC) AS last_day
    FROM price_data
)
SELECT ticker, yr,
       ROUND((MAX(CASE WHEN last_day = 1 THEN `close` END)
            / MAX(CASE WHEN first_day = 1 THEN `close` END) - 1) * 100, 1) AS annual_return_pct
FROM ranked
GROUP BY ticker, yr
ORDER BY yr, ticker;
