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
    # "h_adriatic": ["catchments", "riversegments"],
    # "h_baltic22to26": ["catchments", "riversegments"],
    # "h_baltic30to31": ["catchments", "riversegments"],
    # "h_baltic27to29_32": ["catchments", "riversegments"],
    # "h_barents": ["catchments", "riversegments"],
    # "h_biscayiberian": ["catchments", "riversegments"],
    # "h_blacksea": ["catchments", "riversegments"],
    # "h_celtic": ["catchments", "riversegments"],
    # "h_iceland": ["catchments", "riversegments"],
    # "h_medcentral": ["catchments", "riversegments"],
    # "h_medeast": ["catchments", "riversegments"],
    # "h_medwest": ["catchments", "riversegments"],
    # "h_norwegian": ["catchments", "riversegments"],
    # "h_nseanorth": ["catchments", "riversegments"],
    # "h_nseasouth": ["catchments", "riversegments"],
    # "h_nseauk": ["catchments", "riversegments"],
    # "h_southatlantic": ["catchments", "riversegments"],
    # "h_southmedcentral": ["catchments", "riversegments"],
    # "h_southmedeast": ["catchments", "riversegments"],
    # "h_southmedwest": ["catchments", "riversegments"],
    # "h_svalbard": ["catchments", "riversegments"],
    # "ref": ["tr_destination_des", "tr_maturity_mat", "tr_species_spe", "tr_category_cat", "tr_lifestage_lfs", "tr_country_cou", "tr_habitatlevel_lev", "tr_version_ver", "tr_nimble_nim", "tr_units_uni", "tr_missvalueqal_mis", "tr_age_age", "tr_icworkinggroup_wkg", "tr_fishingarea_fia", "tr_dataaccess_dta", "tr_trait_tra", "tr_metric_mtr", "tr_objecttype_oty", "tr_outcome_oco", "tr_area_are", "tr_quality_qal", "tr_habitat_hab", "tr_rivernames_riv", "tr_habitattype_hty", "tr_fishway_fiw", "tr_gear_gea", "tr_monitoring_mon", "tr_sex_sex", "tr_traitmethod_trm", "tr_traitnumeric_trn", "tr_traitqualitative_trq", "tr_traitvaluequal_trv"],
    # "refnas": ["tr_area_are", "tr_rivernames_riv", "tg_additional_add", "tr_version_ver"],
    # "refbast": ["tr_area_are", "tr_rivernames_riv"],
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
