"""Load the saved project snapshot and run all seven MySQL scripts.

Existing tables are retained as timestamped backups. Passwords are prompted
or read from MYSQL_PASSWORD, never written into the project or its outputs.
"""
import argparse
import getpass
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import URL

ROOT = Path(__file__).resolve().parents[1]
TABLES = {
    "income_statement": "data/income_statement.csv",
    "balance_sheet": "data/balance_sheet.csv",
    "cash_flow": "data/cash_flow.csv",
    "revenue_by_product": "data/revenue_by_product.csv",
    "price_data": "data/raw/price_data_long.csv",
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--user", default="aapl_user")
    parser.add_argument("--database", default="aapl_stock_project", choices=["aapl_stock_project"])
    parser.add_argument("--load", action="store_true", help="Load snapshot, preserving existing tables")
    args = parser.parse_args()
    password = os.environ.pop("MYSQL_PASSWORD", None) or getpass.getpass("MySQL password: ")
    engine = create_engine(URL.create("mysql+pymysql", username=args.user, password=password,
                                     host=args.host, database=args.database))
    out = ROOT / "validation" / "sql_results"
    out.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    summary = {"validated_at_utc": datetime.now(timezone.utc).isoformat(),
               "data_as_of": "2026-11-13", "backups": {}, "scripts": [], "checks": {}}
    frames = {name: pd.read_csv(ROOT / path) for name, path in TABLES.items()}
    frames["price_data"]["date"] = pd.to_datetime(frames["price_data"]["date"])
    assert not frames["price_data"].duplicated(["date", "ticker"]).any()
    bs, cf = frames["balance_sheet"], frames["cash_flow"]
    assert (bs.total_assets == bs.total_liabilities + bs.stockholders_equity).all()
    assert (cf.free_cash_flow == cf.operating_cash_flow + cf.capital_expenditure).all()
    products = frames["revenue_by_product"].groupby("fiscal_year").revenue.sum()
    revenue = frames["income_statement"].set_index("fiscal_year").total_revenue
    pd.testing.assert_series_equal(products, revenue, check_names=False)
    with engine.connect() as con:
        summary["mysql_version"] = con.execute(text("SELECT VERSION()")).scalar_one()
    if args.load:
        existing = set(inspect(engine).get_table_names())
        renames = []
        for name, frame in frames.items():
            stage = f"{name}_stage_{stamp}"
            frame.to_sql(stage, engine, if_exists="fail", index=False, chunksize=1000)
            if name in existing:
                backup = f"{name}_backup_{stamp}"
                renames.append(f"`{name}` TO `{backup}`")
                summary["backups"][name] = backup
            renames.append(f"`{stage}` TO `{name}`")
        with engine.begin() as con:
            con.execute(text("RENAME TABLE " + ", ".join(renames)))
    # Keep one connection for USE and its subsequent statements.
    with engine.begin() as con:
        for path in sorted((ROOT / "sql").glob("*.sql")):
            sql = "\n".join(line.split("--", 1)[0] for line in path.read_text(encoding="utf-8").splitlines())
            result_sets = []
            for statement in filter(None, (part.strip() for part in sql.split(";"))):
                result = con.execute(text(statement))
                if result.returns_rows:
                    frame = pd.DataFrame(result.fetchall(), columns=result.keys())
                    name = f"{path.stem}_q{len(result_sets) + 1}.csv"
                    frame.to_csv(out / name, index=False)
                    result_sets.append({"file": name, "rows": len(frame)})
            summary["scripts"].append({"script": path.name, "status": "PASS", "results": result_sets})
            print(path.name, "PASS", [r["rows"] for r in result_sets])
        for name, expected in frames.items():
            actual = pd.read_sql(text(f"SELECT * FROM `{name}`"), con)
            if name == "price_data":
                actual["date"] = pd.to_datetime(actual["date"])
                keys = ["date", "ticker"]
            elif name == "revenue_by_product":
                keys = ["fiscal_year", "product"]
            else:
                keys = ["fiscal_year"]
            pd.testing.assert_frame_equal(actual.sort_values(keys).reset_index(drop=True),
                                          expected.sort_values(keys).reset_index(drop=True),
                                          check_dtype=False, check_exact=False, rtol=1e-12, atol=1e-8)
            summary["checks"][name] = {"rows": len(actual), "matches_csv": True}
    summary["checks"].update(accounting_equation="PASS", free_cash_flow="PASS", product_revenue="PASS")
    (out.parent / "mysql_validation.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    engine.dispose()
    print("PASS: all tables match the CSV snapshot; accounting and product checks passed.")


if __name__ == "__main__":
    main()
