import os
import pandas as pd
import pyodbc

def mssql_connect_from_env():
    # Preferred: store full ODBC connection string in secret SQLSERVER_CONN
    conn_str = os.getenv("SQLSERVER_CONN")
    if not conn_str:
        return None
    return pyodbc.connect(conn_str)

def mssql_query_df(sql: str) -> pd.DataFrame:
    conn = mssql_connect_from_env()
    if conn is None:
        return pd.DataFrame()
    try:
        df = pd.read_sql(sql, conn)
        return df
    finally:
        conn.close()
