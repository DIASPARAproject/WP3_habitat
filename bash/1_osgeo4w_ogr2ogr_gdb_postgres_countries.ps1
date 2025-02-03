# launch in OSGEO4W console, (QGIS) line by line

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="tempo" D:\eda\countries -nlt MULTIPOLYGON  -overwrite -progress --config PG_USE_COPY YES

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "ALTER TABLE tempo.ne_10m_admin_0_countries rename COLUMN wkb_geometry  to geom;" 