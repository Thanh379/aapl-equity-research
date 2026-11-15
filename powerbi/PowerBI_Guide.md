# Power BI Dashboard – Guide

`AAPL_Dashboard.pbix` is ready to open. The same report is also saved as a **Power BI Project**
(`AAPL_Dashboard.pbip` + the `.Report` / `.SemanticModel` folders) – plain-text files, so every
measure and visual can be reviewed on GitHub.

## 1. Open and refresh

1. Open `AAPL_Dashboard.pbix` in Power BI Desktop
2. **Home → Transform data → Edit parameters** → set `ProjectFolder` to your copy of the repo,
   ending with a backslash, e.g. `C:\Users\you\Documents\aapl-equity-research\`
3. **Home → Refresh**

The price chart reads the bundled `data/raw/price_data_long.csv` snapshot. Notebook 01 can intentionally refresh that file when `REFRESH_DATA = True`.

## 2. Data model

| Table | Source | Role |
|---|---|---|
| `income_statement`, `balance_sheet`, `cash_flow` | `data/*.csv` | 10-K data, FY2022–FY2026 ($ millions) |
| `revenue_by_product` | `data/revenue_by_product.csv` | Product mix (long format) |
| `peer_comps` | `data/peer_comps.csv` | AAPL vs MSFT, GOOGL, META multiples |
| `price_data` | `data/raw/price_data_long.csv` | Daily prices from yfinance |
| `valuation_summary`, `valuation_methods` | `powerbi/valuation_summary.csv` | Model outputs (DCF, Comps, target) |
| `dcf_projection` | `powerbi/dcf_projection.csv` | DCF revenue / FCF, 2026A–2031E |
| `_Measures` | – | All DAX measures |

Relationships: `cash_flow`, `balance_sheet` and `revenue_by_product` → `income_statement` on `fiscal_year`
(many-to-one, single direction). `fiscal_year` is a **Text** column so it shows as "2026", not "2,026".

## 3. Key DAX measures

```DAX
Revenue ($B)        = SUM(income_statement[total_revenue]) / 1000
Operating Margin    = DIVIDE(SUM(income_statement[operating_income]), SUM(income_statement[total_revenue]))
FCF Margin          = DIVIDE(SUM(cash_flow[free_cash_flow]), SUM(income_statement[total_revenue]))
Cash Returned ($B)  = -(SUM(cash_flow[dividends_paid]) + SUM(cash_flow[share_repurchases])) / 1000
FY2026 Revenue ($B) = CALCULATE([Revenue ($B)], income_statement[fiscal_year] = "2026")
Target Price        = CALCULATE(MAX(valuation_summary[value]), valuation_summary[metric] = "Target price")
Upside              = DIVIDE([Target Price], [Market Price]) - 1
Rating              = SWITCH(TRUE(), [Upside] > 0.15, "BUY", [Upside] < -0.15, "SELL", "HOLD")
AAPL Close          = CALCULATE(AVERAGE(price_data[close]), price_data[ticker] = "AAPL")
```

`Rating` uses the same rule as Excel and Python. The valuation and projection CSVs are saved model outputs: changing Excel assumptions does not update them automatically. Re-export those outputs and refresh Power BI after a scenario change; the supplied files match the base-case snapshot.

## 4. Pages

| Page | Visuals |
|---|---|
| **Business Performance** | 4 KPI cards (FY2026) · revenue vs net income · margin trend · revenue mix (100% stacked) · FCF vs cash returned |
| **Valuation** | Price / target / upside / rating cards · value per share by method · peer EV/EBITDA · AAPL price history · DCF projection table |

Design rules used: one blue colour family, red only for the SELL signal, and chart titles that state
the insight (e.g. *"Services pushed operating margin to 33%"*) instead of just naming the metric.
