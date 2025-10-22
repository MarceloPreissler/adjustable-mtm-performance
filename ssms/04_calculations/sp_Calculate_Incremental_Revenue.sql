/*******************************************************************************
 * STORED PROCEDURE: sp_Calculate_Incremental_Revenue
 *
 * PURPOSE: Calculate Incremental Revenue with decomposition analysis
 * TARGET TABLE: out_Incremental_Revenue
 *
 * FORMULA: Incremental Revenue = (NewPrice - PriceAtStart) × Quantity
 *
 * DECOMPOSITION (Holding Variables Constant):
 * - Rate Impact: Isolate effect of price changes (hold Consumption & Counts constant)
 * - Consumption Impact: Isolate effect of usage changes (hold Rate & Counts constant)
 * - Counts Impact: Isolate effect of customer count changes (hold Rate & Consumption constant)
 *
 * PURPOSE: Understand what's driving revenue changes - rates, volume, or customers?
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Calculate_Incremental_Revenue', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Calculate_Incremental_Revenue;
GO

CREATE PROCEDURE dbo.sp_Calculate_Incremental_Revenue
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsCalculated INT;

    TRUNCATE TABLE out_Incremental_Revenue;
    PRINT 'Cleared out_Incremental_Revenue';

    PRINT 'Calculating Incremental Revenue with decomposition...';

    -- ========================================================================
    -- CALCULATE INCREMENTAL REVENUE WITH DECOMPOSITION
    -- ========================================================================

    -- First, create a CTE with baseline (prior period) for comparison
    WITH CurrentPeriod AS (
        SELECT
            c.YearMonth,
            c.MatrixChannel AS Channel,
            c.PremiseType,
            c.TermMTM AS CustomerType,
            AVG(p.CurrentPrice) AS CurrentPrice,
            AVG(p.PriceStartOfYear) AS StartPrice,
            SUM(c.Gains) AS CustomerCount,
            AVG(u.AverageUsageKWH) AS AvgConsumption,
            SUM(u.TotalUsageKWH) AS TotalConsumption
        FROM stg_MTM_Counts_Normalized c
        LEFT JOIN stg_MTM_Pricing_Data p
            ON c.YearMonth = LEFT(CONVERT(VARCHAR(10), p.EffectiveDate, 112), 6)
        LEFT JOIN stg_Usage_Data u
            ON c.YearMonth = u.YearMonth
        WHERE c.Gains > 0
        GROUP BY c.YearMonth, c.MatrixChannel, c.PremiseType, c.TermMTM
    )

    INSERT INTO out_Incremental_Revenue (
        YearMonth,
        Channel,
        PremiseType,
        CustomerType,
        PriceAtStart,
        NewPrice,
        PriceChange,
        Quantity,
        IncrementalRevenue,
        RevenueImpact_Rate,
        RevenueImpact_Consumption,
        RevenueImpact_Counts
    )
    SELECT
        YearMonth,
        Channel,
        PremiseType,
        CustomerType,

        -- Pricing
        StartPrice AS PriceAtStart,
        CurrentPrice AS NewPrice,
        (CurrentPrice - StartPrice) AS PriceChange,

        -- Quantity = Customer Count × Average Consumption
        (CustomerCount * AvgConsumption) AS Quantity,

        -- INCREMENTAL REVENUE = (NewPrice - StartPrice) × Quantity
        (CurrentPrice - StartPrice) * (CustomerCount * AvgConsumption) AS IncrementalRevenue,

        -- ====================================================================
        -- DECOMPOSITION ANALYSIS
        -- ====================================================================

        -- 1. RATE IMPACT (Hold Consumption & Counts Constant)
        --    Shows revenue change if ONLY price changed
        (CurrentPrice - StartPrice) * (CustomerCount * AvgConsumption) AS RevenueImpact_Rate,

        -- 2. CONSUMPTION IMPACT (Hold Rate & Counts Constant)
        --    Shows revenue change if ONLY consumption changed
        --    Need to compare to prior period consumption (using TotalConsumption as proxy)
        --    This is simplified - ideally compare to prior month
        0 AS RevenueImpact_Consumption,  -- TODO: Requires prior period comparison

        -- 3. COUNTS IMPACT (Hold Rate & Consumption Constant)
        --    Shows revenue change if ONLY customer count changed
        --    This is simplified - ideally compare to prior period
        0 AS RevenueImpact_Counts  -- TODO: Requires prior period comparison

    FROM CurrentPeriod;

    SET @RowsCalculated = @@ROWCOUNT;

    PRINT 'Calculated Incremental Revenue for ' + CAST(@RowsCalculated AS VARCHAR) + ' segments';

    -- ========================================================================
    -- UPDATE WITH PROPER DECOMPOSITION (Requires Prior Period)
    -- ========================================================================
    -- NOTE: Full decomposition requires comparing to a baseline period
    -- The above calculation shows the rate impact correctly
    -- For consumption and counts impacts, we need to implement period-over-period logic

    PRINT '';
    PRINT 'NOTE: Full decomposition requires prior period comparison';
    PRINT 'Current implementation shows Rate Impact correctly';
    PRINT 'Consumption and Counts impacts require enhancement with period-over-period analysis';

    -- ========================================================================
    -- SUMMARY RESULTS
    -- ========================================================================
    PRINT '======================================================================';
    PRINT 'INCREMENTAL REVENUE CALCULATION COMPLETE';
    PRINT '======================================================================';

    -- Total by Customer Type
    SELECT
        PremiseType,
        CustomerType,
        COUNT(*) AS Segments,
        SUM(IncrementalRevenue) AS TotalIncrementalRevenue,
        SUM(RevenueImpact_Rate) AS TotalRateImpact,
        AVG(PriceChange) AS AvgPriceChange
    FROM out_Incremental_Revenue
    GROUP BY PremiseType, CustomerType
    ORDER BY PremiseType, CustomerType;

    -- By Channel
    SELECT
        Channel,
        SUM(IncrementalRevenue) AS TotalRevenue,
        AVG(PriceChange) AS AvgPriceChange,
        SUM(Quantity) AS TotalQuantity
    FROM out_Incremental_Revenue
    GROUP BY Channel
    ORDER BY SUM(IncrementalRevenue) DESC;

    -- Check for price decreases (negative revenue impact)
    DECLARE @NegativeRevenueCount INT;
    SELECT @NegativeRevenueCount = COUNT(*)
    FROM out_Incremental_Revenue
    WHERE IncrementalRevenue < 0;

    IF @NegativeRevenueCount > 0
    BEGIN
        PRINT '';
        PRINT '⚠️  WARNING: ' + CAST(@NegativeRevenueCount AS VARCHAR) + ' segments have NEGATIVE incremental revenue';
        PRINT 'This means prices were DECREASED in these segments:';

        SELECT TOP 10
            YearMonth,
            Channel,
            PremiseType,
            CustomerType,
            PriceAtStart,
            NewPrice,
            PriceChange,
            IncrementalRevenue
        FROM out_Incremental_Revenue
        WHERE IncrementalRevenue < 0
        ORDER BY IncrementalRevenue ASC;
    END

    PRINT '======================================================================';

END
GO

PRINT 'Created stored procedure: sp_Calculate_Incremental_Revenue';
PRINT 'Usage: EXEC sp_Calculate_Incremental_Revenue';
PRINT '';
PRINT 'NOTE: Enhanced decomposition (Consumption & Counts impacts) requires prior period logic';
GO
