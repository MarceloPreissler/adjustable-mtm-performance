/*******************************************************************************
 * STORED PROCEDURE: sp_Extract_Pricing_Data
 *
 * PURPOSE: Extract customer pricing data (energy charges) from StatusFact table
 * TARGET TABLE: stg_MTM_Pricing_Data
 *
 * CRITICAL FOR: Incremental Revenue and Contribution Margin calculations
 *
 * NEED FROM USER:
 * - Actual table name for StatusFact (or equivalent pricing table)
 * - Schema location
 * - Column names for customer ID, ESIID, pricing fields
 *******************************************************************************/

USE MTM_Performance;
GO

IF OBJECT_ID('dbo.sp_Extract_Pricing_Data', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Extract_Pricing_Data;
GO

CREATE PROCEDURE dbo.sp_Extract_Pricing_Data
    @StartYear INT = 2024,
    @EndYear INT = 2025
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ErrorMsg NVARCHAR(4000);
    DECLARE @RowsInserted INT;

    -- Clear existing data
    TRUNCATE TABLE stg_MTM_Pricing_Data;
    PRINT 'Cleared stg_MTM_Pricing_Data';

    BEGIN TRY
        PRINT 'Extracting pricing data from StatusFact table...';

        -- ====================================================================
        -- TODO: UPDATE THIS QUERY WITH YOUR ACTUAL TABLE AND COLUMN NAMES
        -- ====================================================================
        /*
        EXAMPLE - Update with your actual table structure:

        INSERT INTO stg_MTM_Pricing_Data (
            CustomerID,
            ESIID,
            EffectiveDate,
            PriceStartOfYear,
            CurrentPrice,
            PriceChange,
            PriceBand,
            BaseCharge
        )
        SELECT
            p.BusinessPartnerID AS CustomerID,
            p.ESIID,
            p.EffectiveDate,
            p.EnergyChargeJan2024 AS PriceStartOfYear,  -- TODO: Update column name
            p.CurrentEnergyCharge AS CurrentPrice,       -- TODO: Update column name
            (p.CurrentEnergyCharge - p.EnergyChargeJan2024) AS PriceChange,
            CASE
                WHEN p.CurrentEnergyCharge < 0.15 THEN '<15c'
                WHEN p.CurrentEnergyCharge >= 0.15 AND p.CurrentEnergyCharge < 0.18 THEN '15-18c'
                ELSE '>18c'
            END AS PriceBand,
            p.BaseCharge
        FROM [YourDatabase].[YourSchema].StatusFact p  -- TODO: Update database and schema
        WHERE p.Year BETWEEN @StartYear AND @EndYear
          AND p.CustomerType IN ('B_MASS_MTM', 'B_MASS_TERM')
          AND p.Brand = 'TXU';
        */

        -- ====================================================================
        -- PLACEHOLDER QUERY - REPLACE WITH ACTUAL QUERY ABOVE
        -- ====================================================================
        PRINT '======================================================================';
        PRINT 'ACTION REQUIRED: Update sp_Extract_Pricing_Data with actual query';
        PRINT '======================================================================';
        PRINT 'Please provide the following information:';
        PRINT '1. What is the actual name of your pricing/StatusFact table?';
        PRINT '2. What database and schema is it in?';
        PRINT '3. What are the column names for:';
        PRINT '   - Customer ID / Business Partner ID';
        PRINT '   - ESIID';
        PRINT '   - Energy Charge ($/kWh) at start of year';
        PRINT '   - Current Energy Charge ($/kWh)';
        PRINT '   - Base Charge';
        PRINT '   - Effective Date';
        PRINT '======================================================================';

        -- Temporary: Insert sample data structure for testing
        -- DELETE THIS SECTION once you have real query
        PRINT 'NOTE: Using placeholder data for now. Replace with actual query.';

        /*
        INSERT INTO stg_MTM_Pricing_Data (
            CustomerID, ESIID, EffectiveDate,
            PriceStartOfYear, CurrentPrice, PriceChange, PriceBand, BaseCharge
        )
        VALUES
            ('SAMPLE001', '10000000000001', '2024-01-01', 0.1400, 0.1550, 0.0150, '15-18c', 9.95),
            ('SAMPLE002', '10000000000002', '2024-01-01', 0.1600, 0.1750, 0.0150, '15-18c', 9.95);

        PRINT 'Inserted sample data for testing';
        */

    END TRY
    BEGIN CATCH
        SET @ErrorMsg = 'Pricing data extraction failed: ' + ERROR_MESSAGE();
        PRINT @ErrorMsg;
        THROW;
    END CATCH

    -- Summary
    SELECT @RowsInserted = COUNT(*) FROM stg_MTM_Pricing_Data;

    PRINT '======================================================================';
    PRINT 'Pricing data extraction complete!';
    PRINT 'Total records in stg_MTM_Pricing_Data: ' + CAST(@RowsInserted AS VARCHAR);
    PRINT '======================================================================';

    -- Show sample of extracted data
    SELECT TOP 10 * FROM stg_MTM_Pricing_Data ORDER BY EffectiveDate DESC;

END
GO

PRINT 'Created stored procedure: sp_Extract_Pricing_Data';
PRINT 'Usage: EXEC sp_Extract_Pricing_Data @StartYear=2024, @EndYear=2025';
PRINT '';
PRINT '⚠️  ACTION REQUIRED: Update this procedure with your actual pricing table details';
GO
