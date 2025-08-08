[README.md](https://github.com/user-attachments/files/21688050/README.md)
# adjustable-mtm-performance

Automation pack for Adjustable MTM, allocation swimlanes, and performance QC across Snowflake, SQL Server, and SAP HANA.

## What this does (at a glance)
- Extracts MTM usage/gains (multi‑source) → `data_exports/mtm_usage_*.csv`
- Normalizes channels and builds monthly rollups → `data_exports/mtm_rollup_actuals.csv`
- QC checks (basic reasonability) → `data_exports/qc_report.json`
- Swimlane pivot (allocation table) → `data_exports/allocation_swimlanes.csv`
- Excel export of all outputs (flat, no formulas) → `data_exports/adjustable_mtm_actuals.xlsx`
- Commits artifacts back to the repo via `PAT_GITHUB`

## Secrets to create
- `PAT_GITHUB` — Personal Access Token with `repo` scope (commit‑back only).
- Snowflake: `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ACCOUNT` (+ optional `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`)
- SQL Server: `SQLSERVER_CONN` (full ODBC connection string)
- HANA: `HANA_HOST`, `HANA_PORT`, `HANA_USER`, `HANA_PASSWORD` (+ optional `HANA_SCHEMA`)

## Where to place this ZIP
Unzip the contents **into the root of the GitHub repository** you want to use (the folder should contain `.github/`, `python/`, `sql/`, etc.). Commit and push.

## Run it
- Trigger workflow **Run Adjustable MTM ETL** from Actions (or wait for schedule).
- Toggle connections with workflow inputs:
  - `enable_snowflake`: true/false
  - `enable_sqlserver`: true/false
  - `enable_hana`: true/false

## Local development
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export SNOWFLAKE_USER=...
# etc
python python/extract/run_extract.py
python python/qc_checks/validate_actual_counts.py
python python/output_formatting/write_to_excel.py
```
