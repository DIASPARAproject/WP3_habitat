-- the table riverbasins is only available for download as laea, we transform it back to wgs84

ALTER TABLE ccm21.seaoutlets
  ALTER COLUMN shape
   TYPE geometry(MultiPolygon, 4326)
  USING ST_Transform(shape, 4326);

ALTER TABLE ccm21.seaoutlets RENAME COLUMN shape TO geom;


ALTER TABLE ccm21.ccm21_laea_riverbasins
  ALTER COLUMN geom
   TYPE geometry(MultiPolygon, 4326)
  USING ST_Transform(geom, 4326);
  
ALTER TABLE ccm21.ccm21_laea_riverbasins RENAME TO ccm21.ccm21_wgs84_riverbasins;

-- fix the basins we do not want to have (Igris Euphrate, basins flowing to black sea) Volga ...

-- Tigris and black sea
DELETE FROM w2017.catchments WHERE wso_id = ANY(ARRAY[2294495,2294484]); --46811
DELETE FROM w2017.riversegments WHERE wso_id = ANY(ARRAY[2294495,2294484]); --46811
--DELETE FROM w2017.namedrivers WHERE wso_id = ANY(ARRAY[2294495,2294484]);
DELETE FROM w2017.seaoutlets WHERE wso_id = ANY(ARRAY[2294495,2294484]); --2

-- VOLGA into the black sea

DELETE FROM w2013.catchments WHERE wso_id = ANY(ARRAY[1779618,1457128,1457725,1460380,1456942,1457138,1457780,1457789]); --170589
DELETE FROM w2013.riversegments WHERE wso_id = ANY(ARRAY[1779618,1457128,1457725,1460380,1456942,1457138,1457780,1457789]); --170588
DELETE FROM w2013.namedrivers WHERE wso_id = ANY(ARRAY[1779618,1457128,1457725,1460380,1456942,1457138,1457780,1457789]); --17
DELETE FROM w2013.seaoutlets WHERE wso_id = ANY(ARRAY[1779618,1457128,1457725,1460380,1456942,1457138,1457780,1457789]); --8
-- some catchments remain along the black sea
TODO

-- change ownership and permissions to tables, check that indexes exist

TODO