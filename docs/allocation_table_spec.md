# Allocation Table (Swimlanes) Spec

**Purpose**: single table view for portfolio segmentation to settle cross‑team definitions.

**Columns** (min set):
- YearLook, MonthLook
- ESID_PREMISE (proxy for Premise type: RES/BUS)
- TermMTM (TERM/MTM from CUSTOMER_FLAG)
- MatrixChannel (normalized)
- ScottChannel (consolidated: Reactive or named channel)
- GainCount (sum)

**Extensions** (as fields become available):
- CustomerType/BP type
- ProductType (RES/COMM)
- AccountDetermination (tax)
- ContractClass
