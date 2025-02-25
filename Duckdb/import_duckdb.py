import os
import duckdb

pg_user = os.getenv("userlocal")
pg_password = os.getenv("passlocal")
pg_host = os.getenv("hostdiaspara")

con = duckdb.connect("diaspara_duckdb.db")
con.execute("INSTALL postgres_scanner;")
con.execute("LOAD postgres_scanner;")

pg_connection = f"host={pg_host} port=5432 user={pg_user} password={pg_password} dbname=diaspara"

schemas = {
    "h_adriatic": ["catchments", "riversegments"],
    "h_baltic_26_22": ["catchments", "riversegments"],
    "h_baltic_3031": ["catchments", "riversegments"],
    "h_baltic_3229_27": ["catchments", "riversegments"],
    "h_barent": ["catchments", "riversegments"],
    "h_biscay_iberian": ["catchments", "riversegments"],
    "h_black_sea": ["catchments", "riversegments"],
    "h_celtic": ["catchments", "riversegments"],
    "h_iceland": ["catchments", "riversegments"],
    "h_med_central": ["catchments", "riversegments"],
    "h_med_east": ["catchments", "riversegments"],
    "h_med_west": ["catchments", "riversegments"],
    "h_norwegian": ["catchments", "riversegments"],
    "h_nsea_north": ["catchments", "riversegments"],
    "h_nsea_south": ["catchments", "riversegments"],
    "h_nsea_uk": ["catchments", "riversegments"],
    "h_south_atlantic": ["catchments", "riversegments"],
    "h_south_med_central": ["catchments", "riversegments"],
    "h_south_med_east": ["catchments", "riversegments"],
    "h_south_med_west": ["catchments", "riversegments"],
    "h_svalbard": ["catchments", "riversegments"]
}

for schema, tables in schemas.items():
    for table in tables:
        parquet_file = f"{schema}_{table}.parquet"

        schema_quoted = f'"{schema}"'
        table_quoted = f'"{table}"' 
        view_name = f'"{schema}_{table}_view"'

        con.execute(f"""
            CREATE OR REPLACE VIEW {view_name} AS 
            SELECT * FROM postgres_scan('{pg_connection}', '{schema}', '{table}');
        """)

        con.execute(f"""
            COPY (SELECT * FROM {view_name}) 
            TO '{parquet_file}' (FORMAT 'parquet');
        """)

        print(f"✅ Table {schema}.{table} dumped to {parquet_file}")

con.close()
print("All done !")
