# launch in OSGEO4W console, (QGIS) line by line

ogr2ogr.exe -f "PostgreSQL" PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ices_areas" D:\eda\ices\ICES_areas -nlt MULTIPOLYGON -overwrite  -progress --config PG_USE_COPY YES

ogr2ogr.exe -f "PostgreSQL" PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ices_ecoregions" D:\eda\ices\ICES_ecoregions -nlt MULTIPOLYGON -overwrite -progress --config PG_USE_COPY YES