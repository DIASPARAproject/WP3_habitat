# launch in OSGEO4W console, (QGIS) line by line

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ecrinsbasins" D:\eda\ecrins\EcrFEC.sqlite   -overwrite -progress --config PG_USE_COPY YES

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ecrinsrivers" D:\eda\ecrins\EcrRiv.sqlite -overwrite -progress --config PG_USE_COPY YES
