import os
import pandas as pd
from pathlib import Path

from extract_from_snowflake import sf_query_df
from extract_from_sqlserver import mssql_query_df
from extract_from_hana import hana_query_df

SQL_EXTRACT_PATH = str(Path(__file__).resolve().parents[2] / "sql" / "adjustable_mtm" / "extract_mtm_usage.sql")
EXPORT_DIR = str(Path(__file__).resolve().parents[2] / "data_exports")
Path(EXPORT_DIR).mkdir(parents=True, exist_ok=True)

def read_sql_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def save_df(df: pd.DataFrame, name: str):
    out = Path(EXPORT_DIR) / name
    df.to_csv(out, index=False)
    print(f"Wrote {out} ({len(df):,} rows)")

def main():
    sql = read_sql_file(SQL_EXTRACT_PATH)

    any_rows = False

    # Snowflake
    if os.getenv("ENABLE_SNOWFLAKE", "true").lower() in ("1","true","yes"):
        df_sf = sf_query_df(sql)
        if not df_sf.empty:
            any_rows = True
            save_df(df_sf, "mtm_usage_snowflake.csv")

    # SQL Server
    if os.getenv("ENABLE_SQLSERVER", "false").lower() in ("1","true","yes"):
        df_ms = mssql_query_df(sql)
        if not df_ms.empty:
            any_rows = True
            save_df(df_ms, "mtm_usage_sqlserver.csv")

    # HANA
    if os.getenv("ENABLE_HANA", "false").lower() in ("1","true","yes"):
        df_hana = hana_query_df(sql)
        if not df_hana.empty:
            any_rows = True
            save_df(df_hana, "mtm_usage_hana.csv")

    if not any_rows:
        print("No connections enabled or no rows returned. Check secrets and ENABLE_* flags.")

if __name__ == "__main__":
    main()
