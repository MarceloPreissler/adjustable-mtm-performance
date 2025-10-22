/*******************************************************************************
 * QUICK TEST SCRIPT - MTM Performance Management
 *
 * PURPOSE: Quick validation before running full setup
 * RUN THIS FIRST to verify everything is ready
 *
 * This will test:
 * 1. Linked server connectivity (SNOWFLAKE and HANA_LINKED)
 * 2. Access to Mass_Plan_Proj_Actual table
 * 3. Data availability for 2024-2025
 * 4. Sample data preview
 *******************************************************************************/

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT '      MTM PERFORMANCE MANAGEMENT - QUICK TEST';
PRINT '      ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '======================================================================';
PRINT '';

-- ============================================================================
-- TEST 1: LINKED SERVER - SNOWFLAKE
-- ============================================================================
PRINT '>>> TEST 1: SNOWFLAKE Linked Server';
PRINT '--------------------';

BEGIN TRY
    -- Basic connectivity test
    DECLARE @snow_test TABLE (result INT);
    INSERT INTO @snow_test EXEC ('SELECT 1') AT SNOWFLAKE;

    IF EXISTS (SELECT 1 FROM @snow_test)
        PRINT '✓ SNOWFLAKE connection: SUCCESS';
    ELSE
        PRINT '✗ SNOWFLAKE connection: FAILED (no response)';
END TRY
BEGIN CATCH
    PRINT '✗ SNOWFLAKE connection: FAILED';
    PRINT '  Error: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- Test data access
BEGIN TRY
    PRINT 'Testing Mass_Plan_Proj_Actual table access...';

    DECLARE @snow_count INT;
    DECLARE @snow_count_table TABLE (cnt INT);

    INSERT INTO @snow_count_table
    EXEC ('
        SELECT COUNT(*)
        FROM Mass_Plan_Proj_Actual
        WHERE CATEGORY = ''MASS_PORTFOLIO_ACTUAL''
          AND LEFT(YEARMONTH,4) IN (''2024'',''2025'')
          AND CUSTOMER_FLAG IN (''B_MASS_MTM'', ''B_MASS_TERM'')
    ') AT SNOWFLAKE;

    SELECT @snow_count = cnt FROM @snow_count_table;

    PRINT '✓ Mass_Plan_Proj_Actual accessible';
    PRINT '  Records found (2024-2025 MTM/TERM): ' + CAST(@snow_count AS VARCHAR);

    IF @snow_count = 0
        PRINT '  ⚠️  WARNING: No records found! Check filters or data availability.';
    ELSE IF @snow_count < 100
        PRINT '  ⚠️  WARNING: Very few records found. Expected more data.';
    ELSE
        PRINT '  ✓ Good data volume';

END TRY
BEGIN CATCH
    PRINT '✗ Mass_Plan_Proj_Actual access: FAILED';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Note: Table might not exist or different name/schema';
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- TEST 2: LINKED SERVER - HANA_LINKED
-- ============================================================================
PRINT '>>> TEST 2: HANA_LINKED Linked Server';
PRINT '--------------------';

BEGIN TRY
    -- Basic connectivity test
    DECLARE @hana_test TABLE (result INT);
    INSERT INTO @hana_test EXEC ('SELECT 1 FROM DUMMY') AT HANA_LINKED;

    IF EXISTS (SELECT 1 FROM @hana_test)
        PRINT '✓ HANA_LINKED connection: SUCCESS';
    ELSE
        PRINT '✗ HANA_LINKED connection: FAILED (no response)';
END TRY
BEGIN CATCH
    PRINT '✗ HANA_LINKED connection: FAILED';
    PRINT '  Error: ' + ERROR_MESSAGE();
END CATCH

PRINT '';

-- Test data access
BEGIN TRY
    PRINT 'Testing Mass_Plan_Proj_Actual table access...';

    DECLARE @hana_count INT;
    DECLARE @hana_count_table TABLE (cnt INT);

    INSERT INTO @hana_count_table
    EXEC ('
        SELECT COUNT(*)
        FROM Mass_Plan_Proj_Actual
        WHERE CATEGORY = ''MASS_PORTFOLIO_ACTUAL''
          AND SUBSTRING(YEARMONTH, 1, 4) IN (''2024'',''2025'')
          AND CUSTOMER_FLAG IN (''B_MASS_MTM'', ''B_MASS_TERM'')
    ') AT HANA_LINKED;

    SELECT @hana_count = cnt FROM @hana_count_table;

    PRINT '✓ Mass_Plan_Proj_Actual accessible';
    PRINT '  Records found (2024-2025 MTM/TERM): ' + CAST(@hana_count AS VARCHAR);

    IF @hana_count = 0
        PRINT '  ⚠️  WARNING: No records found! Check filters or data availability.';
    ELSE IF @hana_count < 100
        PRINT '  ⚠️  WARNING: Very few records found. Expected more data.';
    ELSE
        PRINT '  ✓ Good data volume';

END TRY
BEGIN CATCH
    PRINT '✗ Mass_Plan_Proj_Actual access: FAILED';
    PRINT '  Error: ' + ERROR_MESSAGE();
    PRINT '  Note: Table might not exist or different name/schema';
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- TEST 3: SAMPLE DATA PREVIEW
-- ============================================================================
PRINT '>>> TEST 3: Sample Data Preview';
PRINT '--------------------';
PRINT 'Fetching sample records from SNOWFLAKE...';
PRINT '';

BEGIN TRY
    SELECT TOP 5
        LEFT(YEARMONTH, 4) AS Year,
        RIGHT(YEARMONTH, 2) AS Month,
        CHANNEL,
        ESID_PREMISE,
        CUSTOMER_FLAG,
        BEGINNING AS Beg,
        GAIN AS Gains,
        LOSS,
        ENDING AS [End]
    FROM OPENQUERY(SNOWFLAKE, '
        SELECT *
        FROM Mass_Plan_Proj_Actual
        WHERE CATEGORY = ''MASS_PORTFOLIO_ACTUAL''
          AND LEFT(YEARMONTH,4) IN (''2024'',''2025'')
          AND CUSTOMER_FLAG IN (''B_MASS_MTM'', ''B_MASS_TERM'')
          AND CHANNEL <> ''BD_MASS''
        LIMIT 5
    ');

    PRINT '';
    PRINT '✓ Sample data retrieved successfully';

END TRY
BEGIN CATCH
    PRINT '✗ Sample data retrieval failed';
    PRINT '  Error: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '';

-- ============================================================================
-- SUMMARY
-- ============================================================================
PRINT '======================================================================';
PRINT '      QUICK TEST SUMMARY';
PRINT '======================================================================';
PRINT '';
PRINT 'If all tests passed ✓, you are ready to:';
PRINT '  1. Run 01_setup/create_database_and_tables.sql';
PRINT '  2. Create all stored procedures';
PRINT '  3. Run sp_MTM_Performance_Master_Run';
PRINT '';
PRINT 'If any tests failed ✗, please:';
PRINT '  - Verify linked server configuration';
PRINT '  - Check table names and schema';
PRINT '  - Verify data exists for 2024-2025';
PRINT '  - Check permissions';
PRINT '';
PRINT '======================================================================';
PRINT 'NEXT STEP: Review test results above and proceed if all passed.';
PRINT '======================================================================';

GO
