import os
import uuid
import geopandas as gpd
import pandas as pd
import sqlalchemy
import zipfile

pg_user = os.getenv("usermercure")
pg_password = os.getenv("passmercure")
pg_host = os.getenv("hostmercure")
pg_db = "diaspara"

pg_url = f"postgresql://{pg_user}:{pg_password}@{pg_host}:5432/{pg_db}"
engine = sqlalchemy.create_engine(pg_url)

schemas = {
    # "h_adriatic": ["catchments", "riversegments","lakes"],
    # "h_baltic22to26": ["catchments", "riversegments","lakes"],
    # "h_baltic30to31": ["catchments", "riversegments","lakes"],
    # "h_baltic27to29_32": ["catchments", "riversegments","lakes"],
    # "h_barents": ["catchments", "riversegments","lakes"],
    # "h_biscayiberian": ["catchments", "riversegments","lakes"],
    # "h_blacksea": ["catchments", "riversegments","lakes"],
    # "h_celtic": ["catchments", "riversegments","lakes"],
    # "h_iceland": ["catchments", "riversegments","lakes"],
    # "h_medcentral": ["catchments", "riversegments","lakes"],
    # "h_medeast": ["catchments", "riversegments","lakes"],
    # "h_medwest": ["catchments", "riversegments","lakes"],
    # "h_norwegian": ["catchments", "riversegments","lakes"],
    # "h_nseanorth": ["catchments", "riversegments","lakes"],
    # "h_nseasouth": ["catchments", "riversegments","lakes"],
    # "h_nseauk": ["catchments", "riversegments","lakes"],
    # "h_southatlantic": ["catchments", "riversegments","lakes"],
    # "h_southmedcentral": ["catchments", "riversegments","lakes"],
    # "h_southmedeast": ["catchments", "riversegments","lakes"],
    # "h_southmedwest": ["catchments", "riversegments","lakes"],
    # "h_svalbard": ["catchments", "riversegments","lakes"],
    "ref": ["tr_habitatlevel_lev", "tr_icworkinggroup_wkg"],
    "refnas": ["tr_area_are", "tr_rivernames_riv"],
    "refbast": ["tr_area_are", "tr_rivernames_riv", "landings_wbast_river_names"],
    "refeel": ["tr_area_are"]
}

def convert_uuids_to_str(df):
    for col in df.columns:
        if df[col].dtype == 'object':
            if df[col].apply(lambda x: isinstance(x, uuid.UUID)).any():
                df[col] = df[col].astype(str)
    return df

for schema, tables in schemas.items():
    parquet_files = []
    
    for table in tables:
        full_table = f'"{schema}"."{table}"'
        try:
            if table == "catchments":
                gdf = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col="shape")
                filename = f"{schema}_{table}.parquet"
                gdf.to_parquet(filename, index=False)
                parquet_files.append(filename)
                print(f"Exported {schema}.{table} with geometry (shape)")

            elif table == "riversegments":
                gdf = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col="geom")
                filename = f"{schema}_{table}.parquet"
                gdf.to_parquet(filename, index=False)
                parquet_files.append(filename)
                print(f"Exported {schema}.{table} with geometry (geom)")

            elif table == "tr_area_are" and schema in ["ref", "refnas", "refbast","refeel"]:
                gdf = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col="geom_polygon")
                filename1 = f"{schema}_{table}_polygon.parquet"
                gdf.to_parquet(filename1, index=False)
                parquet_files.append(filename1)
                print(f"Exported {schema}.{table} with geometry (geom_polygon)")

                gdf_line = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col="geom_line")
                filename2 = f"{schema}_{table}_line.parquet"
                gdf.to_parquet(filename2, index=False)
                parquet_files.append(filename2)
                print(f"Exported {schema}.{table} with geometry (geom_line)")
                
            elif table in ["tr_country_cou", "tr_fishingarea_fia"]:
                gdf = gpd.read_postgis(f"SELECT * FROM {full_table}", engine, geom_col="geom")
                gdf = convert_uuids_to_str(gdf)
                filename = f"{schema}_{table}.parquet"
                gdf.to_parquet(filename, index=False)
                parquet_files.append(filename)
                print(f"Exported {schema}.{table} with geometry (geom)")

            else:
                df = pd.read_sql(f"SELECT * FROM {full_table}", engine)
                df = convert_uuids_to_str(df)
                filename = f"{schema}_{table}.parquet"
                df.to_parquet(filename, index=False)
                parquet_files.append(filename)
                print(f"Exported {schema}.{table} without geometry")

        except Exception as e:
            print(f"Error with {full_table}: {e}")
    
    if parquet_files:
        zip_name = f"{schema}.zip"
        with zipfile.ZipFile(zip_name, 'w') as zf:
            for file in parquet_files:
                zf.write(file)
                os.remove(file) 
        print(f"Created archive: {zip_name}")

print("Done.")
