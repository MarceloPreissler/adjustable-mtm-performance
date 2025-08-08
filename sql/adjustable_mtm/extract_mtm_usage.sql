-- Snowflake / SQL Server / HANA compatible pattern to adapt per engine
-- Replace schema names with your org specifics in the extractor scripts if needed.
-- MTM usage snapshot by YEARMONTH for MASS portfolio
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
WHERE CATEGORY = 'MASS_PORTFOLIO_ACTUAL'
  AND (BRAND_NAME = 'TXU' OR BRAND_NAME IS NULL)
  AND LEFT(YEARMONTH,4) IN ('2024','2025')
  AND CUSTOMER_FLAG IN ('B_MASS_MTM', 'B_MASS_TERM')
  AND CHANNEL <> 'BD_MASS'
GROUP BY YEARMONTH, CHANNEL, ESID_PREMISE, CUSTOMER_FLAG
ORDER BY YearLook, MonthLook;
