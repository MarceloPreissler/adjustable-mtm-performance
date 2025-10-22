/*******************************************************************************
 * DATABASE AND STAGING TABLES SETUP
 *
 * PURPOSE: Create database and all staging/output tables for MTM Performance
 * RUN THIS SECOND after creating linked servers
 *
 * DATABASE: MTM_Performance (or customize below)
 *******************************************************************************/

-- ============================================================================
-- STEP 1: CREATE DATABASE
-- ============================================================================
-- TODO: Customize database name if needed

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'MTM_Performance')
BEGIN
    CREATE DATABASE MTM_Performance;
    PRINT 'Created database: MTM_Performance';
END
ELSE
BEGIN
    PRINT 'Database MTM_Performance already exists';
END
GO

USE MTM_Performance;
GO

-- ============================================================================
-- STEP 2: CREATE STAGING TABLES
-- ============================================================================

-- Drop existing tables if they exist (for clean setup)
IF OBJECT_ID('stg_MTM_Counts_Raw', 'U') IS NOT NULL DROP TABLE stg_MTM_Counts_Raw;
IF OBJECT_ID('stg_MTM_Pricing_Data', 'U') IS NOT NULL DROP TABLE stg_MTM_Pricing_Data;
IF OBJECT_ID('stg_COGS_Data', 'U') IS NOT NULL DROP TABLE stg_COGS_Data;
IF OBJECT_ID('stg_Plan_Data', 'U') IS NOT NULL DROP TABLE stg_Plan_Data;
IF OBJECT_ID('stg_Usage_Data', 'U') IS NOT NULL DROP TABLE stg_Usage_Data;
IF OBJECT_ID('stg_MTM_Counts_Normalized', 'U') IS NOT NULL DROP TABLE stg_MTM_Counts_Normalized;

-- -----------------------------------------------------------------------------
-- RAW MTM COUNTS (from Snowflake/HANA via OPENQUERY)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_MTM_Counts_Raw (
    DataSource VARCHAR(20),                -- 'SNOWFLAKE', 'HANA', 'SQLSERVER'
    YearLook VARCHAR(4),
    MonthLook VARCHAR(2),
    CHANNEL VARCHAR(100),
    ESID_PREMISE VARCHAR(50),
    CUSTOMER_FLAG VARCHAR(50),
    BegCount INT,
    Gains INT,
    RollIn INT,
    RollOut INT,
    Loss INT,
    EndCount INT,
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_MTM_Counts_Raw PRIMARY KEY (DataSource, YearLook, MonthLook, CHANNEL, ESID_PREMISE, CUSTOMER_FLAG)
);

PRINT 'Created table: stg_MTM_Counts_Raw';

-- -----------------------------------------------------------------------------
-- PRICING DATA (from StatusFact or your pricing table)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_MTM_Pricing_Data (
    CustomerID VARCHAR(50),                -- Business Partner ID or Customer ID
    ESIID VARCHAR(50),                     -- ESIID
    EffectiveDate DATE,
    PriceStartOfYear DECIMAL(10,4),        -- Energy charge at start of year ($/kWh)
    CurrentPrice DECIMAL(10,4),            -- Current energy charge ($/kWh)
    PriceChange DECIMAL(10,4),             -- CurrentPrice - PriceStartOfYear
    PriceBand VARCHAR(20),                 -- '<15c', '15-18c', '>18c'
    BaseCharge DECIMAL(10,2),              -- Fixed base charge
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Pricing_Data PRIMARY KEY (CustomerID, ESIID, EffectiveDate)
);

PRINT 'Created table: stg_MTM_Pricing_Data';

-- -----------------------------------------------------------------------------
-- COGS DATA (from EDM)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_COGS_Data (
    YearMonth VARCHAR(6),                  -- YYYYMM format
    PremiseType VARCHAR(10),               -- 'RES' or 'BUS'
    CustomerType VARCHAR(20),              -- 'MTM' or 'TERM'
    ActualCOGS DECIMAL(10,4),              -- Actual COGS ($/kWh)
    PlanCOGS DECIMAL(10,4),                -- Planned COGS ($/kWh)
    COGSVariance DECIMAL(10,4),            -- ActualCOGS - PlanCOGS
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_COGS_Data PRIMARY KEY (YearMonth, PremiseType, CustomerType)
);

PRINT 'Created table: stg_COGS_Data';

-- -----------------------------------------------------------------------------
-- PLAN DATA (from FP&A tables)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_Plan_Data (
    YearMonth VARCHAR(6),                  -- YYYYMM format
    Channel VARCHAR(100),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(20),
    PlannedGains INT,
    PlannedLosses INT,
    PlannedSwaps INT,
    PlannedTransfers INT,
    PlannedRevenue DECIMAL(18,2),
    PlannedMargin DECIMAL(18,2),
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Plan_Data PRIMARY KEY (YearMonth, Channel, PremiseType, CustomerType)
);

PRINT 'Created table: stg_Plan_Data';

-- -----------------------------------------------------------------------------
-- USAGE/CONSUMPTION DATA (from AMS 15-minute interval table)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_Usage_Data (
    CustomerID VARCHAR(50),
    ESIID VARCHAR(50),
    YearMonth VARCHAR(6),
    TotalUsageKWH DECIMAL(18,2),           -- Total consumption in kWh
    TotalUsageMWH DECIMAL(18,4),           -- Total consumption in MWh
    AverageUsageKWH DECIMAL(18,2),         -- Average monthly usage
    UsageBucket VARCHAR(50),               -- '<100 MWh', '100-500 MWh', '>500 MWh', etc.
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Usage_Data PRIMARY KEY (CustomerID, ESIID, YearMonth)
);

PRINT 'Created table: stg_Usage_Data';

-- -----------------------------------------------------------------------------
-- NORMALIZED MTM COUNTS (after channel mapping and transformations)
-- -----------------------------------------------------------------------------
CREATE TABLE stg_MTM_Counts_Normalized (
    YearLook VARCHAR(4),
    MonthLook VARCHAR(2),
    YearMonth VARCHAR(6),                  -- YYYYMM
    MassActualChannel VARCHAR(100),        -- Original channel
    MatrixChannel VARCHAR(100),            -- Normalized channel
    ScottChannel VARCHAR(100),             -- Consolidated channel
    ESID_PREMISE VARCHAR(50),
    PremiseType VARCHAR(10),               -- 'RES' or 'BUS'
    TermMTM VARCHAR(10),                   -- 'MTM' or 'TERM'
    BegCount INT,
    Gains INT,
    RollIn INT,
    RollOut INT,
    Loss INT,
    EndCount INT,
    Swaps INT,                             -- RollOut (customers switching products)
    NetGains INT,                          -- Gains - Loss
    ExtractDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_MTM_Counts_Normalized PRIMARY KEY (YearMonth, MatrixChannel, ESID_PREMISE, TermMTM)
);

PRINT 'Created table: stg_MTM_Counts_Normalized';

-- ============================================================================
-- STEP 3: CREATE OUTPUT/ANALYSIS TABLES
-- ============================================================================

IF OBJECT_ID('out_Incremental_Revenue', 'U') IS NOT NULL DROP TABLE out_Incremental_Revenue;
IF OBJECT_ID('out_Contribution_Margin', 'U') IS NOT NULL DROP TABLE out_Contribution_Margin;
IF OBJECT_ID('out_Counts_Analysis', 'U') IS NOT NULL DROP TABLE out_Counts_Analysis;
IF OBJECT_ID('out_Consumption_Analysis', 'U') IS NOT NULL DROP TABLE out_Consumption_Analysis;
IF OBJECT_ID('out_Actual_vs_Plan', 'U') IS NOT NULL DROP TABLE out_Actual_vs_Plan;

-- -----------------------------------------------------------------------------
-- INCREMENTAL REVENUE OUTPUT
-- -----------------------------------------------------------------------------
CREATE TABLE out_Incremental_Revenue (
    YearMonth VARCHAR(6),
    Channel VARCHAR(100),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(10),
    PriceAtStart DECIMAL(10,4),
    NewPrice DECIMAL(10,4),
    PriceChange DECIMAL(10,4),
    Quantity DECIMAL(18,2),                -- Volume (customer count * avg consumption)
    IncrementalRevenue DECIMAL(18,2),      -- (NewPrice - PriceAtStart) * Quantity
    -- Decomposition (holding variables constant)
    RevenueImpact_Rate DECIMAL(18,2),      -- Impact of rate changes only
    RevenueImpact_Consumption DECIMAL(18,2), -- Impact of consumption changes only
    RevenueImpact_Counts DECIMAL(18,2),    -- Impact of count changes only
    CalculationDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Incremental_Revenue PRIMARY KEY (YearMonth, Channel, PremiseType, CustomerType)
);

PRINT 'Created table: out_Incremental_Revenue';

-- -----------------------------------------------------------------------------
-- CONTRIBUTION MARGIN OUTPUT (MOST CRITICAL METRIC)
-- -----------------------------------------------------------------------------
CREATE TABLE out_Contribution_Margin (
    YearMonth VARCHAR(6),
    Channel VARCHAR(100),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(10),
    NewPrice DECIMAL(10,4),
    OldPrice DECIMAL(10,4),
    ActualCOGS DECIMAL(10,4),
    PlanCOGS DECIMAL(10,4),
    Usage DECIMAL(18,2),
    Quantity DECIMAL(18,2),
    IncrementalRevenue DECIMAL(18,2),
    COGSVariance DECIMAL(18,2),            -- (ActualCOGS - PlanCOGS) * Usage
    ContributionMargin DECIMAL(18,2),      -- (NewPrice - OldPrice - (ActualCOGS/Usage)) * Quantity
    MarginPercent DECIMAL(10,2),           -- CM / Revenue
    CalculationDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Contribution_Margin PRIMARY KEY (YearMonth, Channel, PremiseType, CustomerType)
);

PRINT 'Created table: out_Contribution_Margin';

-- -----------------------------------------------------------------------------
-- COUNTS ANALYSIS OUTPUT
-- -----------------------------------------------------------------------------
CREATE TABLE out_Counts_Analysis (
    YearMonth VARCHAR(6),
    Channel VARCHAR(100),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(10),
    ActualGains INT,
    PlannedGains INT,
    GainsVariance INT,                     -- Actual - Plan
    ActualLosses INT,
    PlannedLosses INT,
    LossesVariance INT,
    ActualSwaps INT,
    PlannedSwaps INT,
    SwapsVariance INT,
    ActualTransfers INT,
    PlannedTransfers INT,
    TransfersVariance INT,
    NetChange INT,                         -- Gains - Losses - Swaps + Transfers
    CalculationDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Counts_Analysis PRIMARY KEY (YearMonth, Channel, PremiseType, CustomerType)
);

PRINT 'Created table: out_Counts_Analysis';

-- -----------------------------------------------------------------------------
-- CONSUMPTION ANALYSIS OUTPUT
-- -----------------------------------------------------------------------------
CREATE TABLE out_Consumption_Analysis (
    YearMonth VARCHAR(6),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(10),
    TotalUsageMWH DECIMAL(18,4),
    AverageUsageMWH DECIMAL(18,4),
    CustomerCount INT,
    UsagePerCustomer DECIMAL(18,4),
    UsageBucket VARCHAR(50),
    BucketCount INT,
    BucketPercent DECIMAL(10,2),
    CalculationDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT PK_Consumption_Analysis PRIMARY KEY (YearMonth, PremiseType, CustomerType, UsageBucket)
);

PRINT 'Created table: out_Consumption_Analysis';

-- -----------------------------------------------------------------------------
-- ACTUAL VS PLAN VARIANCE OUTPUT
-- -----------------------------------------------------------------------------
CREATE TABLE out_Actual_vs_Plan (
    YearMonth VARCHAR(6),
    Channel VARCHAR(100),
    PremiseType VARCHAR(10),
    CustomerType VARCHAR(10),
    MetricName VARCHAR(100),
    ActualValue DECIMAL(18,2),
    PlanValue DECIMAL(18,2),
    Variance DECIMAL(18,2),
    VariancePercent DECIMAL(10,2),
    Status VARCHAR(20),                    -- 'Met', 'Exceeded', 'Missed'
    CalculationDate DATETIME DEFAULT GETDATE()
);

PRINT 'Created table: out_Actual_vs_Plan';

-- ============================================================================
-- STEP 4: CREATE HELPER/LOOKUP TABLES
-- ============================================================================

IF OBJECT_ID('lkp_Channel_Mapping', 'U') IS NOT NULL DROP TABLE lkp_Channel_Mapping;
IF OBJECT_ID('lkp_Price_Bands', 'U') IS NOT NULL DROP TABLE lkp_Price_Bands;

-- -----------------------------------------------------------------------------
-- CHANNEL MAPPING LOOKUP
-- -----------------------------------------------------------------------------
CREATE TABLE lkp_Channel_Mapping (
    SourceChannel VARCHAR(100) PRIMARY KEY,
    MatrixChannel VARCHAR(100),
    ScottChannel VARCHAR(100)
);

-- Insert channel mappings
INSERT INTO lkp_Channel_Mapping (SourceChannel, MatrixChannel, ScottChannel)
VALUES
    ('WEB PHONE REACTIVE', 'CALL CENTER', 'Reactive'),
    ('REACTIVE', 'CALL CENTER', 'Reactive'),
    ('CALL CENTER', 'CALL CENTER', 'Reactive'),
    ('WEB SEARCH', 'Web Search', 'Web Search'),
    ('WEB_SEARCH', 'Web Search', 'Web Search'),
    ('ONLINE PARTNER', 'SOE', 'SOE'),
    ('RAQ', 'RAQ', 'RAQ'),
    ('REQUEST A QUOTE', 'RAQ', 'RAQ'),
    ('TEE.COM', 'RAQ', 'RAQ'),
    ('OUTBOUND', 'Agile', 'Agile'),
    ('AGILE', 'Agile', 'Agile'),
    ('OBTM', 'Agile', 'Agile'),
    ('DIRECT MAIL', 'DM', 'DM'),
    ('DM', 'DM', 'DM'),
    ('BAAT', 'BAAT', 'BAAT'),
    ('PARTNERSHIPS/EVENTS', 'Partnerships/Events', 'Reactive'),
    ('BD_MASS - POLR', 'POLR', 'POLR'),
    ('UNK', 'Other', 'Reactive'),
    ('BD_LBM', 'Other', 'Reactive'),
    ('LBM', 'Other', 'Reactive'),
    ('DOOR TO DOOR', 'Other', 'Reactive'),
    ('SPECIALTY_MKT', 'Other', 'Reactive'),
    ('', 'Other', 'Reactive');

PRINT 'Created and populated table: lkp_Channel_Mapping';

-- -----------------------------------------------------------------------------
-- PRICE BANDS LOOKUP
-- -----------------------------------------------------------------------------
CREATE TABLE lkp_Price_Bands (
    PriceBand VARCHAR(20) PRIMARY KEY,
    MinPrice DECIMAL(10,4),
    MaxPrice DECIMAL(10,4),
    Description VARCHAR(100)
);

INSERT INTO lkp_Price_Bands (PriceBand, MinPrice, MaxPrice, Description)
VALUES
    ('<15c', 0.0000, 0.1499, 'Below 15 cents per kWh'),
    ('15-18c', 0.1500, 0.1799, '15 to 18 cents per kWh'),
    ('>18c', 0.1800, 9.9999, 'Above 18 cents per kWh (soft cap)');

PRINT 'Created and populated table: lkp_Price_Bands';

-- ============================================================================
-- SUMMARY
-- ============================================================================
PRINT '======================================================================';
PRINT 'Database and table setup complete!';
PRINT 'Database: MTM_Performance';
PRINT 'Staging Tables: 6';
PRINT 'Output Tables: 5';
PRINT 'Lookup Tables: 2';
PRINT '======================================================================';
PRINT 'Next step: Run extraction stored procedures in ssms/02_extraction/';
PRINT '======================================================================';
GO
