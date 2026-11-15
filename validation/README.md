# Validation record

Data snapshot: November 13, 2026. MySQL validation: November 15, 2026.

- All seven SQL scripts executed successfully on MySQL 8.0.44, producing nine result sets.
- Tables reconciled to the saved CSVs: income statement (5 rows), balance sheet (5), cash flow (5), revenue by product (25), daily prices (14,925).
- Total assets equal liabilities plus equity in all five years.
- Operating cash flow plus signed capex equals free cash flow in all five years.
- Product revenue sums to total revenue in all five years.
- Existing MySQL tables were preserved under timestamped backup names; see `mysql_validation.json`.
- All three notebooks were rerun successfully using the bundled snapshot. Daily beta rounded to 1.177 and WACC to 10.02%.
- Python's DCF ($138.86), comparable-company value ($214.94), and blended target ($176.90) matched the saved Excel and Power BI summary values. No cached Excel error cells were found. Excel itself was not recalculated during this handoff; see `model_check.json`.

The files in `sql_results/` are actual database query outputs. These checks verify execution and internal consistency; they are not an audit of every external input or a validation of the investment recommendation. Model assumptions and methodological limitations are documented in the main README.

Run `python scripts/validate_mysql.py` to repeat the checks against the current local database, or add `--load` to load the bundled snapshot with backups. Authentication stays local and is not included in this repository.
