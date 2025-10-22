/*******************************************************************************
 * MASTER ORCHESTRATION PROCEDURE
 *
 * PURPOSE: Run complete MTM Performance Management workflow
 * RUNS: All extraction, transformation, and calculation procedures in sequence
 *
 * WORKFLOW:
 * 1. Extract data from Snowflake, HANA, and other sources
 * 2. Normalize and transform raw data
 * 3. Calculate key metrics (Revenue, Margin, Counts, Usage)
 * 4. Perform actual vs plan analysis
 * 5. Generate summary reports
 *
 * USAGE: EXEC sp_MTM_Performance_Master_Run
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_MTM_Performance_Master_Run', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_MTM_Performance_Master_Run;
GO

CREATE PROCEDURE dbo.sp_MTM_Performance_Master_Run
    @EnableSnowflake BIT = 1,
    @EnableHANA BIT = 1,
    @EnableLocalSQLServer BIT = 0,
    @StartYearMonth VARCHAR(6) = '202401',
    @EndYearMonth VARCHAR(6) = '202512'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @StepStartTime DATETIME;
    DECLARE @ErrorMsg NVARCHAR(4000);
    DECLARE @StepName VARCHAR(100);

    PRINT '======================================================================';
    PRINT '      MTM PERFORMANCE MANAGEMENT - MASTER RUN';
    PRINT '      Started: ' + CONVERT(VARCHAR, @StartTime, 120);
    PRINT '======================================================================';
    PRINT '';

    BEGIN TRY

        -- ====================================================================
        -- STEP 1: EXTRACT MTM COUNTS DATA
        -- ====================================================================
        SET @StepName = 'Extract MTM Counts';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 1: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Extract_MTM_Counts
            @EnableSnowflake = @EnableSnowflake,
            @EnableHANA = @EnableHANA,
            @EnableLocalSQLServer = @EnableLocalSQLServer;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 2: EXTRACT PRICING DATA
        -- ====================================================================
        SET @StepName = 'Extract Pricing Data';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 2: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Extract_Pricing_Data
            @StartYear = LEFT(@StartYearMonth, 4),
            @EndYear = LEFT(@EndYearMonth, 4);

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 3: EXTRACT COGS AND PLAN DATA
        -- ====================================================================
        SET @StepName = 'Extract COGS and Plan Data';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 3: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Extract_COGS_and_Plan_Data
            @StartYearMonth = @StartYearMonth,
            @EndYearMonth = @EndYearMonth;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 4: EXTRACT USAGE DATA
        -- ====================================================================
        SET @StepName = 'Extract Usage Data';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 4: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Extract_Usage_Data
            @StartYearMonth = @StartYearMonth,
            @EndYearMonth = @EndYearMonth;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 5: NORMALIZE CHANNELS AND TRANSFORM DATA
        -- ====================================================================
        SET @StepName = 'Normalize Channels';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 5: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Normalize_Channels;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 6: CALCULATE CONTRIBUTION MARGIN (MOST CRITICAL!)
        -- ====================================================================
        SET @StepName = 'Calculate Contribution Margin';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 6: ' + @StepName + ' ⭐ MOST CRITICAL METRIC';
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Calculate_Contribution_Margin;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 7: CALCULATE INCREMENTAL REVENUE
        -- ====================================================================
        SET @StepName = 'Calculate Incremental Revenue';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 7: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Calculate_Incremental_Revenue;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- STEP 8: ACTUAL VS PLAN ANALYSIS
        -- ====================================================================
        SET @StepName = 'Actual vs Plan Analysis';
        SET @StepStartTime = GETDATE();
        PRINT '>>> STEP 8: ' + @StepName;
        PRINT '    Started: ' + CONVERT(VARCHAR, @StepStartTime, 120);

        EXEC sp_Actual_vs_Plan_Analysis;

        PRINT '    Completed in ' + CAST(DATEDIFF(SECOND, @StepStartTime, GETDATE()) AS VARCHAR) + ' seconds';
        PRINT '';

        -- ====================================================================
        -- FINAL SUMMARY
        -- ====================================================================
        DECLARE @TotalTime INT = DATEDIFF(SECOND, @StartTime, GETDATE());

        PRINT '======================================================================';
        PRINT '      MTM PERFORMANCE MANAGEMENT - RUN COMPLETE';
        PRINT '======================================================================';
        PRINT 'Started:  ' + CONVERT(VARCHAR, @StartTime, 120);
        PRINT 'Finished: ' + CONVERT(VARCHAR, GETDATE(), 120);
        PRINT 'Total Time: ' + CAST(@TotalTime / 60 AS VARCHAR) + ' minutes ' + CAST(@TotalTime % 60 AS VARCHAR) + ' seconds';
        PRINT '';
        PRINT 'OUTPUT TABLES POPULATED:';
        PRINT '  - out_Contribution_Margin      (THE MOST CRITICAL METRIC)';
        PRINT '  - out_Incremental_Revenue';
        PRINT '  - out_Counts_Analysis';
        PRINT '  - out_Actual_vs_Plan';
        PRINT '';
        PRINT 'NEXT STEPS:';
        PRINT '  1. Review out_Contribution_Margin for profitability insights';
        PRINT '  2. Check out_Actual_vs_Plan for target achievement';
        PRINT '  3. Investigate any negative margins or missed targets';
        PRINT '  4. Export results to Excel or reporting tool';
        PRINT '======================================================================';

        -- Show quick summary
        PRINT '';
        PRINT 'QUICK SUMMARY:';
        PRINT '';

        -- Total Contribution Margin
        SELECT
            'TOTAL CONTRIBUTION MARGIN' AS Metric,
            SUM(ContributionMargin) AS TotalValue,
            AVG(MarginPercent) AS AvgMarginPct
        FROM out_Contribution_Margin;

        -- Performance vs Plan
        SELECT
            Status,
            COUNT(*) AS MetricCount
        FROM out_Actual_vs_Plan
        GROUP BY Status;

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = 'ERROR in ' + @StepName + ': ' + ERROR_MESSAGE();
        PRINT '';
        PRINT '======================================================================';
        PRINT '✗ RUN FAILED';
        PRINT '======================================================================';
        PRINT @ErrorMsg;
        PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR);
        PRINT 'Error Severity: ' + CAST(ERROR_SEVERITY() AS VARCHAR);
        PRINT '======================================================================';

        -- Re-throw error
        THROW;
    END CATCH

END
GO

PRINT '';
PRINT '======================================================================';
PRINT 'Created stored procedure: sp_MTM_Performance_Master_Run';
PRINT '======================================================================';
PRINT '';
PRINT 'USAGE:';
PRINT '  EXEC sp_MTM_Performance_Master_Run';
PRINT '    @EnableSnowflake = 1,';
PRINT '    @EnableHANA = 1,';
PRINT '    @EnableLocalSQLServer = 0,';
PRINT '    @StartYearMonth = ''202401'',';
PRINT '    @EndYearMonth = ''202512'';';
PRINT '';
PRINT 'This will run the complete MTM Performance Management workflow.';
PRINT '======================================================================';
GO
