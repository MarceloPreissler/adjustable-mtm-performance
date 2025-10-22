/*******************************************************************************
 * STORED PROCEDURE: sp_Normalize_Channels
 *
 * PURPOSE: Normalize raw channel data and create segmented view
 * SOURCE TABLE: stg_MTM_Counts_Raw
 * TARGET TABLE: stg_MTM_Counts_Normalized
 *
 * TRANSFORMATIONS:
 * - Map raw channels to MatrixChannel and ScottChannel
 * - Classify RES/BUS from ESID_PREMISE
 * - Classify MTM/TERM from CUSTOMER_FLAG
 * - Calculate swaps (RollOut) and net gains
 * - Deduplicate across data sources
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Normalize_Channels', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Normalize_Channels;
GO

CREATE PROCEDURE dbo.sp_Normalize_Channels
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @RowsProcessed INT;

    -- Clear target table
    TRUNCATE TABLE stg_MTM_Counts_Normalized;
    PRINT 'Cleared stg_MTM_Counts_Normalized';

    -- ========================================================================
    -- NORMALIZE AND TRANSFORM RAW DATA
    -- ========================================================================
    PRINT 'Normalizing channels and segmenting data...';

    INSERT INTO stg_MTM_Counts_Normalized (
        YearLook,
        MonthLook,
        YearMonth,
        MassActualChannel,
        MatrixChannel,
        ScottChannel,
        ESID_PREMISE,
        PremiseType,
        TermMTM,
        BegCount,
        Gains,
        RollIn,
        RollOut,
        Loss,
        EndCount,
        Swaps,
        NetGains
    )
    SELECT
        r.YearLook,
        r.MonthLook,
        r.YearLook + r.MonthLook AS YearMonth,
        r.CHANNEL AS MassActualChannel,

        -- Map to MatrixChannel using lookup table
        COALESCE(lkp.MatrixChannel, 'Unknown') AS MatrixChannel,

        -- Map to ScottChannel using lookup table
        COALESCE(lkp.ScottChannel, 'Reactive') AS ScottChannel,

        r.ESID_PREMISE,

        -- Classify Premise Type (RES vs BUS)
        CASE
            WHEN r.ESID_PREMISE LIKE '%RES%' THEN 'RES'
            WHEN r.ESID_PREMISE LIKE '%BUS%' THEN 'BUS'
            WHEN r.ESID_PREMISE LIKE '%COMM%' THEN 'BUS'
            ELSE 'OTHER'
        END AS PremiseType,

        -- Classify MTM vs TERM
        CASE
            WHEN r.CUSTOMER_FLAG = 'B_MASS_MTM' THEN 'MTM'
            WHEN r.CUSTOMER_FLAG = 'B_MASS_TERM' THEN 'TERM'
            ELSE 'OTHER'
        END AS TermMTM,

        -- Aggregate counts (deduplicate across data sources - take MAX)
        MAX(r.BegCount) AS BegCount,
        MAX(r.Gains) AS Gains,
        MAX(r.RollIn) AS RollIn,
        MAX(r.RollOut) AS RollOut,
        MAX(r.Loss) AS Loss,
        MAX(r.EndCount) AS EndCount,

        -- Swaps = RollOut (customers switching to different products)
        MAX(r.RollOut) AS Swaps,

        -- Net Gains = Gains - Loss
        MAX(r.Gains) - MAX(r.Loss) AS NetGains

    FROM stg_MTM_Counts_Raw r
    LEFT JOIN lkp_Channel_Mapping lkp
        ON r.CHANNEL = lkp.SourceChannel

    GROUP BY
        r.YearLook,
        r.MonthLook,
        r.CHANNEL,
        COALESCE(lkp.MatrixChannel, 'Unknown'),
        COALESCE(lkp.ScottChannel, 'Reactive'),
        r.ESID_PREMISE,
        CASE
            WHEN r.ESID_PREMISE LIKE '%RES%' THEN 'RES'
            WHEN r.ESID_PREMISE LIKE '%BUS%' THEN 'BUS'
            WHEN r.ESID_PREMISE LIKE '%COMM%' THEN 'BUS'
            ELSE 'OTHER'
        END,
        CASE
            WHEN r.CUSTOMER_FLAG = 'B_MASS_MTM' THEN 'MTM'
            WHEN r.CUSTOMER_FLAG = 'B_MASS_TERM' THEN 'TERM'
            ELSE 'OTHER'
        END;

    SET @RowsProcessed = @@ROWCOUNT;

    PRINT 'Normalized ' + CAST(@RowsProcessed AS VARCHAR) + ' records';

    -- ========================================================================
    -- SUMMARY STATISTICS
    -- ========================================================================
    PRINT '======================================================================';
    PRINT 'Channel normalization complete!';
    PRINT '======================================================================';

    -- By Premise Type and Customer Type
    SELECT
        PremiseType,
        TermMTM,
        COUNT(*) AS RecordCount,
        SUM(Gains) AS TotalGains,
        SUM(Loss) AS TotalLosses,
        SUM(Swaps) AS TotalSwaps,
        SUM(NetGains) AS TotalNetGains
    FROM stg_MTM_Counts_Normalized
    GROUP BY PremiseType, TermMTM
    ORDER BY PremiseType, TermMTM;

    -- By Channel (MatrixChannel)
    SELECT
        MatrixChannel,
        COUNT(*) AS RecordCount,
        SUM(Gains) AS TotalGains
    FROM stg_MTM_Counts_Normalized
    GROUP BY MatrixChannel
    ORDER BY SUM(Gains) DESC;

    -- Check for Unknown channels (need mapping)
    DECLARE @UnknownCount INT;
    SELECT @UnknownCount = COUNT(*)
    FROM stg_MTM_Counts_Normalized
    WHERE MatrixChannel = 'Unknown';

    IF @UnknownCount > 0
    BEGIN
        PRINT '';
        PRINT '⚠️  WARNING: ' + CAST(@UnknownCount AS VARCHAR) + ' records have Unknown channels';
        PRINT 'Review and add to lkp_Channel_Mapping table:';

        SELECT DISTINCT MassActualChannel, COUNT(*) AS OccurrenceCount
        FROM stg_MTM_Counts_Normalized
        WHERE MatrixChannel = 'Unknown'
        GROUP BY MassActualChannel
        ORDER BY COUNT(*) DESC;
    END

END
GO

PRINT 'Created stored procedure: sp_Normalize_Channels';
PRINT 'Usage: EXEC sp_Normalize_Channels';
GO
