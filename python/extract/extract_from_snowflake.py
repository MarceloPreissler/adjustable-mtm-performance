import os
import pandas as pd
import snowflake.connector

def sf_connect_from_env():
    user = os.getenv("SNOWFLAKE_USER")
    password = os.getenv("SNOWFLAKE_PASSWORD")
    account = os.getenv("SNOWFLAKE_ACCOUNT")
    warehouse = os.getenv("SNOWFLAKE_WAREHOUSE", "")
    database = os.getenv("SNOWFLAKE_DATABASE", "")
    schema = os.getenv("SNOWFLAKE_SCHEMA", "")
    if not (user and password and account):
        return None
    conn = snowflake.connector.connect(
        user=user, password=password, account=account,
        warehouse=warehouse or None, database=database or None, schema=schema or None
    )
    return conn

def sf_query_df(sql: str) -> pd.DataFrame:
    conn = sf_connect_from_env()
    if conn is None:
        return pd.DataFrame()
    cur = conn.cursor()
    try:
        cur.execute(sql)
        df = cur.fetch_pandas_all()
        return df
    finally:
        cur.close()
        conn.close()
