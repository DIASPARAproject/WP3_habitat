import os
import geopandas as gpd
import sqlalchemy

pg_user = os.getenv("userlocal")
pg_password = os.getenv("passlocal")
pg_host = os.getenv("hostdiaspara")
pg_db = "diaspara"

pg_url = f"postgresql://{pg_user}:{pg_password}@{pg_host}:5432/{pg_db}"
engine = sqlalchemy.create_engine(pg_url)

schemas = {
    "h_adriatic": ["catchments", "riversegments"],
    "h_baltic22to26": ["catchments", "riversegments"],
    "h_baltic30to31": ["catchments", "riversegments"],
    "h_baltic27to29_32": ["catchments", "riversegments"],
    "h_barents": ["catchments", "riversegments"],
    "h_biscayiberian": ["catchments", "riversegments"],
    "h_blacksea": ["catchments", "riversegments"],
    "h_celtic": ["catchments", "riversegments"],
    "h_iceland": ["catchments", "riversegments"],
    "h_medcentral": ["catchments", "riversegments"],
    "h_medeast": ["catchments", "riversegments"],
    "h_medwest": ["catchments", "riversegments"],
    "h_norwegian": ["catchments", "riversegments"],
    "h_nseanorth": ["catchments", "riversegments"],
    "h_nseasouth": ["catchments", "riversegments"],
    "h_nseauk": ["catchments", "riversegments"],
    "h_southatlantic": ["catchments", "riversegments"],
    "h_southmedcentral": ["catchments", "riversegments"],
    "h_southmedeast": ["catchments", "riversegments"],
    "h_southmedwest": ["catchments", "riversegments"],
    "h_svalbard": ["catchments", "riversegments"],
    "ref": ["tr_area_are"],
    "refnas": ["tr_area_are"],
    "refbast": ["tr_area_are"]
}

for schema, tables in schemas.items():
    for table in tables:
        full_table = f'"{schema}"."{table}"'

        if schema in ["ref", "refnas", "refbast"]:
            geom_col = "geom_polygon"
        elif table == "catchments":
            geom_col = "shape"
        elif table == "riversegments":
            geom_col = "geom"
        else:
            geom_col = "shape"

        try:
            gdf = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col=geom_col)
            parquet_file = f"{schema}_{table}.parquet"
            gdf.to_parquet(parquet_file, index=False)
            print(f"Exported {full_table} to {parquet_file}")
        except Exception as e:
            print(f"Error with {full_table}: {e}")

print("Done.")
