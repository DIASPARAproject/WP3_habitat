-- select only useful data from hydroatlas
DROP TABLE IF EXISTS tempo.hydro_large_catchments;
CREATE TABLE tempo.hydro_large_catchments AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id = ANY(ARRAY[1020027430,1020034170])
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev06
WHERE hybas_id = ANY(ARRAY[2060000020,2060000030,2060084750,2060000240,2060000250,2060000350])
UNION ALL
SELECT shape FROM basinatlas.basinatlas_v10_lev07
WHERE hybas_id = ANY(ARRAY[2070000360,2070000430,2070000440,2070000530,2070000540,2070784870,2070794800,2070806260,2070085720,
2070806340,2070812170,2070816130,2070823810,2070829100])
);

CREATE SCHEMA hydroatlas;
DROP TABLE IF EXISTS hydroatlas.catchments;
CREATE TABLE hydroatlas.catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments hlc
  WHERE ST_Intersects(ba.shape,hlc.shape)
  )
);--79871

ALTER TABLE hydroatlas.catchments
RENAME shape TO geom;

CREATE INDEX hydroatlas_catchments_geom_idx ON hydroatlas.catchments USING GIST(geom);
