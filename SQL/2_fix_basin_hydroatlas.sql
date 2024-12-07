-- select only useful data from hydroatlas
--DROP TABLE IF EXISTS tempo.hydro_large_catchments;
--CREATE TABLE tempo.hydro_large_catchments AS(
--SELECT shape FROM basinatlas.basinatlas_v10_lev02
--WHERE hybas_id = ANY(ARRAY[1020027430,1020034170])
--UNION ALL 
--SELECT shape FROM basinatlas.basinatlas_v10_lev06
--WHERE hybas_id = ANY(ARRAY[2060000020,2060000030,2060084750,2060000240,2060000250,2060000350])
--UNION ALL
--SELECT shape FROM basinatlas.basinatlas_v10_lev07
--WHERE hybas_id = ANY(ARRAY[2070000360,2070000430,2070000440,2070000530,2070000540,2070784870,2070794800,2070806260,2070085720,
--2070806340,2070812170,2070816130,2070823810,2070829100])
--);

DROP TABLE IF EXISTS tempo.hydro_large_catchments_east;
CREATE TABLE tempo.hydro_large_catchments_east AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id =1020034170
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev06
WHERE hybas_id = ANY(ARRAY[2060000020,2060000030,2060084750,2060000240,2060000250,2060000350])
UNION ALL
SELECT shape FROM basinatlas.basinatlas_v10_lev07
WHERE hybas_id = ANY(ARRAY[2070000360,2070000430,2070000440,2070000530,2070000540,2070784870,2070794800,2070806260,2070085720,
2070806340,2070812170,2070816130,2070823810,2070829100])
);

DROP TABLE IF EXISTS tempo.hydro_large_catchments_middle;
CREATE TABLE tempo.hydro_large_catchments_middle AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = ANY(ARRAY[1030029810,1030040300,1030040310,1030031860,1030040220,1030040250])
);

DROP TABLE IF EXISTS tempo.hydro_large_catchments_west;
CREATE TABLE tempo.hydro_large_catchments_west AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = 1030027430
);

CREATE SCHEMA w2020;
DROP TABLE IF EXISTS w2020.catchments;
CREATE TABLE w2020.catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments_east hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--24522

CREATE SCHEMA w2021;
DROP TABLE IF EXISTS w2021.catchments;
CREATE TABLE w2021.catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments_middle hlcm
  WHERE ST_Within(ba.shape,hlcm.shape)
  )
); --45334

CREATE SCHEMA w2022;
DROP TABLE IF EXISTS w2022.catchments;
CREATE TABLE w2022.catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments_west hlcw
  WHERE ST_Within(ba.shape,hlcw.shape)
  )
); --6422

--CREATE SCHEMA hydroatlas;
--DROP TABLE IF EXISTS hydroatlas.catchments;
--CREATE TABLE hydroatlas.catchments AS (
--SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
--WHERE EXISTS (
--  SELECT 1
--  FROM tempo.hydro_large_catchments hlc
--  WHERE ST_Intersects(ba.shape,hlc.shape)
--  )
--);--79871

ALTER TABLE w2020.catchments
RENAME shape TO geom;
ALTER TABLE w2021.catchments
RENAME shape TO geom;
ALTER TABLE w2022.catchments
RENAME shape TO geom;


CREATE INDEX hydroatlas_catchments_geom_idx ON w2020.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2021.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2022.catchments USING GIST(geom);