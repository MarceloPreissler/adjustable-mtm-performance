import pandas as pd
from pathlib import Path

def main():
    base = Path(__file__).resolve().parents[2]
    exports = base / "data_exports"
    out_xlsx = exports / "adjustable_mtm_actuals.xlsx"

    frames = {}
    for name in ["mtm_usage_snowflake.csv", "mtm_usage_sqlserver.csv", "mtm_usage_hana.csv", "mtm_rollup_actuals.csv"]:
        f = exports / name
        if f.exists():
            frames[name.replace(".csv","")] = pd.read_csv(f)

    if not frames:
        print("No CSVs found to write. Run extracts first.")
        return

    with pd.ExcelWriter(out_xlsx, engine="xlsxwriter") as xw:
        for sheet, df in frames.items():
            df.to_excel(xw, index=False, sheet_name=sheet[:31])
    print(f"Wrote {out_xlsx}")

if __name__ == "__main__":
    main()
