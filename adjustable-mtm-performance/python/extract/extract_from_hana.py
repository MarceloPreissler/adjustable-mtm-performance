import os
import pandas as pd
from hdbcli import dbapi

def hana_connect_from_env():
    host = os.getenv("HANA_HOST")
    port = os.getenv("HANA_PORT")
    user = os.getenv("HANA_USER")
    password = os.getenv("HANA_PASSWORD")
    if not (host and port and user and password):
        return None
    conn = dbapi.connect(address=host, port=int(port), user=user, password=password)
    schema = os.getenv("HANA_SCHEMA")
    if schema:
        cursor = conn.cursor()
        cursor.execute(f'SET SCHEMA "{schema}"')
        cursor.close()
    return conn

def hana_query_df(sql: str) -> pd.DataFrame:
    conn = hana_connect_from_env()
    if conn is None:
        return pd.DataFrame()
    try:
        cur = conn.cursor()
        cur.execute(sql)
        cols = [c[0] for c in cur.description]
        rows = cur.fetchall()
        return pd.DataFrame(rows, columns=cols)
    finally:
        cur.close()
        conn.close()
