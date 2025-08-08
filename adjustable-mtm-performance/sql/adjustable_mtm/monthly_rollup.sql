-- Roll up Gains by Year/Month/Channels/Term
SELECT
  YearLook,
  MonthLook,
  MassActualChannel,
  MatrixChannel,
  ScottChannel,
  ESID_PREMISE,
  TermMTM,
  SUM(GainCount) AS GainCount
FROM MTM_CHANNEL_ROLLUP_VIEW
GROUP BY
  YearLook, MonthLook, MassActualChannel, MatrixChannel, ScottChannel, ESID_PREMISE, TermMTM
ORDER BY YearLook, MonthLook;
