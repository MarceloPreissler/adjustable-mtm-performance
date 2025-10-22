/*******************************************************************************
 * STORED PROCEDURE: sp_Extract_COGS_and_Plan_Data
 *
 * PURPOSE: Extract COGS (Cost of Goods Sold) and Plan data from EDM
 * TARGET TABLES: stg_COGS_Data, stg_Plan_Data
 *
 * CRITICAL FOR: Contribution Margin calculation (THE MOST IMPORTANT METRIC!)
 *
 * NEED FROM USER:
 * - EDM table locations for COGS data (Actual vs Plan)
 * - FP&A table locations for Plan data (projected gains/losses/revenue)
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Extract_COGS_and_Plan_Data', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Extract_COGS_and_Plan_Data;
GO

CREATE PROCEDURE dbo.sp_Extract_COGS_and_Plan_Data
    @StartYearMonth VARCHAR(6) = '202401',
    @EndYearMonth VARCHAR(6) = '202512'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMsg NVARCHAR(4000);
    DECLARE @RowsCOGS INT;
    DECLARE @RowsPlan INT;

    -- ========================================================================
    -- EXTRACT COGS DATA
    -- ========================================================================
    TRUNCATE TABLE stg_COGS_Data;
    PRINT 'Cleared stg_COGS_Data';

    BEGIN TRY
        PRINT 'Extracting COGS data from EDM...';

        -- ====================================================================
        -- TODO: UPDATE THIS QUERY WITH YOUR ACTUAL EDM TABLE
        -- ====================================================================
        /*
        EXAMPLE - Update with your actual EDM structure:

        INSERT INTO stg_COGS_Data (
            YearMonth,
            PremiseType,
            CustomerType,
            ActualCOGS,
            PlanCOGS,
            COGSVariance
        )
        SELECT
            CONVERT(VARCHAR(6), c.MonthYear, 112) AS YearMonth,  -- Format: YYYYMM
            CASE
                WHEN c.PremiseFlag LIKE '%RES%' THEN 'RES'
                WHEN c.PremiseFlag LIKE '%BUS%' THEN 'BUS'
                ELSE 'OTHER'
            END AS PremiseType,
            CASE
                WHEN c.CustomerFlag = 'B_MASS_MTM' THEN 'MTM'
                WHEN c.CustomerFlag = 'B_MASS_TERM' THEN 'TERM'
                ELSE 'OTHER'
            END AS CustomerType,
            c.ActualCOGS_PerKWH AS ActualCOGS,
            c.PlanCOGS_PerKWH AS PlanCOGS,
            (c.ActualCOGS_PerKWH - c.PlanCOGS_PerKWH) AS COGSVariance
        FROM [EDM_Database].[dbo].COGS_Table c  -- TODO: Update database and table name
        WHERE CONVERT(VARCHAR(6), c.MonthYear, 112) BETWEEN @StartYearMonth AND @EndYearMonth
          AND c.Brand = 'TXU'
          AND c.Portfolio = 'MASS';
        */

        -- ====================================================================
        -- PLACEHOLDER - REPLACE WITH ACTUAL QUERY ABOVE
        -- ====================================================================
        PRINT '======================================================================';
        PRINT 'ACTION REQUIRED: Update sp_Extract_COGS_and_Plan_Data';
        PRINT '======================================================================';
        PRINT 'COGS Data - Please provide:';
        PRINT '1. What is the EDM database and table name for COGS data?';
        PRINT '2. What are the column names for:';
        PRINT '   - Year/Month identifier';
        PRINT '   - Actual COGS ($/kWh)';
        PRINT '   - Plan/Budgeted COGS ($/kWh)';
        PRINT '   - Customer segment (RES/BUS, MTM/TERM)';
        PRINT '======================================================================';

        -- Temporary sample data (DELETE once you have real query)
        /*
        INSERT INTO stg_COGS_Data (YearMonth, PremiseType, CustomerType, ActualCOGS, PlanCOGS, COGSVariance)
        VALUES
            ('202401', 'RES', 'MTM', 0.0850, 0.0800, 0.0050),
            ('202401', 'RES', 'TERM', 0.0840, 0.0800, 0.0040),
            ('202401', 'BUS', 'MTM', 0.0820, 0.0780, 0.0040),
            ('202401', 'BUS', 'TERM', 0.0810, 0.0780, 0.0030);
        PRINT 'Inserted sample COGS data for testing';
        */

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = 'COGS extraction failed: ' + ERROR_MESSAGE();
        PRINT @ErrorMsg;
        -- Continue to plan data even if COGS fails
    END CATCH

    SELECT @RowsCOGS = COUNT(*) FROM stg_COGS_Data;
    PRINT 'COGS records extracted: ' + CAST(@RowsCOGS AS VARCHAR);

    -- ========================================================================
    -- EXTRACT PLAN DATA
    -- ========================================================================
    TRUNCATE TABLE stg_Plan_Data;
    PRINT 'Cleared stg_Plan_Data';

    BEGIN TRY
        PRINT 'Extracting Plan data from FP&A tables...';

        -- ====================================================================
        -- TODO: UPDATE THIS QUERY WITH YOUR ACTUAL FP&A/PLAN TABLE
        -- ====================================================================
        /*
        EXAMPLE - Update with your actual Plan table structure:

        INSERT INTO stg_Plan_Data (
            YearMonth,
            Channel,
            PremiseType,
            CustomerType,
            PlannedGains,
            PlannedLosses,
            PlannedSwaps,
            PlannedTransfers,
            PlannedRevenue,
            PlannedMargin
        )
        SELECT
            CONVERT(VARCHAR(6), p.PlanMonth, 112) AS YearMonth,
            p.Channel,
            CASE
                WHEN p.Segment LIKE '%RES%' THEN 'RES'
                WHEN p.Segment LIKE '%BUS%' THEN 'BUS'
                ELSE 'OTHER'
            END AS PremiseType,
            CASE
                WHEN p.ProductType = 'MTM' THEN 'MTM'
                WHEN p.ProductType = 'TERM' THEN 'TERM'
                ELSE 'OTHER'
            END AS CustomerType,
            p.PlannedGains,
            p.PlannedLosses,
            p.PlannedSwitches AS PlannedSwaps,
            p.PlannedMoves AS PlannedTransfers,
            p.PlannedRevenue,
            p.PlannedContributionMargin AS PlannedMargin
        FROM [FPA_Database].[dbo].Plan_Actuals p  -- TODO: Update database and table name
        WHERE CONVERT(VARCHAR(6), p.PlanMonth, 112) BETWEEN @StartYearMonth AND @EndYearMonth
          AND p.Brand = 'TXU'
          AND p.Portfolio = 'MASS';
        */

        -- ====================================================================
        -- PLACEHOLDER - REPLACE WITH ACTUAL QUERY ABOVE
        -- ====================================================================
        PRINT '======================================================================';
        PRINT 'Plan Data - Please provide:';
        PRINT '1. What is the FP&A database and table name for Plan data?';
        PRINT '2. What are the column names for:';
        PRINT '   - Year/Month identifier';
        PRINT '   - Planned Gains, Losses, Swaps, Transfers';
        PRINT '   - Planned Revenue and Margin';
        PRINT '   - Channel and customer segment';
        PRINT '======================================================================';

        -- Temporary sample data (DELETE once you have real query)
        /*
        INSERT INTO stg_Plan_Data (YearMonth, Channel, PremiseType, CustomerType,
                                   PlannedGains, PlannedLosses, PlannedSwaps, PlannedTransfers,
                                   PlannedRevenue, PlannedMargin)
        VALUES
            ('202401', 'CALL CENTER', 'RES', 'MTM', 500, 200, 50, 25, 125000.00, 45000.00),
            ('202401', 'Web Search', 'RES', 'MTM', 300, 150, 30, 15, 75000.00, 27000.00);
        PRINT 'Inserted sample Plan data for testing';
        */

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = 'Plan data extraction failed: ' + ERROR_MESSAGE();
        PRINT @ErrorMsg;
    END CATCH

    SELECT @RowsPlan = COUNT(*) FROM stg_Plan_Data;
    PRINT 'Plan records extracted: ' + CAST(@RowsPlan AS VARCHAR);

    -- ========================================================================
    -- SUMMARY
    -- ========================================================================
    PRINT '======================================================================';
    PRINT 'COGS and Plan data extraction complete!';
    PRINT 'COGS records: ' + CAST(@RowsCOGS AS VARCHAR);
    PRINT 'Plan records: ' + CAST(@RowsPlan AS VARCHAR);
    PRINT '======================================================================';

    -- Show samples
    IF @RowsCOGS > 0
    BEGIN
        PRINT 'Sample COGS data:';
        SELECT TOP 5 * FROM stg_COGS_Data ORDER BY YearMonth;
    END

    IF @RowsPlan > 0
    BEGIN
        PRINT 'Sample Plan data:';
        SELECT TOP 5 * FROM stg_Plan_Data ORDER BY YearMonth, Channel;
    END

END
GO

PRINT 'Created stored procedure: sp_Extract_COGS_and_Plan_Data';
PRINT 'Usage: EXEC sp_Extract_COGS_and_Plan_Data @StartYearMonth=''202401'', @EndYearMonth=''202512''';
PRINT '';
PRINT '⚠️  ACTION REQUIRED: Update this procedure with your actual EDM and FP&A table details';
GO
