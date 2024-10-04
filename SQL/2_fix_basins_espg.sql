-- the table riverbasins is only available for download as laea, we transform it back to wgs84

ALTER TABLE ccm21.ccm21_laea_riverbasins
  ALTER COLUMN geom
   TYPE geometry(MultiPolygon, 4326)
  USING ST_Transform(geom, 4326);
  
ALTER TABLE ccm21.ccm21_laea_riverbasins RENAME TO ccm21.ccm21_wgs84_riverbasins;

-- fix the basins we do not want to have (Igris Euphrate, basins flowing to black sea) Volga ...

-- Tigris and black sea
DELETE FROM w2017.catchments WHERE wso_id = ANY(ARRAY[2294495,2294484]);
DELETE FROM w2017.riversegments WHERE wso_id = ANY(ARRAY[2294495,2294484]);
DELETE FROM w2017.namedrivers WHERE wso_id = ANY(ARRAY[2294495,2294484]);
DELETE FROM w2017.seaoutlets WHERE wso_id = ANY(ARRAY[2294495,2294484]);

-- VOLGA

TODO

-- change ownership and permissions to tables, check that indexes exist

TODO