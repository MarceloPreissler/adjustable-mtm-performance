/*******************************************************************************
 * TABLE DISCOVERY SCRIPT - MTM Performance Management
 *
 * PURPOSE: Automatically discover tables containing pricing, COGS, plan,
 *          and usage data needed for MTM Performance calculations
 *
 * WHAT THIS DOES:
 * 1. Searches all databases for tables with relevant names
 * 2. Shows table schemas (columns, types)
 * 3. Displays sample data from candidate tables
 * 4. Generates a summary report
 *
 * RUN THIS: It will tell us exactly which tables to use!
 *******************************************************************************/

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT '      MTM PERFORMANCE - TABLE DISCOVERY';
PRINT '      ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '======================================================================';
PRINT '';

-- ============================================================================
-- SECTION 1: SEARCH FOR PRICING TABLES (StatusFact or similar)
-- ============================================================================
PRINT '>>> SECTION 1: SEARCHING FOR PRICING TABLES';
PRINT '--------------------------------------------------------------------';
PRINT 'Looking for tables like: StatusFact, Pricing, Rate, EnergyCharge...';
PRINT '';

-- Create temp table to store results
IF OBJECT_ID('tempdb..#PricingTables') IS NOT NULL DROP TABLE #PricingTables;
CREATE TABLE #PricingTables (
    DatabaseName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    FullTableName NVARCHAR(400),
    RowCount BIGINT
);

-- Search for pricing-related tables across all databases
DECLARE @sql NVARCHAR(MAX);
SET @sql = N'';

SELECT @sql = @sql + N'
USE [' + name + N'];
INSERT INTO #PricingTables (DatabaseName, SchemaName, TableName, FullTableName, RowCount)
SELECT
    ''' + name + N''' AS DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    ''' + name + N'.['' + s.name + ''].['' + t.name + '']'' AS FullTableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE ''%Status%''
   OR t.name LIKE ''%Fact%''
   OR t.name LIKE ''%Pricing%''
   OR t.name LIKE ''%Rate%''
   OR t.name LIKE ''%Price%''
   OR t.name LIKE ''%Energy%Charge%''
   OR t.name LIKE ''%Customer%Price%'';
'
FROM sys.databases
WHERE database_id > 4  -- Skip system databases
  AND state_desc = 'ONLINE'
  AND HAS_DBACCESS(name) = 1;

BEGIN TRY
    EXEC sp_executesql @sql;

    IF EXISTS (SELECT 1 FROM #PricingTables)
    BEGIN
        PRINT 'FOUND PRICING TABLE CANDIDATES:';
        PRINT '';
        SELECT
            ROW_NUMBER() OVER (ORDER BY RowCount DESC) AS [#],
            DatabaseName,
            SchemaName,
            TableName,
            FORMAT(RowCount, 'N0') AS [Rows]
        FROM #PricingTables
        ORDER BY RowCount DESC;
    END
    ELSE
    BEGIN
        PRINT '⚠️  No pricing tables found with common naming patterns';
    END
END TRY
BEGIN CATCH
    PRINT '⚠️  Error searching for pricing tables: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- SECTION 2: SEARCH FOR COGS TABLES
-- ============================================================================
PRINT '>>> SECTION 2: SEARCHING FOR COGS TABLES';
PRINT '--------------------------------------------------------------------';
PRINT 'Looking for tables like: COGS, Cost, EDM...';
PRINT '';

IF OBJECT_ID('tempdb..#COGSTables') IS NOT NULL DROP TABLE #COGSTables;
CREATE TABLE #COGSTables (
    DatabaseName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    FullTableName NVARCHAR(400),
    RowCount BIGINT
);

SET @sql = N'';

SELECT @sql = @sql + N'
USE [' + name + N'];
INSERT INTO #COGSTables (DatabaseName, SchemaName, TableName, FullTableName, RowCount)
SELECT
    ''' + name + N''' AS DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    ''' + name + N'.['' + s.name + ''].['' + t.name + '']'' AS FullTableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE ''%COGS%''
   OR t.name LIKE ''%Cost%Goods%''
   OR t.name LIKE ''%EDM%''
   OR t.name LIKE ''%Power%Cost%''
   OR t.name LIKE ''%Actual%Cost%'';
'
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
  AND HAS_DBACCESS(name) = 1;

BEGIN TRY
    EXEC sp_executesql @sql;

    IF EXISTS (SELECT 1 FROM #COGSTables)
    BEGIN
        PRINT 'FOUND COGS TABLE CANDIDATES:';
        PRINT '';
        SELECT
            ROW_NUMBER() OVER (ORDER BY RowCount DESC) AS [#],
            DatabaseName,
            SchemaName,
            TableName,
            FORMAT(RowCount, 'N0') AS [Rows]
        FROM #COGSTables
        ORDER BY RowCount DESC;
    END
    ELSE
    BEGIN
        PRINT '⚠️  No COGS tables found with common naming patterns';
    END
END TRY
BEGIN CATCH
    PRINT '⚠️  Error searching for COGS tables: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- SECTION 3: SEARCH FOR PLAN/FORECAST TABLES
-- ============================================================================
PRINT '>>> SECTION 3: SEARCHING FOR PLAN/FORECAST TABLES';
PRINT '--------------------------------------------------------------------';
PRINT 'Looking for tables like: Plan, Forecast, Budget, FPA...';
PRINT '';

IF OBJECT_ID('tempdb..#PlanTables') IS NOT NULL DROP TABLE #PlanTables;
CREATE TABLE #PlanTables (
    DatabaseName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    FullTableName NVARCHAR(400),
    RowCount BIGINT
);

SET @sql = N'';

SELECT @sql = @sql + N'
USE [' + name + N'];
INSERT INTO #PlanTables (DatabaseName, SchemaName, TableName, FullTableName, RowCount)
SELECT
    ''' + name + N''' AS DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    ''' + name + N'.['' + s.name + ''].['' + t.name + '']'' AS FullTableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE ''%Plan%''
   OR t.name LIKE ''%Forecast%''
   OR t.name LIKE ''%Budget%''
   OR t.name LIKE ''%FPA%''
   OR t.name LIKE ''%FP_A%''
   OR t.name LIKE ''%Projected%''
   OR t.name LIKE ''%Target%'';
'
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
  AND HAS_DBACCESS(name) = 1;

BEGIN TRY
    EXEC sp_executesql @sql;

    IF EXISTS (SELECT 1 FROM #PlanTables)
    BEGIN
        PRINT 'FOUND PLAN TABLE CANDIDATES:';
        PRINT '';
        SELECT
            ROW_NUMBER() OVER (ORDER BY RowCount DESC) AS [#],
            DatabaseName,
            SchemaName,
            TableName,
            FORMAT(RowCount, 'N0') AS [Rows]
        FROM #PlanTables
        ORDER BY RowCount DESC;
    END
    ELSE
    BEGIN
        PRINT '⚠️  No plan tables found with common naming patterns';
    END
END TRY
BEGIN CATCH
    PRINT '⚠️  Error searching for plan tables: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- SECTION 4: SEARCH FOR USAGE/CONSUMPTION TABLES
-- ============================================================================
PRINT '>>> SECTION 4: SEARCHING FOR USAGE/CONSUMPTION TABLES';
PRINT '--------------------------------------------------------------------';
PRINT 'Looking for tables like: Usage, Consumption, AMS, Meter...';
PRINT '';

IF OBJECT_ID('tempdb..#UsageTables') IS NOT NULL DROP TABLE #UsageTables;
CREATE TABLE #UsageTables (
    DatabaseName NVARCHAR(128),
    SchemaName NVARCHAR(128),
    TableName NVARCHAR(128),
    FullTableName NVARCHAR(400),
    RowCount BIGINT
);

SET @sql = N'';

SELECT @sql = @sql + N'
USE [' + name + N'];
INSERT INTO #UsageTables (DatabaseName, SchemaName, TableName, FullTableName, RowCount)
SELECT
    ''' + name + N''' AS DatabaseName,
    s.name AS SchemaName,
    t.name AS TableName,
    ''' + name + N'.['' + s.name + ''].['' + t.name + '']'' AS FullTableName,
    p.rows AS RowCount
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
WHERE t.name LIKE ''%Usage%''
   OR t.name LIKE ''%Consumption%''
   OR t.name LIKE ''%AMS%''
   OR t.name LIKE ''%Meter%''
   OR t.name LIKE ''%KWH%''
   OR t.name LIKE ''%Energy%Data%''
   OR t.name LIKE ''%Interval%'';
'
FROM sys.databases
WHERE database_id > 4
  AND state_desc = 'ONLINE'
  AND HAS_DBACCESS(name) = 1;

BEGIN TRY
    EXEC sp_executesql @sql;

    IF EXISTS (SELECT 1 FROM #UsageTables)
    BEGIN
        PRINT 'FOUND USAGE TABLE CANDIDATES:';
        PRINT '';
        SELECT
            ROW_NUMBER() OVER (ORDER BY RowCount DESC) AS [#],
            DatabaseName,
            SchemaName,
            TableName,
            FORMAT(RowCount, 'N0') AS [Rows]
        FROM #UsageTables
        ORDER BY RowCount DESC;
    END
    ELSE
    BEGIN
        PRINT '⚠️  No usage tables found with common naming patterns';
    END
END TRY
BEGIN CATCH
    PRINT '⚠️  Error searching for usage tables: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- SECTION 5: GENERATE FOLLOW-UP QUERIES
-- ============================================================================
PRINT '======================================================================';
PRINT '      NEXT STEPS - EXPLORE TABLE SCHEMAS';
PRINT '======================================================================';
PRINT '';
PRINT 'Copy and run the queries below to see columns and sample data:';
PRINT '';

-- Generate schema queries for top candidates
DECLARE @TableName NVARCHAR(400);
DECLARE @Counter INT = 1;

-- Pricing tables
IF EXISTS (SELECT 1 FROM #PricingTables)
BEGIN
    PRINT '-- ================================================================';
    PRINT '-- PRICING TABLE SCHEMAS';
    PRINT '-- ================================================================';

    DECLARE pricing_cursor CURSOR FOR
    SELECT TOP 3 FullTableName FROM #PricingTables ORDER BY RowCount DESC;

    OPEN pricing_cursor;
    FETCH NEXT FROM pricing_cursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '';
        PRINT '-- Table: ' + @TableName;
        PRINT 'SELECT TOP 5 * FROM ' + @TableName + ';';
        PRINT 'EXEC sp_help ''' + @TableName + ''';';

        FETCH NEXT FROM pricing_cursor INTO @TableName;
    END

    CLOSE pricing_cursor;
    DEALLOCATE pricing_cursor;
    PRINT '';
END

-- COGS tables
IF EXISTS (SELECT 1 FROM #COGSTables)
BEGIN
    PRINT '-- ================================================================';
    PRINT '-- COGS TABLE SCHEMAS';
    PRINT '-- ================================================================';

    DECLARE cogs_cursor CURSOR FOR
    SELECT TOP 3 FullTableName FROM #COGSTables ORDER BY RowCount DESC;

    OPEN cogs_cursor;
    FETCH NEXT FROM cogs_cursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '';
        PRINT '-- Table: ' + @TableName;
        PRINT 'SELECT TOP 5 * FROM ' + @TableName + ';';
        PRINT 'EXEC sp_help ''' + @TableName + ''';';

        FETCH NEXT FROM cogs_cursor INTO @TableName;
    END

    CLOSE cogs_cursor;
    DEALLOCATE cogs_cursor;
    PRINT '';
END

-- Plan tables
IF EXISTS (SELECT 1 FROM #PlanTables)
BEGIN
    PRINT '-- ================================================================';
    PRINT '-- PLAN TABLE SCHEMAS';
    PRINT '-- ================================================================';

    DECLARE plan_cursor CURSOR FOR
    SELECT TOP 3 FullTableName FROM #PlanTables ORDER BY RowCount DESC;

    OPEN plan_cursor;
    FETCH NEXT FROM plan_cursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '';
        PRINT '-- Table: ' + @TableName;
        PRINT 'SELECT TOP 5 * FROM ' + @TableName + ';';
        PRINT 'EXEC sp_help ''' + @TableName + ''';';

        FETCH NEXT FROM plan_cursor INTO @TableName;
    END

    CLOSE plan_cursor;
    DEALLOCATE plan_cursor;
    PRINT '';
END

-- Usage tables
IF EXISTS (SELECT 1 FROM #UsageTables)
BEGIN
    PRINT '-- ================================================================';
    PRINT '-- USAGE TABLE SCHEMAS';
    PRINT '-- ================================================================';

    DECLARE usage_cursor CURSOR FOR
    SELECT TOP 3 FullTableName FROM #UsageTables ORDER BY RowCount DESC;

    OPEN usage_cursor;
    FETCH NEXT FROM usage_cursor INTO @TableName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT '';
        PRINT '-- Table: ' + @TableName;
        PRINT 'SELECT TOP 5 * FROM ' + @TableName + ';';
        PRINT 'EXEC sp_help ''' + @TableName + ''';';

        FETCH NEXT FROM usage_cursor INTO @TableName;
    END

    CLOSE usage_cursor;
    DEALLOCATE usage_cursor;
    PRINT '';
END

PRINT '';
PRINT '======================================================================';
PRINT 'Copy the queries above and run them to see:';
PRINT '  - Sample data from each table';
PRINT '  - Column names and data types';
PRINT '  - Which tables have the data we need';
PRINT '';
PRINT 'Then send me the table names and I will update the extraction procs!';
PRINT '======================================================================';

-- Cleanup
DROP TABLE #PricingTables;
DROP TABLE #COGSTables;
DROP TABLE #PlanTables;
DROP TABLE #UsageTables;

GO
