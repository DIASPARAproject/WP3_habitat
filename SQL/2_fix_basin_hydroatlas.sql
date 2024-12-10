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

-- Selecting southern mediterranean data from hydroatlas
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


-- Selecting european data from hydroatlas (large catchments)
DROP TABLE IF EXISTS tempo.hydro_large_catchments_europe;
CREATE TABLE tempo.hydro_large_catchments_europe AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = ANY(ARRAY[2030000010,2030003440,2030005690,2030006590,2030006600,2030007930,2030007940,2030008490,2030008500,
							2030009230,2030012730,2030014550,2030016230,2030018240,2030020320,2030024230,2030026030,2030028220,
							2030030090,2030033480,2030037990,2030041390,2030045150,2030046500,2030047500,2030048590,2030048790,
							2030054200,2030056770,2030057170,2030059370,2030059450,2030059500,2030068680])
);

-- Selecting european data from hydroatlas (small catchments)
DROP TABLE IF EXISTS tempo.hydro_small_catchments_europe;
CREATE TABLE tempo.hydro_small_catchments_europe AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments_europe hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--77682


-- Creating regional subdivisions following the ccm
CREATE SCHEMA h2000;
DROP TABLE IF EXISTS h2000.catchments;
CREATE TABLE h2000.catchments AS
SELECT *
FROM tempo.hydro_small_catchments_europe hsce
WHERE (
  SELECT SUM(ST_Area(ST_Intersection(hsce.shape, c.shape)))
  FROM w2000.catchments c
  WHERE ST_Intersects(hsce.shape, c.shape)
) / ST_Area(hsce.shape) >= 0.9;--5727

CREATE TABLE h2000.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2000.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--6313

SELECT * FROM h2000.catchments;

CREATE SCHEMA h2001;
DROP TABLE IF EXISTS h2001.catchments;
CREATE TABLE h2001.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2001.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--2404


CREATE SCHEMA h2002;
DROP TABLE IF EXISTS h2002.catchments;
CREATE TABLE h2002.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2002.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--3387


CREATE SCHEMA h2003;
DROP TABLE IF EXISTS h2003.catchments;
CREATE TABLE h2003.catchments AS
SELECT *
FROM tempo.hydro_small_catchments_europe hsce
WHERE (
  SELECT SUM(ST_Area(ST_Intersection(hsce.shape, c.shape)))
  FROM w2003.catchments c
  WHERE ST_Intersects(hsce.shape, c.shape)
) / ST_Area(hsce.shape) >= 0.9;--5602



CREATE TABLE h2003.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2003.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  --AND ST_Area(ST_Intersection(c.shape, hsce.shape)) / ST_Area(c.shape) >= 0.9 --5215, missing polygons
  )
);--6051


CREATE SCHEMA h2004;
DROP TABLE IF EXISTS h2004.catchments;
CREATE TABLE h2004.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2004.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--4497

CREATE SCHEMA h2007;
DROP TABLE IF EXISTS h2007.catchments;
CREATE TABLE h2007.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2007.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--9751

CREATE SCHEMA h2008;
DROP TABLE IF EXISTS h2008.catchments;
CREATE TABLE h2008.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2008.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--5189

CREATE SCHEMA h2009;
DROP TABLE IF EXISTS h2009.catchments;
CREATE TABLE h2009.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2009.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--6137


--CREATE SCHEMA h2010;
--DROP TABLE IF EXISTS h2010.catchments;
--CREATE TABLE h2010.catchments AS (
--SELECT * FROM tempo.hydro_small_catchments_europe hsce
--WHERE EXISTS (
--  SELECT 1
--  FROM w2010.catchments c 
--  WHERE ST_Intersects(hsce.shape,c.shape)
--  )
--); --Canaries


CREATE SCHEMA h2013;
DROP TABLE IF EXISTS h2013.catchments;
CREATE TABLE h2013.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2013.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--7593


--CREATE SCHEMA h2015;
--DROP TABLE IF EXISTS h2015.catchments;
--CREATE TABLE h2015.catchments AS (
--SELECT * FROM tempo.hydro_small_catchments_europe hsce
--WHERE EXISTS (
--  SELECT 1
--  FROM w2015.catchments c 
--  WHERE ST_Intersects(hsce.shape,c.shape)
--  )
--); --Madeira


CREATE SCHEMA h2016;
DROP TABLE IF EXISTS h2016.catchments;
CREATE TABLE h2016.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2016.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--11


CREATE SCHEMA h2017;
DROP TABLE IF EXISTS h2017.catchments;
CREATE TABLE h2017.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2017.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--537

CREATE SCHEMA h2018;
DROP TABLE IF EXISTS h2018.catchments;
CREATE TABLE h2018.catchments AS (
SELECT * FROM tempo.hydro_small_catchments_europe hsce
WHERE EXISTS (
  SELECT 1
  FROM w2018.catchments c 
  WHERE ST_Intersects(hsce.shape,c.shape)
  )
);--699


-- Integrating selected data to the DB
-- Here I use previously selected large catchments to select and integrate catchments of the lowest level

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


-- TODO add wso_id from ccm to hydroatlas
ALTER TABLE h2000.catchments ADD COLUMN wso_id int4;


CREATE TABLE tempo.intersections AS
SELECT 
    h.objectid AS h_id,
    w.wso_id AS wso_id,
    ST_Area(ST_Intersection(h.shape, w.shape)) AS intersection_area
FROM 
    h2000.catchments h
JOIN 
    w2000.catchments w
ON 
    ST_Intersects(h.shape, w.shape);--130495

DROP TABLE IF EXISTS tempo.max_intersections;
CREATE TABLE tempo.max_intersections AS
SELECT 
    h_id,
    wso_id
FROM (
    SELECT 
        h_id,
        wso_id,
        intersection_area,
        RANK() OVER (PARTITION BY h_id ORDER BY intersection_area DESC) AS rank
    FROM 
        tempo.intersections
) ranked
WHERE rank = 1;--5727


UPDATE h2000.catchments h
SET wso_id = t.wso_id
FROM tempo.max_intersections t
WHERE h.objectid = t.h_id;




ALTER TABLE w2020.catchments
RENAME shape TO geom;
ALTER TABLE w2021.catchments
RENAME shape TO geom;
ALTER TABLE w2022.catchments
RENAME shape TO geom;


CREATE INDEX hydroatlas_catchments_geom_idx ON w2020.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2021.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2022.catchments USING GIST(geom);