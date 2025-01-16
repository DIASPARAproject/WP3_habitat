# launch in OSGEO4W console, (QGIS) line by line

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="basinatlas" D:\eda\BasinATLAS_v10.gdb   -overwrite -progress --config PG_USE_COPY YES

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="riveratlas" D:\eda\RiverATLAS_v10.gdb -overwrite -progress --config PG_USE_COPY YES

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="lakeatlas" D:\eda\LakeATLAS_v10.gdb   -overwrite -progress --config PG_USE_COPY YES

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "
"ALTER TABLE riveratlas.riveratlas_v10 RENAME COLUMN shape TO geom;"