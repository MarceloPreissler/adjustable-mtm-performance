/*******************************************************************************
 * STORED PROCEDURE: sp_Extract_Usage_Data
 *
 * PURPOSE: Extract customer usage/consumption from AMS 15-minute interval table
 * TARGET TABLE: stg_Usage_Data
 *
 * CRITICAL FOR: Consumption Analysis and usage bucket segmentation
 *
 * NEED FROM USER:
 * - AMS usage table name and location
 * - How usage data is structured (intervals, aggregations, etc.)
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Extract_Usage_Data', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Extract_Usage_Data;
GO

CREATE PROCEDURE dbo.sp_Extract_Usage_Data
    @StartYearMonth VARCHAR(6) = '202401',
    @EndYearMonth VARCHAR(6) = '202512'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMsg NVARCHAR(4000);
    DECLARE @RowsInserted INT;

    TRUNCATE TABLE stg_Usage_Data;
    PRINT 'Cleared stg_Usage_Data';

    BEGIN TRY
        PRINT 'Extracting usage data from AMS table...';

        -- ====================================================================
        -- TODO: UPDATE THIS QUERY WITH YOUR ACTUAL AMS USAGE TABLE
        -- ====================================================================
        /*
        EXAMPLE - Update with your actual AMS table structure:

        INSERT INTO stg_Usage_Data (
            CustomerID,
            ESIID,
            YearMonth,
            TotalUsageKWH,
            TotalUsageMWH,
            AverageUsageKWH,
            UsageBucket
        )
        SELECT
            u.BusinessPartnerID AS CustomerID,
            u.ESIID,
            CONVERT(VARCHAR(6), u.UsageMonth, 112) AS YearMonth,
            SUM(u.UsageKWH) AS TotalUsageKWH,
            SUM(u.UsageKWH) / 1000.0 AS TotalUsageMWH,
            AVG(u.UsageKWH) AS AverageUsageKWH,
            CASE
                WHEN SUM(u.UsageKWH) / 1000.0 < 100 THEN '<100 MWh'
                WHEN SUM(u.UsageKWH) / 1000.0 >= 100 AND SUM(u.UsageKWH) / 1000.0 < 500 THEN '100-500 MWh'
                WHEN SUM(u.UsageKWH) / 1000.0 >= 500 AND SUM(u.UsageKWH) / 1000.0 < 1000 THEN '500-1000 MWh'
                ELSE '>1000 MWh'
            END AS UsageBucket
        FROM [AMS_Database].[dbo].Usage_15Min u  -- TODO: Update database and table name
        WHERE CONVERT(VARCHAR(6), u.UsageMonth, 112) BETWEEN @StartYearMonth AND @EndYearMonth
          AND u.CustomerType IN ('B_MASS_MTM', 'B_MASS_TERM')
        GROUP BY
            u.BusinessPartnerID,
            u.ESIID,
            CONVERT(VARCHAR(6), u.UsageMonth, 112);
        */

        -- ====================================================================
        -- PLACEHOLDER - REPLACE WITH ACTUAL QUERY ABOVE
        -- ====================================================================
        PRINT '======================================================================';
        PRINT 'ACTION REQUIRED: Update sp_Extract_Usage_Data';
        PRINT '======================================================================';
        PRINT 'Usage Data - Please provide:';
        PRINT '1. What is the AMS database and table name for usage data?';
        PRINT '2. Is usage stored in:';
        PRINT '   - 15-minute intervals?';
        PRINT '   - Already aggregated by month?';
        PRINT '   - Another format?';
        PRINT '3. What are the column names for:';
        PRINT '   - Customer ID / Business Partner';
        PRINT '   - ESIID';
        PRINT '   - Usage amount (kWh)';
        PRINT '   - Date/time';
        PRINT '4. Usage bucket thresholds:';
        PRINT '   - Caroline mentioned filtering >100 MWh customers';
        PRINT '   - What other buckets are needed?';
        PRINT '======================================================================';

        -- Temporary sample data (DELETE once you have real query)
        /*
        INSERT INTO stg_Usage_Data (CustomerID, ESIID, YearMonth,
                                    TotalUsageKWH, TotalUsageMWH, AverageUsageKWH, UsageBucket)
        VALUES
            ('CUST001', '10000000000001', '202401', 15000.0, 15.0, 15000.0, '<100 MWh'),
            ('CUST002', '10000000000002', '202401', 250000.0, 250.0, 250000.0, '100-500 MWh'),
            ('CUST003', '10000000000003', '202401', 750000.0, 750.0, 750000.0, '500-1000 MWh');
        PRINT 'Inserted sample usage data for testing';
        */

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = 'Usage data extraction failed: ' + ERROR_MESSAGE();
        PRINT @ErrorMsg;
        THROW;
    END CATCH

    SELECT @RowsInserted = COUNT(*) FROM stg_Usage_Data;

    PRINT '======================================================================';
    PRINT 'Usage data extraction complete!';
    PRINT 'Total records: ' + CAST(@RowsInserted AS VARCHAR);
    PRINT '======================================================================';

    -- Summary by usage bucket
    IF @RowsInserted > 0
    BEGIN
        SELECT
            UsageBucket,
            COUNT(*) AS CustomerCount,
            SUM(TotalUsageMWH) AS TotalMWH,
            AVG(TotalUsageMWH) AS AvgMWH
        FROM stg_Usage_Data
        GROUP BY UsageBucket
        ORDER BY
            CASE UsageBucket
                WHEN '<100 MWh' THEN 1
                WHEN '100-500 MWh' THEN 2
                WHEN '500-1000 MWh' THEN 3
                WHEN '>1000 MWh' THEN 4
                ELSE 5
            END;
    END

END
GO

PRINT 'Created stored procedure: sp_Extract_Usage_Data';
PRINT 'Usage: EXEC sp_Extract_Usage_Data @StartYearMonth=''202401'', @EndYearMonth=''202512''';
PRINT '';
PRINT '⚠️  ACTION REQUIRED: Update this procedure with your actual AMS table details';
GO
