import pandas as pd
from pathlib import Path

def main():
    base = Path(__file__).resolve().parents[2]
    exports = base / "data_exports"
    src = exports / "mtm_rollup_actuals.csv"
    if not src.exists():
        print("Run validate_actual_counts.py first to create mtm_rollup_actuals.csv")
        return
    df = pd.read_csv(src)

    # Build "swimlane" pivot: BP (proxied by ESID_PREMISE), TermMTM, MatrixChannel -> GainCount
    pivot = pd.pivot_table(
        df,
        index=["YearLook","MonthLook","ESID_PREMISE","TermMTM","MatrixChannel","ScottChannel"],
        values="GainCount",
        aggfunc="sum",
        fill_value=0
    ).reset_index()

    out = exports / "allocation_swimlanes.csv"
    pivot.to_csv(out, index=False)
    print(f"Wrote {out} ({len(pivot):,} rows)")

if __name__ == "__main__":
    main()
