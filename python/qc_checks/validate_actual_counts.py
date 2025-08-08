import pandas as pd
from pathlib import Path

def coalesce_channel_mapping(df):
    # MatrixChannel & ScottChannel mapping logic
    def map_matrix(ch):
        if ch in ('WEB PHONE REACTIVE', 'REACTIVE', 'CALL CENTER'):
            return 'CALL CENTER'
        if ch in ('WEB SEARCH', 'WEB_SEARCH'):
            return 'Web Search'
        if ch in ('ONLINE PARTNER',):
            return 'SOE'
        if ch in ('RAQ','REQUEST A QUOTE','TEE.COM'):
            return 'RAQ'
        if ch in ('OUTBOUND','AGILE','OBTM'):
            return 'Agile'
        if ch in ('DIRECT MAIL','DM'):
            return 'DM'
        if ch in ('BAAT',):
            return 'BAAT'
        if ch in ('PARTNERSHIPS/EVENTS',):
            return 'Partnerships/Events'
        if ch in ('BD_MASS - POLR',):
            return 'POLR'
        if (ch in ('UNK','BD_LBM','LBM','DOOR TO DOOR','SPECIALTY_MKT','') or ch is None):
            return 'Other'
        return 'Unknown'

    df['MatrixChannel'] = df['CHANNEL'].apply(map_matrix)
    df['ScottChannel'] = df['MatrixChannel'].apply(lambda m: 'Reactive' if m in ('CALL CENTER','Partnerships/Events','Other','Unknown') else m)
    df['TermMTM'] = df['CUSTOMER_FLAG'].apply(lambda x: 'TERM' if x == 'B_MASS_TERM' else 'MTM')
    df['MassActualChannel'] = df['CHANNEL']
    return df

def rollup(df):
    grp = (df
        .groupby(['YearLook','MonthLook','MassActualChannel','MatrixChannel','ScottChannel','ESID_PREMISE','TermMTM'], dropna=False)
        .agg(GainCount=('Gains','sum'))
        .reset_index())
    return grp

def main():
    # These CSVs are produced by python/extract/run_extract.py
    p = Path(__file__).resolve().parents[2] / "data_exports"
    candidates = ['mtm_usage_snowflake.csv','mtm_usage_sqlserver.csv','mtm_usage_hana.csv']
    dfs = []
    for c in candidates:
        f = p / c
        if f.exists():
            df = pd.read_csv(f)
            dfs.append(df)
    if not dfs:
        print("No extract files found. Run python/extract/run_extract.py first.")
        return
    df = pd.concat(dfs, ignore_index=True).drop_duplicates()
    df = coalesce_channel_mapping(df)
    rolled = rollup(df)
    out = p / "mtm_rollup_actuals.csv"
    rolled.to_csv(out, index=False)
    print(f"Wrote {out} ({len(rolled):,} rows)")

if __name__ == "__main__":
    main()
