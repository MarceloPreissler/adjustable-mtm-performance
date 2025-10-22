# MTM Performance Management - Quick Start Checklist

## 📋 Complete This Checklist to Get Running

### ✅ STEP 1: Prerequisites (Do This First!)

- [ ] **Open SSMS** on `FTHYN54\MSSQLSERVER2`
- [X] **Linked Servers Already Configured!**
  - [X] SNOWFLAKE (existing linked server)
  - [X] HANA_LINKED (existing linked server)

---

### ✅ STEP 2: Initial Setup (Run Once)

**2.1 Test Linked Servers**
- [ ] Open `ssms/01_setup/test_linked_servers.sql`
- [ ] **Run the script** in SSMS
- [ ] Verify SNOWFLAKE connection successful ✓
- [ ] Verify HANA_LINKED connection successful ✓

**2.2 Create Database and Tables**
- [ ] Open `ssms/01_setup/create_database_and_tables.sql`
- [ ] **Run the script** in SSMS
- [ ] Verify database `MTM_Performance` was created
- [ ] Verify 13 tables were created

---

### ✅ STEP 3: Configure Extraction Procedures

**⚠️ CRITICAL:** Fill in YOUR table information below, then update the scripts

#### 3.1 Pricing Data

**Your Information:**
- Table name: _______________________
- Database: _______________________
- Schema: _______________________
- Customer ID column: _______________________
- ESIID column: _______________________
- Current price column: _______________________
- Start-of-year price column: _______________________
- Effective date column: _______________________

**Action:**
- [ ] Open `ssms/02_extraction/sp_Extract_Pricing_Data.sql`
- [ ] Find the `TODO` section (around line 33)
- [ ] Uncomment the example query
- [ ] Replace table/column names with YOUR values above
- [ ] Comment out or delete the placeholder section
- [ ] **Run the script** to create the stored procedure

#### 3.2 COGS Data

**Your Information:**
- EDM COGS table name: _______________________
- Database: _______________________
- Schema: _______________________
- Actual COGS column: _______________________
- Plan COGS column: _______________________
- Month/Year column: _______________________

**Action:**
- [ ] Open `ssms/02_extraction/sp_Extract_COGS_and_Plan_Data.sql`
- [ ] Find the COGS `TODO` section (around line 28)
- [ ] Uncomment the example query
- [ ] Replace table/column names with YOUR values above
- [ ] **Run the script** to create the stored procedure

#### 3.3 Plan Data

**Your Information:**
- FP&A Plan table name: _______________________
- Database: _______________________
- Schema: _______________________
- Planned gains column: _______________________
- Planned losses column: _______________________
- Planned revenue column: _______________________
- Planned margin column: _______________________

**Action:**
- [ ] In same file (`sp_Extract_COGS_and_Plan_Data.sql`)
- [ ] Find the Plan Data `TODO` section (around line 100)
- [ ] Uncomment the example query
- [ ] Replace table/column names with YOUR values above
- [ ] **Run the script** again to update the stored procedure

#### 3.4 Usage Data

**Your Information:**
- AMS Usage table name: _______________________
- Database: _______________________
- Schema: _______________________
- Customer ID column: _______________________
- ESIID column: _______________________
- Usage kWh column: _______________________
- Date/time column: _______________________
- Data format: [ ] 15-min intervals  [ ] Monthly aggregated  [ ] Other: _______

**Action:**
- [ ] Open `ssms/02_extraction/sp_Extract_Usage_Data.sql`
- [ ] Find the `TODO` section (around line 41)
- [ ] Uncomment the example query
- [ ] Replace table/column names with YOUR values above
- [ ] Adjust aggregation logic based on your data format
- [ ] **Run the script** to create the stored procedure

---

### ✅ STEP 4: Create Remaining Procedures

These are ready to use as-is (no customization needed):

- [ ] Run `ssms/02_extraction/sp_Extract_MTM_Counts.sql`
- [ ] Run `ssms/03_transformation/sp_Normalize_Channels.sql`
- [ ] Run `ssms/04_calculations/sp_Calculate_Contribution_Margin.sql`
- [ ] Run `ssms/04_calculations/sp_Calculate_Incremental_Revenue.sql`
- [ ] Run `ssms/05_analysis/sp_Actual_vs_Plan_Analysis.sql`
- [ ] Run `ssms/master_orchestration.sql`

---

### ✅ STEP 5: Test Run

**Run the complete system:**

```sql
EXEC sp_MTM_Performance_Master_Run
    @EnableSnowflake = 1,
    @EnableHANA = 1,
    @EnableLocalSQLServer = 0,
    @StartYearMonth = '202401',
    @EndYearMonth = '202412';
```

**Check Results:**
- [ ] No errors in execution
- [ ] Data in `stg_MTM_Counts_Raw` (check: `SELECT COUNT(*) FROM stg_MTM_Counts_Raw`)
- [ ] Data in `out_Contribution_Margin` (check: `SELECT COUNT(*) FROM out_Contribution_Margin`)
- [ ] Review summary results

---

### ✅ STEP 6: Validate Results

**Run these queries to verify:**

```sql
-- 1. Check Contribution Margin totals
SELECT
    PremiseType,
    CustomerType,
    SUM(ContributionMargin) AS TotalCM,
    AVG(MarginPercent) AS AvgMarginPct
FROM out_Contribution_Margin
GROUP BY PremiseType, CustomerType;

-- 2. Check for any negative margins (red flags)
SELECT COUNT(*) AS NegativeMarginCount
FROM out_Contribution_Margin
WHERE ContributionMargin < 0;

-- 3. Check actual vs plan performance
SELECT
    Status,
    COUNT(*) AS Count
FROM out_Actual_vs_Plan
GROUP BY Status;

-- 4. Verify data coverage
SELECT
    YearMonth,
    COUNT(*) AS RecordCount
FROM stg_MTM_Counts_Normalized
GROUP BY YearMonth
ORDER BY YearMonth;
```

**Validation Checklist:**
- [ ] Contribution Margin values look reasonable
- [ ] No unexpected NULL values
- [ ] Date ranges match expectations (2024-2025)
- [ ] Channel counts align with source data
- [ ] Actual vs Plan variances make sense

---

### ✅ STEP 7: Schedule (Optional)

**Set up SQL Server Agent job for automated runs:**

- [ ] Open SQL Server Agent in SSMS
- [ ] Create New Job
- [ ] Add step: Execute `sp_MTM_Performance_Master_Run`
- [ ] Set schedule (daily, weekly, monthly?)
- [ ] Configure notifications
- [ ] Test the job

---

## 🆘 Troubleshooting

### Problem: Linked server connection fails
**Solution:**
- Verify DSN works in ODBC Administrator
- Test connection in DSN
- Check credentials
- Verify firewall/network access

### Problem: Extraction procedure returns no data
**Solution:**
- Verify table names are correct
- Check filters (years, brand, category)
- Test query directly in source system
- Verify data exists for date range

### Problem: NULL values in calculations
**Solution:**
- Check that all extraction procedures populated data
- Verify joins between tables (missing keys?)
- Review data quality in source tables

### Problem: "Object not found" errors
**Solution:**
- Verify all procedures were created successfully
- Check database context (`USE MTM_Performance`)
- Re-run setup scripts

---

## 📞 Information Still Needed

If you haven't filled in the sections above, **I NEED THIS INFO:**

1. **StatusFact Table**: database.schema.table = ___________________
2. **EDM COGS Table**: database.schema.table = ___________________
3. **FP&A Plan Table**: database.schema.table = ___________________
4. **AMS Usage Table**: database.schema.table = ___________________

**Linked Servers:** ✅ Already configured (SNOWFLAKE and HANA_LINKED)

**Send this info and I'll update the scripts for you!**

---

## ✅ Final Checklist

- [ ] All linked servers created and tested
- [ ] All tables created
- [ ] All extraction procedures customized with YOUR table info
- [ ] All calculation procedures created
- [ ] Master procedure created
- [ ] Test run completed successfully
- [ ] Results validated
- [ ] Documentation reviewed

**You're ready to manage MTM performance! 🎉**

---

## 📊 Quick Reference: Key Queries

**Daily Check - Contribution Margin:**
```sql
SELECT TOP 20 *
FROM out_Contribution_Margin
ORDER BY YearMonth DESC, ContributionMargin DESC;
```

**Performance Dashboard:**
```sql
SELECT
    MetricName,
    Status,
    COUNT(*) AS SegmentCount,
    AVG(VariancePercent) AS AvgVariance
FROM out_Actual_vs_Plan
GROUP BY MetricName, Status
ORDER BY MetricName;
```

**Problem Areas:**
```sql
SELECT TOP 10
    YearMonth, Channel, PremiseType, CustomerType,
    ContributionMargin, MarginPercent
FROM out_Contribution_Margin
WHERE ContributionMargin < 0
ORDER BY ContributionMargin ASC;
```
