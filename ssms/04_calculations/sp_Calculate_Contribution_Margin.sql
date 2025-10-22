/*******************************************************************************
 * STORED PROCEDURE: sp_Calculate_Contribution_Margin
 *
 * PURPOSE: Calculate Contribution Margin - THE MOST CRITICAL METRIC!
 * TARGET TABLE: out_Contribution_Margin
 *
 * FORMULA: CM = (NewPrice - OldPrice - (ActualCOGS / Usage)) × Quantity
 *
 * Alternative: CM = IncrementalRevenue - (ActualCOGS - PlanCOGS)
 *
 * WHY THIS IS CRITICAL:
 * - Incremental Revenue alone is misleading if COGS increases
 * - CM shows TRUE profitability impact of price changes
 * - Accounts for market power cost fluctuations
 * - Key metric for management decisions
 *
 * DEPENDENCIES:
 * - stg_MTM_Counts_Normalized (customer counts)
 * - stg_MTM_Pricing_Data (old price vs new price)
 * - stg_COGS_Data (actual COGS vs plan COGS)
 * - stg_Usage_Data (consumption for quantity calculation)
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Calculate_Contribution_Margin', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Calculate_Contribution_Margin;
GO

CREATE PROCEDURE dbo.sp_Calculate_Contribution_Margin
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsCalculated INT;

    -- Clear output table
    TRUNCATE TABLE out_Contribution_Margin;
    PRINT 'Cleared out_Contribution_Margin';

    PRINT 'Calculating Contribution Margin (MOST CRITICAL METRIC)...';

    -- ========================================================================
    -- CALCULATE CONTRIBUTION MARGIN
    -- ========================================================================
    INSERT INTO out_Contribution_Margin (
        YearMonth,
        Channel,
        PremiseType,
        CustomerType,
        NewPrice,
        OldPrice,
        ActualCOGS,
        PlanCOGS,
        Usage,
        Quantity,
        IncrementalRevenue,
        COGSVariance,
        ContributionMargin,
        MarginPercent
    )
    SELECT
        c.YearMonth,
        c.MatrixChannel AS Channel,
        c.PremiseType,
        c.TermMTM AS CustomerType,

        -- Pricing
        AVG(p.CurrentPrice) AS NewPrice,
        AVG(p.PriceStartOfYear) AS OldPrice,

        -- COGS
        AVG(cogs.ActualCOGS) AS ActualCOGS,
        AVG(cogs.PlanCOGS) AS PlanCOGS,

        -- Usage
        SUM(u.TotalUsageKWH) AS Usage,

        -- Quantity = Customer Count × Average Usage
        -- Using Gains as proxy for active customer count in period
        (SUM(c.Gains) * AVG(u.AverageUsageKWH)) AS Quantity,

        -- Incremental Revenue = (NewPrice - OldPrice) × Quantity
        (AVG(p.CurrentPrice) - AVG(p.PriceStartOfYear)) *
        (SUM(c.Gains) * AVG(u.AverageUsageKWH)) AS IncrementalRevenue,

        -- COGS Variance = (ActualCOGS - PlanCOGS) × Usage
        (AVG(cogs.ActualCOGS) - AVG(cogs.PlanCOGS)) *
        SUM(u.TotalUsageKWH) AS COGSVariance,

        -- CONTRIBUTION MARGIN = (NewPrice - OldPrice) × Quantity - COGSVariance
        -- OR: (NewPrice - OldPrice - (ActualCOGS / Usage)) × Quantity
        (
            (AVG(p.CurrentPrice) - AVG(p.PriceStartOfYear)) *
            (SUM(c.Gains) * AVG(u.AverageUsageKWH))
        ) - (
            (AVG(cogs.ActualCOGS) - AVG(cogs.PlanCOGS)) *
            SUM(u.TotalUsageKWH)
        ) AS ContributionMargin,

        -- Margin Percent = CM / Revenue
        CASE
            WHEN (AVG(p.CurrentPrice) * (SUM(c.Gains) * AVG(u.AverageUsageKWH))) > 0
            THEN (
                (
                    (AVG(p.CurrentPrice) - AVG(p.PriceStartOfYear)) *
                    (SUM(c.Gains) * AVG(u.AverageUsageKWH))
                ) - (
                    (AVG(cogs.ActualCOGS) - AVG(cogs.PlanCOGS)) *
                    SUM(u.TotalUsageKWH)
                )
            ) / (AVG(p.CurrentPrice) * (SUM(c.Gains) * AVG(u.AverageUsageKWH))) * 100
            ELSE 0
        END AS MarginPercent

    FROM stg_MTM_Counts_Normalized c

    -- Join pricing data (may need adjustment based on how pricing is structured)
    LEFT JOIN stg_MTM_Pricing_Data p
        ON c.YearMonth = LEFT(CONVERT(VARCHAR(10), p.EffectiveDate, 112), 6)

    -- Join COGS data
    LEFT JOIN stg_COGS_Data cogs
        ON c.YearMonth = cogs.YearMonth
        AND c.PremiseType = cogs.PremiseType
        AND c.TermMTM = cogs.CustomerType

    -- Join usage data (may need customer-level join if available)
    LEFT JOIN stg_Usage_Data u
        ON c.YearMonth = u.YearMonth

    WHERE c.Gains > 0  -- Only calculate for periods with customer gains

    GROUP BY
        c.YearMonth,
        c.MatrixChannel,
        c.PremiseType,
        c.TermMTM;

    SET @RowsCalculated = @@ROWCOUNT;

    PRINT 'Calculated Contribution Margin for ' + CAST(@RowsCalculated AS VARCHAR) + ' segments';

    -- ========================================================================
    -- VALIDATION CHECKS
    -- ========================================================================
    PRINT '======================================================================';
    PRINT 'CONTRIBUTION MARGIN CALCULATION COMPLETE';
    PRINT '======================================================================';

    -- Check for NULL values (indicates missing data)
    DECLARE @NullPriceCount INT, @NullCOGSCount INT, @NullUsageCount INT;

    SELECT @NullPriceCount = COUNT(*)
    FROM out_Contribution_Margin
    WHERE NewPrice IS NULL OR OldPrice IS NULL;

    SELECT @NullCOGSCount = COUNT(*)
    FROM out_Contribution_Margin
    WHERE ActualCOGS IS NULL OR PlanCOGS IS NULL;

    SELECT @NullUsageCount = COUNT(*)
    FROM out_Contribution_Margin
    WHERE Usage IS NULL OR Usage = 0;

    IF @NullPriceCount > 0
        PRINT '⚠️  WARNING: ' + CAST(@NullPriceCount AS VARCHAR) + ' records missing pricing data';

    IF @NullCOGSCount > 0
        PRINT '⚠️  WARNING: ' + CAST(@NullCOGSCount AS VARCHAR) + ' records missing COGS data';

    IF @NullUsageCount > 0
        PRINT '⚠️  WARNING: ' + CAST(@NullUsageCount AS VARCHAR) + ' records missing usage data';

    -- ========================================================================
    -- SUMMARY RESULTS
    -- ========================================================================

    -- Total Contribution Margin by Customer Type
    SELECT
        PremiseType,
        CustomerType,
        COUNT(*) AS Segments,
        SUM(IncrementalRevenue) AS TotalIncrementalRevenue,
        SUM(COGSVariance) AS TotalCOGSVariance,
        SUM(ContributionMargin) AS TotalContributionMargin,
        AVG(MarginPercent) AS AvgMarginPercent
    FROM out_Contribution_Margin
    GROUP BY PremiseType, CustomerType
    ORDER BY PremiseType, CustomerType;

    -- Top 10 Channels by Contribution Margin
    SELECT TOP 10
        Channel,
        SUM(ContributionMargin) AS TotalCM,
        AVG(MarginPercent) AS AvgMarginPct,
        SUM(IncrementalRevenue) AS TotalRevenue
    FROM out_Contribution_Margin
    GROUP BY Channel
    ORDER BY SUM(ContributionMargin) DESC;

    -- Flag negative margins (problem areas)
    DECLARE @NegativeMarginCount INT;
    SELECT @NegativeMarginCount = COUNT(*)
    FROM out_Contribution_Margin
    WHERE ContributionMargin < 0;

    IF @NegativeMarginCount > 0
    BEGIN
        PRINT '';
        PRINT '⚠️  ALERT: ' + CAST(@NegativeMarginCount AS VARCHAR) + ' segments have NEGATIVE contribution margin';
        PRINT 'These segments are destroying value (COGS exceeded revenue gains):';

        SELECT TOP 10
            YearMonth,
            Channel,
            PremiseType,
            CustomerType,
            IncrementalRevenue,
            COGSVariance,
            ContributionMargin,
            CASE
                WHEN IncrementalRevenue > 0 THEN 'Revenue positive but COGS too high'
                WHEN IncrementalRevenue < 0 THEN 'Revenue negative'
                ELSE 'Check data'
            END AS Issue
        FROM out_Contribution_Margin
        WHERE ContributionMargin < 0
        ORDER BY ContributionMargin ASC;
    END

    PRINT '======================================================================';
    PRINT 'Next step: Review results and run sp_Calculate_Incremental_Revenue';
    PRINT '======================================================================';

END
GO

PRINT 'Created stored procedure: sp_Calculate_Contribution_Margin';
PRINT 'Usage: EXEC sp_Calculate_Contribution_Margin';
PRINT '';
PRINT '⭐ THIS IS THE MOST CRITICAL METRIC FOR MTM PERFORMANCE MANAGEMENT';
GO
