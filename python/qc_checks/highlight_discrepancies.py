import json
import pandas as pd
from pathlib import Path

def main():
    base = Path(__file__).resolve().parents[2]
    exports = base / "data_exports"
    rules = base / "validation_rules" / "qc_config.yaml"  # not parsed here; placeholder for future highlighting configs

    actuals = exports / "mtm_rollup_actuals.csv"
    if not actuals.exists():
        print("Missing mtm_rollup_actuals.csv. Run validate_actual_counts.py first.")
        return

    df = pd.read_csv(actuals)
    # Simple reasonability checks
    issues = []
    if (df['GainCount'] < 0).any():
        issues.append("Negative GainCount detected.")
    # Optional: add month over month spikes or zeros by channel

    # Save simple report
    report = {
        "rows": len(df),
        "min_gain": int(df['GainCount'].min() or 0),
        "max_gain": int(df['GainCount'].max() or 0),
        "issues": issues
    }
    (exports / "qc_report.json").write_text(json.dumps(report, indent=2))
    print("Wrote qc_report.json")

if __name__ == "__main__":
    main()
