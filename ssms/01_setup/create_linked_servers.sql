/*******************************************************************************
 * LINKED SERVER SETUP FOR MTM PERFORMANCE MANAGEMENT
 *
 * PURPOSE: Create linked servers to Snowflake and SAP HANA
 * RUN THIS FIRST in your SSMS environment on FTHYN54\MSSQLSERVER2
 *
 * PREREQUISITES:
 * - ODBC drivers installed for Snowflake and SAP HANA
 * - DSN configured in Windows ODBC Data Source Administrator
 * - Appropriate permissions to create linked servers
 *******************************************************************************/

USE master;
GO

-- ============================================================================
-- STEP 1: CREATE SNOWFLAKE LINKED SERVER
-- ============================================================================
-- TODO: Update @datasrc with your Snowflake ODBC DSN name

IF EXISTS (SELECT * FROM sys.servers WHERE name = 'SNOWFLAKE_LINK')
BEGIN
    EXEC sp_dropserver 'SNOWFLAKE_LINK', 'droplogins';
    PRINT 'Dropped existing SNOWFLAKE_LINK';
END

EXEC sp_addlinkedserver
    @server = 'SNOWFLAKE_LINK',
    @srvproduct = 'Snowflake',
    @provider = 'MSDASQL',
    @datasrc = 'SnowflakeDSN';  -- TODO: REPLACE WITH YOUR SNOWFLAKE DSN NAME

PRINT 'Created linked server: SNOWFLAKE_LINK';

-- Configure linked server options
EXEC sp_serveroption 'SNOWFLAKE_LINK', 'rpc', 'true';
EXEC sp_serveroption 'SNOWFLAKE_LINK', 'rpc out', 'true';
EXEC sp_serveroption 'SNOWFLAKE_LINK', 'data access', 'true';
EXEC sp_serveroption 'SNOWFLAKE_LINK', 'use remote collation', 'true';

-- Add login mapping
-- TODO: Update with your Snowflake credentials or use mapped login
EXEC sp_addlinkedsrvlogin
    @rmtsrvname = 'SNOWFLAKE_LINK',
    @useself = 'false',
    @rmtuser = NULL,  -- TODO: Your Snowflake username (or NULL if using DSN credentials)
    @rmtpassword = NULL;  -- TODO: Your Snowflake password (or NULL if using DSN credentials)

PRINT 'Configured SNOWFLAKE_LINK options and login mapping';
GO

-- ============================================================================
-- STEP 2: CREATE SAP HANA LINKED SERVER
-- ============================================================================
-- TODO: Update @datasrc with your SAP HANA ODBC DSN name

IF EXISTS (SELECT * FROM sys.servers WHERE name = 'HANA_LINK')
BEGIN
    EXEC sp_dropserver 'HANA_LINK', 'droplogins';
    PRINT 'Dropped existing HANA_LINK';
END

EXEC sp_addlinkedserver
    @server = 'HANA_LINK',
    @srvproduct = 'SAP HANA',
    @provider = 'MSDASQL',
    @datasrc = 'HANAODBC';  -- TODO: REPLACE WITH YOUR HANA DSN NAME

PRINT 'Created linked server: HANA_LINK';

-- Configure linked server options
EXEC sp_serveroption 'HANA_LINK', 'rpc', 'true';
EXEC sp_serveroption 'HANA_LINK', 'rpc out', 'true';
EXEC sp_serveroption 'HANA_LINK', 'data access', 'true';
EXEC sp_serveroption 'HANA_LINK', 'use remote collation', 'true';

-- Add login mapping
-- TODO: Update with your HANA credentials or use mapped login
EXEC sp_addlinkedsrvlogin
    @rmtsrvname = 'HANA_LINK',
    @useself = 'false',
    @rmtuser = NULL,  -- TODO: Your HANA username (or NULL if using DSN credentials)
    @rmtpassword = NULL;  -- TODO: Your HANA password (or NULL if using DSN credentials)

PRINT 'Configured HANA_LINK options and login mapping';
GO

-- ============================================================================
-- STEP 3: TEST CONNECTIONS
-- ============================================================================

PRINT '======================================================================';
PRINT 'TESTING LINKED SERVER CONNECTIONS...';
PRINT '======================================================================';

-- Test Snowflake connection
BEGIN TRY
    DECLARE @snowflake_test TABLE (result INT);
    INSERT INTO @snowflake_test
    EXEC ('SELECT 1') AT SNOWFLAKE_LINK;

    IF EXISTS (SELECT 1 FROM @snowflake_test)
        PRINT '✓ SNOWFLAKE_LINK connection successful!';
    ELSE
        PRINT '✗ SNOWFLAKE_LINK connection failed - no results returned';
END TRY
BEGIN CATCH
    PRINT '✗ SNOWFLAKE_LINK connection failed: ' + ERROR_MESSAGE();
END CATCH

-- Test HANA connection
BEGIN TRY
    DECLARE @hana_test TABLE (result INT);
    INSERT INTO @hana_test
    EXEC ('SELECT 1 FROM DUMMY') AT HANA_LINK;

    IF EXISTS (SELECT 1 FROM @hana_test)
        PRINT '✓ HANA_LINK connection successful!';
    ELSE
        PRINT '✗ HANA_LINK connection failed - no results returned';
END TRY
BEGIN CATCH
    PRINT '✗ HANA_LINK connection failed: ' + ERROR_MESSAGE();
END CATCH

PRINT '======================================================================';
PRINT 'Linked server setup complete!';
PRINT 'Next step: Run create_database_and_tables.sql';
PRINT '======================================================================';
GO
