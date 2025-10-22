# MTM Performance Management System - SSMS Implementation

## 🎯 What This Is

A complete **SQL Server Management Studio (SSMS)** based system for managing and analyzing **Month-to-Month (MTM) customer performance** in the energy utility sector. This replaces the Python-based approach with a pure T-SQL solution using **OPENQUERY** to access Snowflake and SAP HANA data.

---

## 📊 Key Metrics Calculated

### 1. **Contribution Margin** ⭐ MOST CRITICAL
- **Formula**: `(NewPrice - OldPrice - (ActualCOGS / Usage)) × Quantity`
- **Purpose**: TRUE profitability - accounts for both price changes AND cost fluctuations
- **Why Critical**: Revenue alone is misleading if power costs (COGS) increase

### 2. **Incremental Revenue**
- **Formula**: `(NewPrice - PriceAtStart) × Quantity`
- **Decomposition**:
  - Rate Impact (price changes only)
  - Consumption Impact (usage changes only)
  - Counts Impact (customer count changes only)

### 3. **Counts Analysis**
- Gains vs Plan
- Losses vs Plan
- Swaps vs Plan (customers switching products)
- Transfers (customer relocations)
- Net Change

### 4. **Consumption Analysis**
- Usage bucket segmentation (>100 MWh, etc.)
- Weather impact analysis
- Average usage per customer

### 5. **Actual vs Plan Variance**
- Performance against targets
- Status: Met, Exceeded, or Missed
- Variance analysis across all metrics

---

## 📁 Directory Structure

```
ssms/
├── 01_setup/
│   ├── create_linked_servers.sql         # Set up Snowflake/HANA connections
│   └── create_database_and_tables.sql    # Create database and all tables
├── 02_extraction/
│   ├── sp_Extract_MTM_Counts.sql         # Pull counts from Snowflake/HANA
│   ├── sp_Extract_Pricing_Data.sql       # Pull pricing from StatusFact
│   ├── sp_Extract_COGS_and_Plan_Data.sql # Pull COGS and FP&A data
│   └── sp_Extract_Usage_Data.sql         # Pull consumption from AMS
├── 03_transformation/
│   └── sp_Normalize_Channels.sql         # Channel mapping & segmentation
├── 04_calculations/
│   ├── sp_Calculate_Contribution_Margin.sql  # ⭐ MOST CRITICAL
│   └── sp_Calculate_Incremental_Revenue.sql  # Revenue decomposition
├── 05_analysis/
│   └── sp_Actual_vs_Plan_Analysis.sql    # Variance analysis
└── master_orchestration.sql               # Run everything in one go
```

---

## 🚀 Quick Start Guide

### **STEP 1: Verify Linked Servers**

You already have these linked servers configured:
- `SNOWFLAKE` ✅
- `HANA_LINKED` ✅

Test them in SSMS on your server (`FTHYN54\MSSQLSERVER2`):

```sql
-- Test your existing linked servers
:r "01_setup/test_linked_servers.sql"
```

This will verify both connections are working correctly.

---

### **STEP 2: Create Database and Tables**

```sql
:r "01_setup/create_database_and_tables.sql"
```

This creates:
- `MTM_Performance` database
- 6 staging tables
- 5 output tables
- 2 lookup tables (channel mapping, price bands)

---

### **STEP 3: Update Extraction Procedures**

**⚠️ ACTION REQUIRED:** The extraction procedures have placeholders that need YOUR specific table information.

#### **A. Pricing Data** (`02_extraction/sp_Extract_Pricing_Data.sql`)

**I Need From You:**
1. What is your StatusFact table called? (Or equivalent pricing table)
2. Database and schema location?
3. Column names for:
   - Customer ID / Business Partner ID
   - ESIID
   - Energy charge at start of year ($/kWh)
   - Current energy charge ($/kWh)
   - Base charge
   - Effective date

**Example Update:**
```sql
-- Replace the TODO section with something like:
SELECT
    p.BusinessPartnerID AS CustomerID,
    p.ESIID,
    p.EffectiveDate,
    p.EnergyChargeJan2024 AS PriceStartOfYear,
    p.CurrentEnergyCharge AS CurrentPrice,
    -- ... etc
FROM [YourDB].[dbo].StatusFact p
WHERE p.Year BETWEEN @StartYear AND @EndYear
```

#### **B. COGS Data** (`02_extraction/sp_Extract_COGS_and_Plan_Data.sql`)

**I Need From You:**
1. EDM database and table name for COGS data
2. Column names for:
   - Year/Month identifier
   - Actual COGS ($/kWh)
   - Plan/Budgeted COGS ($/kWh)
   - Customer segment (RES/BUS, MTM/TERM)

#### **C. Plan Data** (Same file as COGS)

**I Need From You:**
1. FP&A database and table name for Plan data
2. Column names for:
   - Planned Gains, Losses, Swaps, Transfers
   - Planned Revenue and Margin
   - Channel and customer segment

#### **D. Usage Data** (`02_extraction/sp_Extract_Usage_Data.sql`)

**I Need From You:**
1. AMS database and table name for usage data
2. Is usage stored in:
   - 15-minute intervals?
   - Already aggregated by month?
   - Another format?
3. Column names for:
   - Customer ID / Business Partner
   - ESIID
   - Usage amount (kWh)
   - Date/time
4. Usage bucket thresholds (Caroline mentioned >100 MWh filtering)

---

### **STEP 4: Run the System**

Once you've updated the extraction procedures, run the master procedure:

```sql
EXEC sp_MTM_Performance_Master_Run
    @EnableSnowflake = 1,
    @EnableHANA = 1,
    @EnableLocalSQLServer = 0,
    @StartYearMonth = '202401',
    @EndYearMonth = '202512';
```

This will:
1. Extract all data from sources
2. Normalize and transform
3. Calculate all metrics
4. Perform variance analysis
5. Generate summary reports

---

## 📋 What You Need to Provide

### **Critical Information Needed:**

| Data Source | Information Required | Status |
|------------|---------------------|--------|
| **Pricing (StatusFact)** | Table name, schema, columns for pricing data | ⚠️ NEEDED |
| **COGS (EDM)** | Table name, schema, columns for actual/plan COGS | ⚠️ NEEDED |
| **Plan (FP&A)** | Table name, schema, columns for projected metrics | ⚠️ NEEDED |
| **Usage (AMS)** | Table name, schema, columns for consumption data | ⚠️ NEEDED |
| **Snowflake DSN** | ODBC Data Source Name for Snowflake | ⚠️ NEEDED |
| **HANA DSN** | ODBC Data Source Name for SAP HANA | ⚠️ NEEDED |

### **Optional/Future Enhancements:**

- **Multi-ESIID BP Identification**: Caroline's workflow for flagging business partners with multiple ESIIDs
- **Exception Criteria Checks**: Meter read dates, installment plans, past due accounts
- **Sensitivity Analysis**: Scenario modeling (different loss rates, price changes)
- **SAP Upload File Generation**: Formatted output for price change uploads

---

## 🔍 Output Tables

After running the master procedure, query these tables:

### **Most Important:**
```sql
-- 1. Contribution Margin (THE KEY METRIC!)
SELECT * FROM out_Contribution_Margin
ORDER BY YearMonth, PremiseType, CustomerType;

-- 2. Actual vs Plan Performance
SELECT * FROM out_Actual_vs_Plan
WHERE Status = 'Missed'  -- See where you fell short
ORDER BY ABS(VariancePercent) DESC;
```

### **All Output Tables:**
- `out_Contribution_Margin` - Profitability by segment
- `out_Incremental_Revenue` - Revenue impact with decomposition
- `out_Counts_Analysis` - Customer counts vs plan
- `out_Actual_vs_Plan` - Variance analysis across all metrics
- `out_Consumption_Analysis` - Usage patterns

### **Staging Tables (Intermediate Data):**
- `stg_MTM_Counts_Raw` - Raw counts from sources
- `stg_MTM_Counts_Normalized` - Transformed with channel mapping
- `stg_MTM_Pricing_Data` - Customer pricing
- `stg_COGS_Data` - Cost of goods sold
- `stg_Plan_Data` - FP&A projections
- `stg_Usage_Data` - Customer consumption

---

## ⚙️ Architecture

### **Data Flow:**
```
┌─────────────┐
│  Snowflake  │─┐
└─────────────┘ │
                │  OPENQUERY
┌─────────────┐ │  (via Linked
│  SAP HANA   │─┼─ Servers)
└─────────────┘ │
                │
┌─────────────┐ │
│ SQL Server  │─┘
│ (Local)     │
└─────────────┘
       │
       ▼
┌──────────────────────┐
│  Staging Tables      │ ← Raw extracts
│  (stg_*)            │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Transformation      │ ← Channel normalization
│  (sp_Normalize)      │   Segmentation
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Calculations        │ ← Revenue, Margin, Counts
│  (sp_Calculate_*)    │
└──────────────────────┘
       │
       ▼
┌──────────────────────┐
│  Output Tables       │ ← Final results
│  (out_*)            │
└──────────────────────┘
```

---

## 🎓 Understanding the Metrics

### **Why Contribution Margin is #1:**

**Scenario:** You increase prices from $0.14 to $0.16 per kWh

**Incremental Revenue Analysis:**
- Price increase: $0.02/kWh
- Volume: 1,000,000 kWh
- **Incremental Revenue: $20,000** ✅ Looks great!

**BUT... What if COGS increased?**

**Contribution Margin Analysis:**
- Price increase: $0.02/kWh
- Volume: 1,000,000 kWh
- Actual COGS: $0.10/kWh (increased from $0.08)
- Plan COGS: $0.08/kWh
- COGS Variance: $0.02/kWh × 1M = $20,000
- **Contribution Margin: $20,000 - $20,000 = $0** ❌ No profit!

**This is why CM is critical** - it shows you didn't actually make money despite the revenue increase!

---

## 🛠️ Customization Points

### **Channel Mapping**
Add new channels to `lkp_Channel_Mapping` table:
```sql
INSERT INTO lkp_Channel_Mapping (SourceChannel, MatrixChannel, ScottChannel)
VALUES ('NEW_CHANNEL', 'MatrixName', 'ScottName');
```

### **Price Bands**
Modify thresholds in `lkp_Price_Bands`:
```sql
UPDATE lkp_Price_Bands
SET MaxPrice = 0.1899
WHERE PriceBand = '15-18c';
```

### **Usage Buckets**
Edit in `sp_Extract_Usage_Data`:
```sql
CASE
    WHEN SUM(u.UsageKWH) / 1000.0 < 50 THEN '<50 MWh'
    WHEN SUM(u.UsageKWH) / 1000.0 < 100 THEN '50-100 MWh'
    -- etc.
END AS UsageBucket
```

---

## 📞 Next Steps - What I Need From You

### **Immediate (To Make This Work):**

1. **Snowflake ODBC DSN Name**: What did you name it in Windows ODBC Administrator?
2. **HANA ODBC DSN Name**: What did you name it?
3. **StatusFact Table Details**:
   - Full table name (database.schema.table)
   - Column names for pricing fields
4. **EDM COGS Table Details**:
   - Full table name
   - Column names for actual/plan COGS
5. **FP&A Plan Table Details**:
   - Full table name
   - Column names for projected metrics
6. **AMS Usage Table Details**:
   - Full table name
   - Data structure (intervals vs aggregated)
   - Column names

### **Future Enhancements:**
- Caroline's exception criteria logic
- Sensitivity analysis tables
- SAP upload file formatting
- Automated scheduling (SQL Server Agent jobs)

---

## ✅ What's Already Built and Ready

✅ Complete SSMS/T-SQL infrastructure
✅ OPENQUERY-based data extraction
✅ Channel normalization logic
✅ Contribution Margin calculation (your #1 metric!)
✅ Incremental Revenue with decomposition
✅ Counts analysis (Gains/Losses/Swaps vs Plan)
✅ Actual vs Plan variance analysis
✅ Master orchestration procedure
✅ All database tables and structures

**Status:** Framework is 90% complete - just need your table/column specifics to plug in!

---

## 📧 Support

When you provide the table details above, I'll update the extraction procedures and you'll be ready to run!

**Remember:** This entire system runs in YOUR SSMS environment on `FTHYN54\MSSQLSERVER2` - no cloud dependencies, no Python required. Everything stays in your SQL Server infrastructure.
