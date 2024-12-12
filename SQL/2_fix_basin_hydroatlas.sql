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
CREATE INDEX idx_tempo_hydro_small_catchments_europe ON tempo.hydro_small_catchments_europe USING GIST(shape);

-- Selecting european data from riveratlas
CREATE TABLE tempo.hydro_riversegments_europe AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.hydro_large_catchments_europe e
		WHERE ST_Intersects(r.geom,e.shape)
	)
); --586605 1h59

-- Creating regional subdivisions following the ccm
-- Step 1 : Selecting the most downstream riversegments
DROP TABLE IF EXISTS tempo.riveratlas_mds;
CREATE TABLE tempo.riveratlas_mds AS (
SELECT *
FROM tempo.hydro_riversegments_europe
WHERE hydro_riversegments_europe.hyriv_id = hydro_riversegments_europe.main_riv); --16599

-- Step 2 : Creating the most downstream point of previous segment
ALTER TABLE tempo.riveratlas_mds
ADD COLUMN downstream_point geometry(Point, 4326);
WITH downstream_points AS (
    SELECT 
        hyriv_id,
        ST_PointN((ST_Dump(geom)).geom, ST_NumPoints((ST_Dump(geom)).geom)) AS downstream_point
    FROM tempo.riveratlas_mds
)
UPDATE tempo.riveratlas_mds AS t
SET downstream_point = dp.downstream_point
FROM downstream_points AS dp
WHERE t.hyriv_id = dp.hyriv_id; --16599

CREATE INDEX idx_tempo_riveratlas_mds_dwnstrm ON tempo.riveratlas_mds USING GIST(downstream_point);


-- Step 3 : Intersect most downstream points with ices areas and ices ecoregions
-- ICES Areas for the Baltic
DROP TABLE IF EXISTS tempo.ices_areas_3031;
CREATE TABLE tempo.ices_areas_3031 AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_areas."ICES_Areas_20160601_cut_dense_3857" AS ia
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(ia.geom,4326),
    0.04
)
WHERE ia.subdivisio=ANY(ARRAY['31','30'])); --323 Still missing some points

DROP TABLE IF EXISTS tempo.ices_areas_3229_27;
CREATE TABLE tempo.ices_areas_3229_27 AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_areas."ICES_Areas_20160601_cut_dense_3857" AS ia
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(ia.geom,4326),
    0.04
)
WHERE ia.subdivisio=ANY(ARRAY['32','29','28','27'])); --584


DROP TABLE IF EXISTS tempo.ices_areas_26_22;
CREATE TABLE tempo.ices_areas_26_22 AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_areas."ICES_Areas_20160601_cut_dense_3857" AS ia
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(ia.geom,4326),
    0.04
)
WHERE ia.subdivisio=ANY(ARRAY['26','25','24','23','22'])); --507


-- ICES Ecoregions
DROP TABLE IF EXISTS tempo.ices_ecoregions_med_west;
CREATE TABLE tempo.ices_ecoregions_med_west AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 4);--904


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_central;
CREATE TABLE tempo.ices_ecoregions_med_central AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 5);--467


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_east;
CREATE TABLE tempo.ices_ecoregions_med_east AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 8);--1192


DROP TABLE IF EXISTS tempo.ices_ecoregions_adriatic;
CREATE TABLE tempo.ices_ecoregions_adriatic AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 7);--528


DROP TABLE IF EXISTS tempo.ices_ecoregions_biscay_iberian;
CREATE TABLE tempo.ices_ecoregions_biscay_iberian AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 2);--646


DROP TABLE IF EXISTS tempo.ices_ecoregions_iceland;
CREATE TABLE tempo.ices_ecoregions_iceland AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ICES_ecoregions_20171207_erase_ESRI" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.04
)
WHERE er.objectid = 13);--1030

-- Step 4 : Copy all riversegments with the corresponding main_riv
CREATE SCHEMA h_baltic_3031;
DROP TABLE IF EXISTS h_baltic_3031.riversegments;
CREATE TABLE h_baltic_3031.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3031 AS ia
    ON hre.main_riv = ia.main_riv
);--27480
CREATE INDEX idx_h_baltic_3031_riversegments ON h_baltic_3031.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_3229_27;
DROP TABLE IF EXISTS h_baltic_3229_27.riversegments;
CREATE TABLE h_baltic_3229_27.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3229_27 AS ia
    ON hre.main_riv = ia.main_riv
);--30933
CREATE INDEX idx_h_baltic_3229_27_riversegments ON h_baltic_3229_27.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_26_22;
DROP TABLE IF EXISTS h_baltic_26_22.riversegments;
CREATE TABLE h_baltic_26_22.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_26_22 AS ia
    ON hre.main_riv = ia.main_riv
);--25539
CREATE INDEX idx_h_baltic_26_22_riversegments ON h_baltic_26_22.riversegments USING GIST(geom);


CREATE SCHEMA h_med_west;
DROP TABLE IF EXISTS h_med_west.riversegments;
CREATE TABLE h_med_west.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--25236
CREATE INDEX idx_h_med_west_riversegments ON h_med_west.riversegments USING GIST(geom);


CREATE SCHEMA h_med_central;
DROP TABLE IF EXISTS h_med_central.riversegments;
CREATE TABLE h_med_central.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--3749
CREATE INDEX idx_h_med_central_riversegments ON h_med_central.riversegments USING GIST(geom);


CREATE SCHEMA h_med_east;
DROP TABLE IF EXISTS h_med_east.riversegments;
CREATE TABLE h_med_east.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_east AS ie
    ON hre.main_riv = ie.main_riv
);--20465
CREATE INDEX idx_h_med_east_riversegments ON h_med_east.riversegments USING GIST(geom);


CREATE SCHEMA h_adriatic;
DROP TABLE IF EXISTS h_adriatic.riversegments;
CREATE TABLE h_adriatic.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_adriatic AS ie
    ON hre.main_riv = ie.main_riv
);--16449
CREATE INDEX idx_h_adriatic_riversegments ON h_adriatic.riversegments USING GIST(geom);


CREATE SCHEMA h_biscay_iberian;
DROP TABLE IF EXISTS h_biscay_iberian.riversegments;
CREATE TABLE h_biscay_iberian.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_biscay_iberian AS ie
    ON hre.main_riv = ie.main_riv
);--39247
CREATE INDEX idx_h_biscay_iberian_riversegments ON h_biscay_iberian.riversegments USING GIST(geom);


CREATE SCHEMA h_iceland;
DROP TABLE IF EXISTS h_iceland.riversegments;
CREATE TABLE h_iceland.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_iceland AS ie
    ON hre.main_riv = ie.main_riv
);--16213
CREATE INDEX idx_h_iceland_riversegments ON h_iceland.riversegments USING GIST(geom);


-- Step 5 : Select all corresponding catchments
DROP TABLE IF EXISTS h_baltic_3031.catchments;
CREATE TABLE h_baltic_3031.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3031.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
); --31437


DROP TABLE IF EXISTS h_baltic_3229_27.catchments;
CREATE TABLE h_baltic_3229_27.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3229_27.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--35969


DROP TABLE IF EXISTS h_baltic_26_22.catchments;
CREATE TABLE h_baltic_26_22.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_26_22.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--29510

DROP TABLE IF EXISTS h_med_west.catchments;
CREATE TABLE h_med_west.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--28093


DROP TABLE IF EXISTS h_med_central.catchments;
CREATE TABLE h_med_central.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--4093


DROP TABLE IF EXISTS h_med_east.catchments;
CREATE TABLE h_med_east.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--23239


DROP TABLE IF EXISTS h_adriatic.catchments;
CREATE TABLE h_adriatic.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_adriatic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--17995


DROP TABLE IF EXISTS h_biscay_iberian.catchments;
CREATE TABLE h_biscay_iberian.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_biscay_iberian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--44324


DROP TABLE IF EXISTS h_iceland.catchments;
CREATE TABLE h_iceland.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_iceland.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--16754


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