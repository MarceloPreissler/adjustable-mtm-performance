/*******************************************************************************
 * STORED PROCEDURE: sp_Extract_MTM_Counts
 *
 * PURPOSE: Extract MTM customer counts from Snowflake and HANA using OPENQUERY
 * SOURCE TABLES: Mass_Plan_Proj_Actual (in both Snowflake and HANA)
 * TARGET TABLE: stg_MTM_Counts_Raw
 *
 * EXTRACTS: Beginning, Gains, RollIn, RollOut, Loss, Ending counts
 *           Filtered by: MASS portfolio, TXU brand, 2024-2025, MTM/TERM customers
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Extract_MTM_Counts', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Extract_MTM_Counts;
GO

CREATE PROCEDURE dbo.sp_Extract_MTM_Counts
    @EnableSnowflake BIT = 1,
    @EnableHANA BIT = 1,
    @EnableLocalSQLServer BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorMsg NVARCHAR(4000);

    -- Clear existing data from staging table
    TRUNCATE TABLE stg_MTM_Counts_Raw;
    PRINT 'Cleared stg_MTM_Counts_Raw';

    -- ========================================================================
    -- EXTRACT FROM SNOWFLAKE (using OPENQUERY)
    -- ========================================================================
    IF @EnableSnowflake = 1
    BEGIN
        BEGIN TRY
            PRINT 'Extracting from SNOWFLAKE_LINK...';

            INSERT INTO stg_MTM_Counts_Raw (
                DataSource, YearLook, MonthLook, CHANNEL, ESID_PREMISE,
                CUSTOMER_FLAG, BegCount, Gains, RollIn, RollOut, Loss, EndCount
            )
            SELECT
                'SNOWFLAKE' AS DataSource,
                YearLook,
                MonthLook,
                CHANNEL,
                ESID_PREMISE,
                CUSTOMER_FLAG,
                BegCount,
                Gains,
                RollIn,
                RollOut,
                Loss,
                EndCount
            FROM OPENQUERY(SNOWFLAKE_LINK, '
                SELECT
                    LEFT(YEARMONTH, 4) AS YearLook,
                    RIGHT(YEARMONTH, 2) AS MonthLook,
                    CHANNEL,
                    ESID_PREMISE,
                    CUSTOMER_FLAG,
                    SUM(BEGINNING) AS BegCount,
                    SUM(GAIN) AS Gains,
                    SUM(ROLL_IN) AS RollIn,
                    SUM(ROLL_OUT) AS RollOut,
                    SUM(LOSS) AS Loss,
                    SUM(ENDING) AS EndCount
                FROM Mass_Plan_Proj_Actual
                WHERE CATEGORY = ''MASS_PORTFOLIO_ACTUAL''
                  AND (BRAND_NAME = ''TXU'' OR BRAND_NAME IS NULL)
                  AND LEFT(YEARMONTH,4) IN (''2024'',''2025'')
                  AND CUSTOMER_FLAG IN (''B_MASS_MTM'', ''B_MASS_TERM'')
                  AND CHANNEL <> ''BD_MASS''
                GROUP BY YEARMONTH, CHANNEL, ESID_PREMISE, CUSTOMER_FLAG
            ');

            SET @RowsInserted = @@ROWCOUNT;
            PRINT 'Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' rows from SNOWFLAKE_LINK';

        END TRY
        BEGIN CATCH
            SET @ErrorMsg = 'SNOWFLAKE extraction failed: ' + ERROR_MESSAGE();
            PRINT @ErrorMsg;
            -- Continue to next source even if this fails
        END CATCH
    END

    -- ========================================================================
    -- EXTRACT FROM SAP HANA (using OPENQUERY)
    -- ========================================================================
    IF @EnableHANA = 1
    BEGIN
        BEGIN TRY
            PRINT 'Extracting from HANA_LINK...';

            INSERT INTO stg_MTM_Counts_Raw (
                DataSource, YearLook, MonthLook, CHANNEL, ESID_PREMISE,
                CUSTOMER_FLAG, BegCount, Gains, RollIn, RollOut, Loss, EndCount
            )
            SELECT
                'HANA' AS DataSource,
                YearLook,
                MonthLook,
                CHANNEL,
                ESID_PREMISE,
                CUSTOMER_FLAG,
                BegCount,
                Gains,
                RollIn,
                RollOut,
                Loss,
                EndCount
            FROM OPENQUERY(HANA_LINK, '
                SELECT
                    SUBSTRING(YEARMONTH, 1, 4) AS YearLook,
                    SUBSTRING(YEARMONTH, 5, 2) AS MonthLook,
                    CHANNEL,
                    ESID_PREMISE,
                    CUSTOMER_FLAG,
                    SUM(BEGINNING) AS BegCount,
                    SUM(GAIN) AS Gains,
                    SUM(ROLL_IN) AS RollIn,
                    SUM(ROLL_OUT) AS RollOut,
                    SUM(LOSS) AS Loss,
                    SUM(ENDING) AS EndCount
                FROM Mass_Plan_Proj_Actual
                WHERE CATEGORY = ''MASS_PORTFOLIO_ACTUAL''
                  AND (BRAND_NAME = ''TXU'' OR BRAND_NAME IS NULL)
                  AND SUBSTRING(YEARMONTH, 1, 4) IN (''2024'',''2025'')
                  AND CUSTOMER_FLAG IN (''B_MASS_MTM'', ''B_MASS_TERM'')
                  AND CHANNEL <> ''BD_MASS''
                GROUP BY YEARMONTH, CHANNEL, ESID_PREMISE, CUSTOMER_FLAG
            ');

            SET @RowsInserted = @@ROWCOUNT;
            PRINT 'Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' rows from HANA_LINK';

        END TRY
        BEGIN CATCH
            SET @ErrorMsg = 'HANA extraction failed: ' + ERROR_MESSAGE();
            PRINT @ErrorMsg;
            -- Continue even if this fails
        END CATCH
    END

    -- ========================================================================
    -- OPTIONAL: EXTRACT FROM LOCAL SQL SERVER
    -- ========================================================================
    IF @EnableLocalSQLServer = 1
    BEGIN
        BEGIN TRY
            PRINT 'Extracting from local SQL Server...';

            -- TODO: Update database and schema names for your local SQL Server table
            INSERT INTO stg_MTM_Counts_Raw (
                DataSource, YearLook, MonthLook, CHANNEL, ESID_PREMISE,
                CUSTOMER_FLAG, BegCount, Gains, RollIn, RollOut, Loss, EndCount
            )
            SELECT
                'SQLSERVER' AS DataSource,
                LEFT(YEARMONTH, 4) AS YearLook,
                RIGHT(YEARMONTH, 2) AS MonthLook,
                CHANNEL,
                ESID_PREMISE,
                CUSTOMER_FLAG,
                SUM(BEGINNING) AS BegCount,
                SUM(GAIN) AS Gains,
                SUM(ROLL_IN) AS RollIn,
                SUM(ROLL_OUT) AS RollOut,
                SUM(LOSS) AS Loss,
                SUM(ENDING) AS EndCount
            FROM [YourDatabase].[YourSchema].Mass_Plan_Proj_Actual  -- TODO: UPDATE THIS
            WHERE CATEGORY = 'MASS_PORTFOLIO_ACTUAL'
              AND (BRAND_NAME = 'TXU' OR BRAND_NAME IS NULL)
              AND LEFT(YEARMONTH,4) IN ('2024','2025')
              AND CUSTOMER_FLAG IN ('B_MASS_MTM', 'B_MASS_TERM')
              AND CHANNEL <> 'BD_MASS'
            GROUP BY YEARMONTH, CHANNEL, ESID_PREMISE, CUSTOMER_FLAG;

            SET @RowsInserted = @@ROWCOUNT;
            PRINT 'Inserted ' + CAST(@RowsInserted AS VARCHAR) + ' rows from local SQL Server';

        END TRY
        BEGIN CATCH
            SET @ErrorMsg = 'SQL Server extraction failed: ' + ERROR_MESSAGE();
            PRINT @ErrorMsg;
        END CATCH
    END

    -- ========================================================================
    -- SUMMARY
    -- ========================================================================
    SELECT
        DataSource,
        COUNT(*) AS RecordCount,
        SUM(Gains) AS TotalGains,
        SUM(Loss) AS TotalLosses,
        SUM(RollIn) AS TotalRollIn,
        SUM(RollOut) AS TotalRollOut
    FROM stg_MTM_Counts_Raw
    GROUP BY DataSource;

    DECLARE @TotalRows INT;
    SELECT @TotalRows = COUNT(*) FROM stg_MTM_Counts_Raw;

    PRINT '======================================================================';
    PRINT 'MTM Counts extraction complete!';
    PRINT 'Total records in stg_MTM_Counts_Raw: ' + CAST(@TotalRows AS VARCHAR);
    PRINT '======================================================================';

END
GO

-- Grant execute permissions
-- GRANT EXECUTE ON dbo.sp_Extract_MTM_Counts TO [YourUser];  -- TODO: Update user

PRINT 'Created stored procedure: sp_Extract_MTM_Counts';
PRINT 'Usage: EXEC sp_Extract_MTM_Counts @EnableSnowflake=1, @EnableHANA=1, @EnableLocalSQLServer=0';
GO
