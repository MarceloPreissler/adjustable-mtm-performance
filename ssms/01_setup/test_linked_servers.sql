/*******************************************************************************
 * LINKED SERVER VERIFICATION FOR MTM PERFORMANCE MANAGEMENT
 *
 * PURPOSE: Test existing linked servers to Snowflake and SAP HANA
 *
 * EXISTING LINKED SERVERS:
 * - SNOWFLAKE (already configured)
 * - HANA_LINKED (already configured)
 *
 * NOTE: You already have these linked servers set up!
 *       This script just verifies they work correctly.
 *******************************************************************************/

USE master;
GO

PRINT '======================================================================';
PRINT 'TESTING EXISTING LINKED SERVER CONNECTIONS...';
PRINT '======================================================================';
PRINT '';

-- ============================================================================
-- TEST SNOWFLAKE LINKED SERVER
-- ============================================================================
PRINT 'Testing SNOWFLAKE linked server...';

BEGIN TRY
    -- Check if linked server exists
    IF NOT EXISTS (SELECT * FROM sys.servers WHERE name = 'SNOWFLAKE')
    BEGIN
        PRINT '✗ ERROR: Linked server ''SNOWFLAKE'' not found!';
        PRINT '  Please verify the linked server exists with: SELECT * FROM sys.servers';
    END
    ELSE
    BEGIN
        -- Test connection
        DECLARE @snowflake_test TABLE (result INT);
        INSERT INTO @snowflake_test
        EXEC ('SELECT 1') AT SNOWFLAKE;

        IF EXISTS (SELECT 1 FROM @snowflake_test)
        BEGIN
            PRINT '✓ SNOWFLAKE connection successful!';
            PRINT '  Linked server is working correctly.';
        END
        ELSE
        BEGIN
            PRINT '✗ SNOWFLAKE connection failed - no results returned';
        END
    END
END TRY
BEGIN CATCH
    PRINT '✗ SNOWFLAKE connection failed: ' + ERROR_MESSAGE();
    PRINT '  Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '  Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT '  Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
END CATCH

PRINT '';

-- ============================================================================
-- TEST HANA_LINKED SERVER
-- ============================================================================
PRINT 'Testing HANA_LINKED server...';

BEGIN TRY
    -- Check if linked server exists
    IF NOT EXISTS (SELECT * FROM sys.servers WHERE name = 'HANA_LINKED')
    BEGIN
        PRINT '✗ ERROR: Linked server ''HANA_LINKED'' not found!';
        PRINT '  Please verify the linked server exists with: SELECT * FROM sys.servers';
    END
    ELSE
    BEGIN
        -- Test connection (HANA uses DUMMY table for test queries)
        DECLARE @hana_test TABLE (result INT);
        INSERT INTO @hana_test
        EXEC ('SELECT 1 FROM DUMMY') AT HANA_LINKED;

        IF EXISTS (SELECT 1 FROM @hana_test)
        BEGIN
            PRINT '✓ HANA_LINKED connection successful!';
            PRINT '  Linked server is working correctly.';
        END
        ELSE
        BEGIN
            PRINT '✗ HANA_LINKED connection failed - no results returned';
        END
    END
END TRY
BEGIN CATCH
    PRINT '✗ HANA_LINKED connection failed: ' + ERROR_MESSAGE();
    PRINT '  Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR);
    PRINT '  Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
    PRINT '  Error State: ' + CAST(ERROR_STATE() AS VARCHAR);
END CATCH

PRINT '';

-- ============================================================================
-- SHOW LINKED SERVER DETAILS
-- ============================================================================
PRINT '======================================================================';
PRINT 'EXISTING LINKED SERVERS:';
PRINT '======================================================================';

SELECT
    name AS LinkedServerName,
    product AS Product,
    provider AS Provider,
    data_source AS DataSource,
    is_remote_login_enabled AS RemoteLoginEnabled
FROM sys.servers
WHERE name IN ('SNOWFLAKE', 'HANA_LINKED')
ORDER BY name;

PRINT '';
PRINT '======================================================================';
PRINT 'VERIFICATION COMPLETE!';
PRINT '';
PRINT 'If both connections tested successfully, you are ready to proceed.';
PRINT 'Next step: Run create_database_and_tables.sql';
PRINT '======================================================================';
GO
