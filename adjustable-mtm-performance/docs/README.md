# Adjustable MTM Performance – Automation Pack

This repo automates:
- Multi‑source extracts (Snowflake, SQL Server, SAP HANA)
- Channel mapping and monthly MTM rollups
- QC checks and discrepancy report
- Flat Excel and CSV exports (no formulas)
- GitHub Actions scheduling & commit‑back via `PAT_GITHUB`

## Quick Start
1. Create GitHub Actions secrets (Settings → Secrets and variables → Actions):
   - `PAT_GITHUB` (token with `repo` scope; used to push results back)
   - **Snowflake**: `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ACCOUNT` (+ optional `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`)
   - **SQL Server**: `SQLSERVER_CONN` (full ODBC connection string; see workflow for example)
   - **HANA**: `HANA_HOST`, `HANA_PORT`, `HANA_USER`, `HANA_PASSWORD`, optional `HANA_SCHEMA`

2. Commit the repo to GitHub.

3. Run the workflow “Run Adjustable MTM ETL” from the Actions tab (or wait for the schedule).

Outputs will appear under `/data_exports` and `/logs` and be pushed back to the repo by the workflow.
