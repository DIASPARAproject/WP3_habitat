# launch in OSGEO4W console, (QGIS) line by line

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ices_areas" D:\eda\ices\ICES_areas -overwrite -nlt MULTIPOLYGON -progress --config PG_USE_COPY YES

ogr2ogr.exe -f "PostgreSQL" -a_srs EPSG:4326 PG:"host=localhost port=5432 dbname=diaspara user=postgres password=postgres" -lco SCHEMA="ices_ecoregions" D:\eda\ices\ICES_ecoregions -overwrite -progress --config PG_USE_COPY YES