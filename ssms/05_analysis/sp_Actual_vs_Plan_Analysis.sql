/*******************************************************************************
 * STORED PROCEDURE: sp_Actual_vs_Plan_Analysis
 *
 * PURPOSE: Compare Actual vs Plan performance across all key metrics
 * TARGET TABLE: out_Actual_vs_Plan, out_Counts_Analysis
 *
 * COMPARES:
 * - Gains vs Plan (Did we acquire more/fewer customers than expected?)
 * - Losses vs Plan (Did we lose more/fewer customers than expected?)
 * - Swaps vs Plan (Did more/fewer customers switch products?)
 * - Revenue vs Plan
 * - Margin vs Plan
 *
 * STATUS: Met, Exceeded, or Missed targets
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Actual_vs_Plan_Analysis', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Actual_vs_Plan_Analysis;
GO

CREATE PROCEDURE dbo.sp_Actual_vs_Plan_Analysis
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsAnalyzed INT;

    -- ========================================================================
    -- COUNTS ANALYSIS (Gains, Losses, Swaps, Transfers)
    -- ========================================================================
    TRUNCATE TABLE out_Counts_Analysis;
    PRINT 'Calculating Counts Analysis (Actual vs Plan)...';

    INSERT INTO out_Counts_Analysis (
        YearMonth,
        Channel,
        PremiseType,
        CustomerType,
        ActualGains,
        PlannedGains,
        GainsVariance,
        ActualLosses,
        PlannedLosses,
        LossesVariance,
        ActualSwaps,
        PlannedSwaps,
        SwapsVariance,
        ActualTransfers,
        PlannedTransfers,
        TransfersVariance,
        NetChange
    )
    SELECT
        a.YearMonth,
        a.MatrixChannel AS Channel,
        a.PremiseType,
        a.TermMTM AS CustomerType,

        -- Gains
        SUM(a.Gains) AS ActualGains,
        COALESCE(MAX(p.PlannedGains), 0) AS PlannedGains,
        SUM(a.Gains) - COALESCE(MAX(p.PlannedGains), 0) AS GainsVariance,

        -- Losses
        SUM(a.Loss) AS ActualLosses,
        COALESCE(MAX(p.PlannedLosses), 0) AS PlannedLosses,
        SUM(a.Loss) - COALESCE(MAX(p.PlannedLosses), 0) AS LossesVariance,

        -- Swaps (RollOut = customers switching to different products)
        SUM(a.Swaps) AS ActualSwaps,
        COALESCE(MAX(p.PlannedSwaps), 0) AS PlannedSwaps,
        SUM(a.Swaps) - COALESCE(MAX(p.PlannedSwaps), 0) AS SwapsVariance,

        -- Transfers (RollIn for now, ideally match transfers in/out)
        SUM(a.RollIn) AS ActualTransfers,
        COALESCE(MAX(p.PlannedTransfers), 0) AS PlannedTransfers,
        SUM(a.RollIn) - COALESCE(MAX(p.PlannedTransfers), 0) AS TransfersVariance,

        -- Net Change = Gains - Losses - Swaps + Transfers
        (SUM(a.Gains) - SUM(a.Loss) - SUM(a.Swaps) + SUM(a.RollIn)) AS NetChange

    FROM stg_MTM_Counts_Normalized a
    LEFT JOIN stg_Plan_Data p
        ON a.YearMonth = p.YearMonth
        AND a.MatrixChannel = p.Channel
        AND a.PremiseType = p.PremiseType
        AND a.TermMTM = p.CustomerType

    GROUP BY
        a.YearMonth,
        a.MatrixChannel,
        a.PremiseType,
        a.TermMTM;

    SET @RowsAnalyzed = @@ROWCOUNT;
    PRINT 'Analyzed counts for ' + CAST(@RowsAnalyzed AS VARCHAR) + ' segments';

    -- ========================================================================
    -- ACTUAL VS PLAN VARIANCE (All Metrics)
    -- ========================================================================
    TRUNCATE TABLE out_Actual_vs_Plan;
    PRINT 'Calculating Actual vs Plan variance across all metrics...';

    -- Gains Variance
    INSERT INTO out_Actual_vs_Plan (YearMonth, Channel, PremiseType, CustomerType,
                                     MetricName, ActualValue, PlanValue, Variance, VariancePercent, Status)
    SELECT
        YearMonth, Channel, PremiseType, CustomerType,
        'Gains' AS MetricName,
        ActualGains AS ActualValue,
        PlannedGains AS PlanValue,
        GainsVariance AS Variance,
        CASE WHEN PlannedGains > 0 THEN (GainsVariance * 100.0 / PlannedGains) ELSE 0 END AS VariancePercent,
        CASE
            WHEN GainsVariance >= 0 THEN 'Met/Exceeded'
            ELSE 'Missed'
        END AS Status
    FROM out_Counts_Analysis
    WHERE PlannedGains > 0;

    -- Losses Variance (Lower is better, so logic is inverted)
    INSERT INTO out_Actual_vs_Plan (YearMonth, Channel, PremiseType, CustomerType,
                                     MetricName, ActualValue, PlanValue, Variance, VariancePercent, Status)
    SELECT
        YearMonth, Channel, PremiseType, CustomerType,
        'Losses' AS MetricName,
        ActualLosses AS ActualValue,
        PlannedLosses AS PlanValue,
        LossesVariance AS Variance,
        CASE WHEN PlannedLosses > 0 THEN (LossesVariance * 100.0 / PlannedLosses) ELSE 0 END AS VariancePercent,
        CASE
            WHEN LossesVariance <= 0 THEN 'Met/Exceeded'  -- Lower losses is good
            ELSE 'Missed'
        END AS Status
    FROM out_Counts_Analysis
    WHERE PlannedLosses > 0;

    -- Swaps Variance (Lower is better, dilutes margin)
    INSERT INTO out_Actual_vs_Plan (YearMonth, Channel, PremiseType, CustomerType,
                                     MetricName, ActualValue, PlanValue, Variance, VariancePercent, Status)
    SELECT
        YearMonth, Channel, PremiseType, CustomerType,
        'Swaps' AS MetricName,
        ActualSwaps AS ActualValue,
        PlannedSwaps AS PlanValue,
        SwapsVariance AS Variance,
        CASE WHEN PlannedSwaps > 0 THEN (SwapsVariance * 100.0 / PlannedSwaps) ELSE 0 END AS VariancePercent,
        CASE
            WHEN SwapsVariance <= 0 THEN 'Met/Exceeded'  -- Lower swaps is good
            ELSE 'Missed'
        END AS Status
    FROM out_Counts_Analysis
    WHERE PlannedSwaps > 0;

    -- Revenue Variance
    INSERT INTO out_Actual_vs_Plan (YearMonth, Channel, PremiseType, CustomerType,
                                     MetricName, ActualValue, PlanValue, Variance, VariancePercent, Status)
    SELECT
        r.YearMonth, r.Channel, r.PremiseType, r.CustomerType,
        'Revenue' AS MetricName,
        r.IncrementalRevenue AS ActualValue,
        COALESCE(p.PlannedRevenue, 0) AS PlanValue,
        r.IncrementalRevenue - COALESCE(p.PlannedRevenue, 0) AS Variance,
        CASE WHEN p.PlannedRevenue > 0 THEN ((r.IncrementalRevenue - p.PlannedRevenue) * 100.0 / p.PlannedRevenue) ELSE 0 END AS VariancePercent,
        CASE
            WHEN r.IncrementalRevenue >= COALESCE(p.PlannedRevenue, 0) THEN 'Met/Exceeded'
            ELSE 'Missed'
        END AS Status
    FROM out_Incremental_Revenue r
    LEFT JOIN stg_Plan_Data p
        ON r.YearMonth = p.YearMonth
        AND r.Channel = p.Channel
        AND r.PremiseType = p.PremiseType
        AND r.CustomerType = p.CustomerType
    WHERE p.PlannedRevenue IS NOT NULL;

    -- Margin Variance
    INSERT INTO out_Actual_vs_Plan (YearMonth, Channel, PremiseType, CustomerType,
                                     MetricName, ActualValue, PlanValue, Variance, VariancePercent, Status)
    SELECT
        cm.YearMonth, cm.Channel, cm.PremiseType, cm.CustomerType,
        'Contribution Margin' AS MetricName,
        cm.ContributionMargin AS ActualValue,
        COALESCE(p.PlannedMargin, 0) AS PlanValue,
        cm.ContributionMargin - COALESCE(p.PlannedMargin, 0) AS Variance,
        CASE WHEN p.PlannedMargin > 0 THEN ((cm.ContributionMargin - p.PlannedMargin) * 100.0 / p.PlannedMargin) ELSE 0 END AS VariancePercent,
        CASE
            WHEN cm.ContributionMargin >= COALESCE(p.PlannedMargin, 0) THEN 'Met/Exceeded'
            ELSE 'Missed'
        END AS Status
    FROM out_Contribution_Margin cm
    LEFT JOIN stg_Plan_Data p
        ON cm.YearMonth = p.YearMonth
        AND cm.Channel = p.Channel
        AND cm.PremiseType = p.PremiseType
        AND cm.CustomerType = p.CustomerType
    WHERE p.PlannedMargin IS NOT NULL;

    SET @RowsAnalyzed = @@ROWCOUNT;

    -- ========================================================================
    -- SUMMARY RESULTS
    -- ========================================================================
    PRINT '======================================================================';
    PRINT 'ACTUAL VS PLAN ANALYSIS COMPLETE';
    PRINT '======================================================================';

    -- Overall performance summary
    SELECT
        MetricName,
        Status,
        COUNT(*) AS SegmentCount,
        SUM(ActualValue) AS TotalActual,
        SUM(PlanValue) AS TotalPlan,
        SUM(Variance) AS TotalVariance,
        AVG(VariancePercent) AS AvgVariancePct
    FROM out_Actual_vs_Plan
    GROUP BY MetricName, Status
    ORDER BY MetricName, Status;

    -- Highlight biggest misses
    PRINT '';
    PRINT 'Top 10 Biggest Misses:';
    SELECT TOP 10
        YearMonth,
        Channel,
        MetricName,
        ActualValue,
        PlanValue,
        Variance,
        VariancePercent,
        Status
    FROM out_Actual_vs_Plan
    WHERE Status = 'Missed'
    ORDER BY ABS(VariancePercent) DESC;

    -- Highlight biggest wins
    PRINT '';
    PRINT 'Top 10 Biggest Wins (Exceeded Plan):';
    SELECT TOP 10
        YearMonth,
        Channel,
        MetricName,
        ActualValue,
        PlanValue,
        Variance,
        VariancePercent
    FROM out_Actual_vs_Plan
    WHERE Status = 'Met/Exceeded' AND Variance > 0
    ORDER BY VariancePercent DESC;

    PRINT '======================================================================';

END
GO

PRINT 'Created stored procedure: sp_Actual_vs_Plan_Analysis';
PRINT 'Usage: EXEC sp_Actual_vs_Plan_Analysis';
GO
