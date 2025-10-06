
-- Modifying SRID and creating index
ALTER TABLE ices_areas.ices_areas_20160601_cut_dense_3857
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE ices_areas."ices_areas_20160601_cut_dense_3857"
	ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
	USING ST_Transform(geom, 4326);
DROP INDEX IF EXISTS ices_areas.ices_areas_wkb_geometry_geom_idx;
CREATE INDEX ices_areas_wkb_geometry_geom_idx
	ON ices_areas."ices_areas_20160601_cut_dense_3857"
	USING GIST(geom);

ALTER TABLE ices_ecoregions.ices_ecoregions_20171207_erase_esri
RENAME COLUMN wkb_geometry TO geom;
ALTER TABLE ices_ecoregions."ices_ecoregions_20171207_erase_esri"
	ALTER COLUMN geom TYPE geometry(MultiPolygon, 4326)
	USING ST_Transform(geom, 4326);
DROP INDEX IF EXISTS ices_ecoregions.ices_ecoregions_wkb_geometry_geom_idx;
CREATE INDEX ices_ecoregions_wkb_geometry_geom_idx
	ON ices_ecoregions."ices_ecoregions_20171207_erase_esri"
	USING GIST(geom);


DROP INDEX IF EXISTS tempo.ne_10m_admin_0_countries_wkb_geometry_geom_idx;
CREATE INDEX ne_10m_admin_0_countries_wkb_geometry_geom_idx
	ON tempo.ne_10m_admin_0_countries
	USING GIST(geom);

CREATE INDEX idx_riversegments_geom ON tempo.hydro_riversegments_europe USING GIST(geom);

-- Selecting southern mediterranean data from hydroatlas
DROP TABLE IF EXISTS tempo.hydro_large_catchments;
CREATE TABLE tempo.hydro_large_catchments AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id =1020034170
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = ANY(ARRAY[1030029810,1030040300,1030040310,1030031860,1030040220,1030040250,1030027430,1030034610])
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev06
WHERE hybas_id IN (2060000020,2060000030,2060000240,2060000250)
);--13


-- Selecting south med data from hydroatlas (small catchments)
DROP TABLE IF EXISTS tempo.hydro_small_catchments;
CREATE TABLE tempo.hydro_small_catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--75869
CREATE INDEX idx_tempo_hydro_small_catchments ON tempo.hydro_small_catchments USING GIST(shape);

-- Selecting european data from hydroatlas (large catchments)
DROP TABLE IF EXISTS tempo.hydro_large_catchments_europe;
CREATE TABLE tempo.hydro_large_catchments_europe AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = ANY(ARRAY[2030000010,2030003440,2030005690,2030006590,2030006600,2030007930,2030007940,2030008490,2030008500,
							2030009230,2030012730,2030014550,2030016230,2030018240,2030020320,2030024230,2030026030,2030028220,
							2030030090,2030033480,2030037990,2030041390,2030045150,2030046500,2030047500,2030048590,2030048790,
							2030054200,2030056770,2030057170,2030059370,2030059450,2030059500,2030068680,2030059510])
);--35

-- Selecting european data from hydroatlas (small catchments)
DROP TABLE IF EXISTS tempo.hydro_small_catchments_europe;
CREATE TABLE tempo.hydro_small_catchments_europe AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments_europe hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--78055
CREATE INDEX idx_tempo_hydro_small_catchments_europe ON tempo.hydro_small_catchments_europe USING GIST(shape);


-- Selecting south med data from riveratlas
DROP TABLE IF EXISTS tempo.hydro_riversegments;
CREATE TABLE tempo.hydro_riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.hydro_small_catchments e
		WHERE ST_Intersects(r.geom,e.shape)
	)
);--436570
CREATE INDEX idx_tempo_hydro_riversegments ON tempo.hydro_riversegments USING GIST(geom);


-- Selecting european data from riveratlas
DROP TABLE IF EXISTS tempo.hydro_riversegments_europe;
CREATE TABLE tempo.hydro_riversegments_europe AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.hydro_small_catchments_europe e
		WHERE ST_Intersects(r.geom,e.shape)
	)
); --589947

-- Creating regional subdivisions following the ICES Areas and Ecoregions
-- Step 1 : Selecting the most downstream riversegments
-- EUROPE
DROP TABLE IF EXISTS tempo.riveratlas_mds;
CREATE TABLE tempo.riveratlas_mds AS (
	SELECT *
	FROM tempo.hydro_riversegments_europe
	WHERE hydro_riversegments_europe.hyriv_id = hydro_riversegments_europe.main_riv); --17344


--SOUTH MED
DROP TABLE IF EXISTS tempo.riveratlas_mds_sm;
CREATE TABLE tempo.riveratlas_mds_sm AS (
	SELECT *
	FROM tempo.hydro_riversegments
	WHERE hydro_riversegments.hyriv_id = hydro_riversegments.main_riv); --8032


-- Step 2 : Creating the most downstream point of previous segment
-- EUROPE
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
	WHERE t.hyriv_id = dp.hyriv_id; --17344

CREATE INDEX idx_tempo_riveratlas_mds_dwnstrm ON tempo.riveratlas_mds USING GIST(downstream_point);


-- SOUTH MED
ALTER TABLE tempo.riveratlas_mds_sm
	ADD COLUMN downstream_point geometry(Point, 4326);
WITH downstream_points AS (
    SELECT 
        hyriv_id,
        ST_PointN((ST_Dump(geom)).geom, ST_NumPoints((ST_Dump(geom)).geom)) AS downstream_point
    FROM tempo.riveratlas_mds_sm
)
UPDATE tempo.riveratlas_mds_sm AS t
	SET downstream_point = dp.downstream_point
	FROM downstream_points AS dp
	WHERE t.hyriv_id = dp.hyriv_id; --8032

CREATE INDEX idx_tempo_riveratlas_mds__sm_dwnstrm ON tempo.riveratlas_mds_sm USING GIST(downstream_point);

-- Step 3 : Intersect most downstream points with ices areas and ices ecoregions
-- ICES Areas for the Baltic
DROP TABLE IF EXISTS tempo.ices_areas_3031;
CREATE TABLE tempo.ices_areas_3031 AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_DWithin(
	    dp.downstream_point,
	    ia.geom,
	    0.04
	)
	WHERE ia.subdivisio=ANY(ARRAY['31','30'])
); --323 Still missing some points
CREATE INDEX idx_tempo_ices_areas_3031 ON tempo.ices_areas_3031 USING GIST(downstream_point);

DROP TABLE IF EXISTS tempo.ices_areas_3229_27;
CREATE TABLE tempo.ices_areas_3229_27 AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
	ON ST_DWithin(
	    dp.downstream_point,
	    ia.geom,
	    0.01
	)
	WHERE ia.subdivisio=ANY(ARRAY['32','29','28','27'])
	AND dp.downstream_point NOT IN (
		SELECT existing.downstream_point
	    FROM tempo.ices_areas_3031 AS existing)
); --569
CREATE INDEX idx_tempo_ices_areas_3229_27 ON tempo.ices_areas_3229_27 USING GIST(downstream_point);

DROP TABLE IF EXISTS tempo.ices_areas_26_22;
CREATE TABLE tempo.ices_areas_26_22 AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
	ON ST_DWithin(
	    dp.downstream_point,
	    ia.geom,
	    0.02
	)
	WHERE ia.subdivisio=ANY(ARRAY['26','25','24','22'])
	AND dp.downstream_point NOT IN (
		SELECT existing.downstream_point
	    FROM tempo.ices_areas_3031, tempo.ices_areas_3229_27 AS existing)
); --463
CREATE INDEX idx_tempo_ices_areas_26_22 ON tempo.ices_areas_26_22 USING GIST(downstream_point);

-- ICES Ecoregions

DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_north;
CREATE TABLE tempo.ices_ecoregions_nsea_north AS (
    WITH ecoregion_points AS (
        SELECT DISTINCT dp.*
        FROM tempo.riveratlas_mds AS dp
        JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
        ON ST_DWithin(
            dp.downstream_point,
            er.geom,
            0.04
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            cs.geom,
            0.02
        )
        WHERE er.objectid = 11
          AND cs.name IN ('Norway','Sweden')
    ),
    area_points AS (
        SELECT DISTINCT dp.*
        FROM tempo.riveratlas_mds AS dp
        JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
        ON ST_DWithin(
            dp.downstream_point,
            ia.geom,
            0.04
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            cs.geom,
            0.02
        )
        WHERE ia.subdivisio = '23'
          AND cs.name IN ('Norway','Sweden')
    )
    SELECT * FROM ecoregion_points
    UNION
    SELECT * FROM area_points
    WHERE downstream_point NOT IN (
        SELECT downstream_point FROM ecoregion_points
    )
);--1271


DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_uk;
CREATE TABLE tempo.ices_ecoregions_nsea_uk AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.02
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.02
    )
    WHERE er.objectid = 11
      AND cs.name IN ('United Kingdom')
);--451


DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_south;
CREATE TABLE tempo.ices_ecoregions_nsea_south AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.02
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.02
    )
    WHERE er.objectid = 11
      AND cs.name IN ('France','Belgium','Netherlands','Germany','Denmark','Jersey','Guernsey')
);--673


DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_south;
CREATE TABLE tempo.ices_ecoregions_nsea_south AS (
    WITH ecoregion_points AS (
        SELECT DISTINCT dp.*
        FROM tempo.riveratlas_mds AS dp
        JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(er.geom, 4326),
            0.02
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(cs.geom, 4326),
            0.02
        )
        WHERE er.objectid = 11
          AND cs.name IN ('France', 'Belgium', 'Netherlands', 'Germany', 'Denmark', 'Jersey', 'Guernsey')
    ),
    area_points AS (
        SELECT DISTINCT dp.*
        FROM tempo.riveratlas_mds AS dp
        JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(ia.geom, 4326),
            0.02
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(cs.geom, 4326),
            0.02
        )
        WHERE ia.subdivisio = '23'
          AND cs.name IN ('France', 'Belgium', 'Netherlands', 'Germany', 'Denmark', 'Jersey', 'Guernsey')
    )
    SELECT * FROM ecoregion_points
    UNION
    SELECT * FROM area_points
    WHERE downstream_point NOT IN (
        SELECT downstream_point FROM ecoregion_points
    )
);--684



DROP TABLE IF EXISTS tempo.ices_ecoregions_celtic;
CREATE TABLE tempo.ices_ecoregions_celtic AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.02
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.01
    )
    WHERE er.objectid IN (9,15)
      AND cs.name IN ('United Kingdom','Ireland','Isle of Man','Faeroe Is.')
);--2065


DROP TABLE IF EXISTS tempo.ices_ecoregions_iceland;
CREATE TABLE tempo.ices_ecoregions_iceland AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.25
	)
	WHERE er.objectid = 13
);--1076


DROP TABLE IF EXISTS tempo.ices_areas_svalbard;
CREATE TABLE tempo.ices_areas_svalbard AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ref.tr_fishingarea_fia AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    er.geom,
	    0.04
	)
	WHERE er.fia_division = '27.2.b'
	OR dp.main_riv = ANY(ARRAY[20000351, 20000291, 20000316, 20000304, 20000314, 20000278, 20000238, 20000272])
); --1379
CREATE INDEX idx_tempo_ices_areas_svalbard ON tempo.ices_areas_svalbard USING GIST(downstream_point);


DROP TABLE IF EXISTS tempo.ices_ecoregions_barent;
CREATE TABLE tempo.ices_ecoregions_barent AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.02
	)
	WHERE er.objectid = 14
	AND dp.downstream_point NOT IN (
			SELECT existing.downstream_point
	    	FROM tempo.ices_areas_svalbard AS existing)
);--1948


DROP TABLE IF EXISTS tempo.ices_ecoregions_norwegian;
CREATE TABLE tempo.ices_ecoregions_norwegian AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.objectid = 16
);--1387


DROP TABLE IF EXISTS tempo.ices_ecoregions_biscay_iberian;
CREATE TABLE tempo.ices_ecoregions_biscay_iberian AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.04
	)
	WHERE er.objectid = 2
);--646


--UPDATE tempo."GSAs_simplified_division" fi SET geom = t3.geom FROM tempo."37.1.1.1" t3 WHERE fi.f_gsa = '37.1.1.1';
--UPDATE tempo."GSAs_simplified_division" fi SET geom = t3.geom FROM tempo."37.1.1.3" t3 WHERE fi.f_gsa = '37.1.1.3';
--UPDATE ref.tr_fishingarea_fia fi SET geom = t3.geom FROM tempo."27.9.a" t3 WHERE fi.fia_code = '27.9.a';


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_west;
CREATE TABLE tempo.ices_ecoregions_med_west AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.1.1.1','37.1.1.6','37.1.2.7','37.1.3.9','37.1.3.10','37.1.3.8','37.1.3.112','37.1.1.5')
);--890

--DROP TABLE IF EXISTS tempo.ices_ecoregions_med_spain;
--CREATE TABLE tempo.ices_ecoregions_med_spain AS (
--	SELECT dp.*
--	FROM tempo.riveratlas_mds AS dp
--	JOIN tempo."GSAs_simplified_division" AS er
--	ON ST_DWithin(
--	    dp.downstream_point,
--	    ST_Transform(er.geom,4326),
--	    0.01
--	)
--	WHERE er.f_gsa IN ('37.1.1.1','37.1.1.6')
--);
--
--
--
--DROP TABLE IF EXISTS tempo.ices_ecoregions_med_fr;
--CREATE TABLE tempo.ices_ecoregions_med_fr AS (
--	SELECT dp.*
--	FROM tempo.riveratlas_mds AS dp
--	JOIN tempo."GSAs_simplified_division" AS er
--	ON ST_DWithin(
--	    dp.downstream_point,
--	    ST_Transform(er.geom,4326),
--	    0.01
--	)
--	WHERE er.f_gsa IN ('37.1.2.7')
--);
--
--
--DROP TABLE IF EXISTS tempo.ices_ecoregions_med_ita;
--CREATE TABLE tempo.ices_ecoregions_med_ita AS (
--	SELECT dp.*
--	FROM tempo.riveratlas_mds AS dp
--	JOIN tempo."GSAs_simplified_division" AS er
--	ON ST_DWithin(
--	    dp.downstream_point,
--	    ST_Transform(er.geom,4326),
--	    0.01
--	)
--	WHERE er.f_gsa IN ('37.1.3.9','37.1.3.10')
--);
--
--
--DROP TABLE IF EXISTS tempo.ices_ecoregions_med_isle;
--CREATE TABLE tempo.ices_ecoregions_med_isle AS (
--	SELECT dp.*
--	FROM tempo.riveratlas_mds AS dp
--	JOIN tempo."GSAs_simplified_division" AS er
--	ON ST_DWithin(
--	    dp.downstream_point,
--	    ST_Transform(er.geom,4326),
--	    0.01
--	)
--	WHERE er.f_gsa IN ('37.1.3.8','37.1.3.112','37.1.1.5')
--);




DROP TABLE IF EXISTS tempo.ices_ecoregions_med_central;
CREATE TABLE tempo.ices_ecoregions_med_central AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.2.2.15','37.2.2.16','37.2.2.19','37.2.2.20')
	AND dp.hyriv_id NOT IN (20622643,20620772,20688798,20689371)
);--443


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_east;
CREATE TABLE tempo.ices_ecoregions_med_east AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.3.1.22','37.3.1.23','37.3.2.24','37.3.2.25','37.3.2.27','37.4.1.28')
);--1273


DROP TABLE IF EXISTS tempo.ices_ecoregions_adriatic;
CREATE TABLE tempo.ices_ecoregions_adriatic AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.2.1.17')
	AND dp.hyriv_id NOT IN (20611257,20612666,20619064,20618903,20620772,20618904,20619233,20619641,20619234,20618820,20620219)
);--386


DROP TABLE IF EXISTS tempo.ices_ecoregions_black_sea;
CREATE TABLE tempo.ices_ecoregions_black_sea AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_division IN ('37.4.2','37.4.3')
);--607


-- South Med
--DROP TABLE IF EXISTS tempo.ices_ecoregions_south_medwest;
--CREATE TABLE tempo.ices_ecoregions_south_medwest AS (
--	SELECT dp.*
--	FROM tempo.riveratlas_mds_sm AS dp
--	JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
--	ON ST_DWithin(
--	    dp.downstream_point,
--	    ST_Transform(er.geom,4326),
--	    0.01
--	)
--	WHERE er.objectid = 4
--);--268

DROP TABLE IF EXISTS tempo.ices_ecoregions_south_medwest;
CREATE TABLE tempo.ices_ecoregions_south_medwest AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds_sm AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.1.1.3','37.1.1.4')
);--225



DROP TABLE IF EXISTS tempo.ices_ecoregions_south_medcentral;
CREATE TABLE tempo.ices_ecoregions_south_medcentral AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds_sm AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
	    dp.downstream_point,
	    ST_Transform(er.geom,4326),
	    0.01
	)
	WHERE er.f_gsa IN ('37.2.2.13','37.2.2.14','37.2.2.211','37.2.2.212','37.2.2.213')
);--353


DROP TABLE IF EXISTS tempo.ices_ecoregions_south_medeast;
CREATE TABLE tempo.ices_ecoregions_south_medeast AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds_sm AS dp
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_DWithin(
    	dp.downstream_point,
    	ST_Transform(er.geom,4326),
    	0.01
	)
	WHERE er.f_gsa IN ('37.3.2.26')
);--150


DROP TABLE IF EXISTS tempo.ices_ecoregions_south_atlantic;
CREATE TABLE tempo.ices_ecoregions_south_atlantic AS (
	SELECT dp.*
	FROM tempo.riveratlas_mds_sm AS dp
	JOIN ref.tr_fishingarea_fia AS er
	ON ST_DWithin(
    	dp.downstream_point,
    	ST_Transform(er.geom,4326),
    	0.01
	)
	WHERE er.fia_division = ANY(ARRAY['34.1.1', '34.1.2', '34.1.3'])
);--672




---------------- Step 3.5 : Redo with larger buffer to catch missing bassins ----------------

WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(ia.geom, 4326),
        0.1
    )
    WHERE ia.subdivisio = ANY(ARRAY['31', '30'])
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_areas_26_22
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3229_27
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3031
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_areas_3031
SELECT mp.*
FROM missing_points AS mp;--5



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(ia.geom, 4326),
        0.1
    )
    WHERE ia.subdivisio = ANY(ARRAY['32', '29', '28'])
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_areas_26_22
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3229_27
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3031
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_areas_3229_27
SELECT mp.*
FROM missing_points AS mp;--8



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(ia.geom, 4326),
        0.1
    )
    WHERE ia.subdivisio = ANY(ARRAY['26', '25', '24','22'])
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_areas_26_22
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3229_27
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3031
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_areas_26_22
SELECT mp.*
FROM missing_points AS mp;--0


WITH filtered_points AS (
    SELECT DISTINCT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.objectid = 11
      AND cs.name IN ('Norway', 'Sweden')

    UNION
    SELECT DISTINCT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(ia.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE ia.subdivisio = '23'
      AND cs.name IN ('Norway', 'Sweden')
),
excluded_points AS (
    SELECT downstream_point FROM tempo.ices_areas_26_22
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3229_27
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_3031
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_nsea_north
SELECT mp.*
FROM missing_points AS mp;--65



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.02
    )
    WHERE er.objectid = 11
      AND cs.name IN ('United Kingdom')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_celtic
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_uk
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_nsea_uk
SELECT mp.*
FROM missing_points AS mp;--1


WITH filtered_ecoregion_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.objectid = 11
      AND cs.name IN ('France', 'Belgium', 'Netherlands', 'Germany', 'Denmark', 'Jersey', 'Guernsey')
),
filtered_area_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(ia.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE ia.subdivisio = '23'
      AND cs.name IN ('France', 'Belgium', 'Netherlands', 'Germany', 'Denmark', 'Jersey', 'Guernsey')
),
combined_filtered_points AS (
    SELECT * FROM filtered_ecoregion_points
    UNION
    SELECT * FROM filtered_area_points
    WHERE downstream_point NOT IN (
        SELECT downstream_point FROM filtered_ecoregion_points
    )
),
excluded_points AS (
    SELECT downstream_point FROM tempo.ices_ecoregions_celtic
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_uk
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_biscay_iberian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_26_22
),
missing_points AS (
    SELECT cfp.*
    FROM combined_filtered_points AS cfp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(cfp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_nsea_south
SELECT mp.*
FROM missing_points AS mp;--15



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.02
    )
    WHERE er.objectid IN (9,15)
      AND cs.name IN ('United Kingdom','Ireland','Isle of Man','Faeroe Is.')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_celtic
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_uk
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_celtic
SELECT mp.*
FROM missing_points AS mp;--42


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ref.tr_fishingarea_fia AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.fia_division IN ('27.1.b', '27.2.b')
      AND cs.name IN ('Norway')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_svalbard
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_areas_svalbard
SELECT mp.*
FROM missing_points AS mp;


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.objectid IN (14)
      AND cs.name IN ('Norway','Russia')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_areas_svalbard
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_barent
SELECT mp.*
FROM missing_points AS mp;--43


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.objectid IN (16)
      AND cs.name IN ('Norway')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_norwegian
SELECT mp.*
FROM missing_points AS mp;--58


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.objectid IN (2)
      AND cs.name IN ('Spain', 'France')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_biscay_iberian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_biscay_iberian
SELECT mp.*
FROM missing_points AS mp;--0


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_subarea IN ('37.1')
      AND cs.name IN ('Spain', 'France','Italy')
      AND dp.hyriv_id NOT IN (20658482,20658054,20657591)
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_biscay_iberian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_central
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_med_west
SELECT mp.*
FROM missing_points AS mp;--21


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_subarea IN ('37.2')
      AND er.f_division NOT IN ('37.2.1')
      AND cs.name IN ('Greece','Italy','Albania','Malta')
      AND dp.hyriv_id NOT IN (20621866,20622643,20614993,20611270,20609968,20689371)
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_central
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_adriatic
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_med_central
SELECT mp.*
FROM missing_points AS mp;--37


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_subarea IN ('37.3')
      AND cs.name IN ('Greece','N. Cyprus','Cyprus','Turkey','Syria','Lebanon','Israel','Palestine')
      AND dp.hyriv_id NOT IN (20614993)
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_central
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_black_sea
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_med_east
SELECT mp.*
FROM missing_points AS mp;--31


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_division IN ('37.2.1')
      AND cs.name IN ('Greece','Italy','Slovenia','Croatia','Albania','Montenegro','Bosnia and Herz.')
      AND dp.hyriv_id NOT IN (20615722,20612666,20611257,20620772,20620219,20622643,20621866,20619064,
      						  20618903,20619233,20619641,20619234,20618820,20620219,20618904)
), 
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_central
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_adriatic
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_adriatic
SELECT mp.*
FROM missing_points AS mp;--268


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_division IN ('37.4.2','37.4.3')
      AND cs.name IN ('Greece','Bulgaria','Romania','Turkey','Ukraine','Russia','Georgia')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_black_sea
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_east
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_black_sea
SELECT mp.*
FROM missing_points AS mp;--258



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_subarea IN ('37.1')
   	  AND er.f_division NOT IN ('37.1.3')
      AND cs.name IN ('Morocco','Algeria','Tunisia')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_south_medwest
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medcentral
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_medwest
SELECT mp.*
FROM missing_points AS mp;--5


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.1
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.1
    )
    WHERE er.f_subarea IN ('37.2')
      AND cs.name IN ('Tunisia','Lybia','Egypt','Palestine')
      OR er.f_division IN ('37.1.3')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_south_medwest
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medeast
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medcentral
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_medcentral
SELECT mp.*
FROM missing_points AS mp;--47


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
    JOIN tempo."GSAs_simplified_division" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.15
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.15
    )
    WHERE er.f_subarea IN ('37.3')
      AND cs.name IN ('Egypt')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medeast
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medcentral
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_medeast
SELECT mp.*
FROM missing_points AS mp;--11



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
    JOIN ref.tr_fishingarea_fia AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.15
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.15
    )
    WHERE er.fia_division IN ('34.1.1', '34.1.2', '34.1.3')
      AND cs.name IN ('Mauritania','W. Sahara','Morocco','Spain')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_biscay_iberian
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medwest
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_atlantic
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_atlantic
SELECT mp.*
FROM missing_points AS mp;--391


----------------- Step 4 : Copy all riversegments with the corresponding main_riv ------------
CREATE SCHEMA h_baltic30to31;
DROP TABLE IF EXISTS h_baltic30to31.riversegments;
CREATE TABLE h_baltic30to31.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3031 AS ia
    ON hre.main_riv = ia.main_riv
);--27389

ALTER TABLE h_baltic30to31.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic30to31_riversegments_main_riv ON h_baltic30to31.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic30to31_riversegments ON h_baltic30to31.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic27to29_32;
DROP TABLE IF EXISTS h_baltic27to29_32.riversegments;
CREATE TABLE h_baltic27to29_32.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3229_27 AS ia
    ON hre.main_riv = ia.main_riv
);--30869

ALTER TABLE h_baltic27to29_32.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic27to29_32_riversegments_main_riv ON h_baltic27to29_32.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic27to29_32_riversegments ON h_baltic27to29_32.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic22to26;
DROP TABLE IF EXISTS h_baltic22to26.riversegments;
CREATE TABLE h_baltic22to26.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_26_22 AS ia
    ON hre.main_riv = ia.main_riv
);--25120

ALTER TABLE h_baltic22to26.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic22to26_riversegments_main_riv ON h_baltic22to26.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic22to26_riversegments ON h_baltic22to26.riversegments USING GIST(geom);


CREATE SCHEMA h_nseanorth;
DROP TABLE IF EXISTS h_nseanorth.riversegments;
CREATE TABLE h_nseanorth.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_north AS ie
    ON hre.main_riv = ie.main_riv
);--20338

ALTER TABLE h_nseanorth.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nseanorth_riversegments_main_riv ON h_nseanorth.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nseanorth_riversegments ON h_nseanorth.riversegments USING GIST(geom);


CREATE SCHEMA h_nseauk;
DROP TABLE IF EXISTS h_nseauk.riversegments;
CREATE TABLE h_nseauk.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_uk AS ie
    ON hre.main_riv = ie.main_riv
);--9060

ALTER TABLE h_nseauk.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nseauk_riversegments_main_riv ON h_nseauk.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nseauk_riversegments ON h_nseauk.riversegments USING GIST(geom);


CREATE SCHEMA h_nseasouth;
DROP TABLE IF EXISTS h_nseasouth.riversegments;
CREATE TABLE h_nseasouth.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_south AS ie
    ON hre.main_riv = ie.main_riv
);--35954

ALTER TABLE h_nseasouth.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nseasouth_riversegments_main_riv ON h_nseasouth.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nseasouth_riversegments ON h_nseasouth.riversegments USING GIST(geom);


CREATE SCHEMA h_celtic;
DROP TABLE IF EXISTS h_celtic.riversegments;
CREATE TABLE h_celtic.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_celtic AS ie
    ON hre.main_riv = ie.main_riv
);--18919

ALTER TABLE h_celtic.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_celtic_riversegments_main_riv ON h_celtic.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_celtic_riversegments ON h_celtic.riversegments USING GIST(geom);


CREATE SCHEMA h_iceland;
DROP TABLE IF EXISTS h_iceland.riversegments;
CREATE TABLE h_iceland.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_iceland AS ie
    ON hre.main_riv = ie.main_riv
);--17581

ALTER TABLE h_iceland.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_iceland_riversegments_main_riv ON h_iceland.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_iceland_riversegments ON h_iceland.riversegments USING GIST(geom);


CREATE SCHEMA h_svalbard;
DROP TABLE IF EXISTS h_svalbard.riversegments;
CREATE TABLE h_svalbard.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_svalbard AS ie
    ON hre.main_riv = ie.main_riv
);--298

ALTER TABLE h_svalbard.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_svalbard_riversegments_main_riv ON h_svalbard.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_svalbard_riversegments ON h_svalbard.riversegments USING GIST(geom);



CREATE SCHEMA h_barents;
DROP TABLE IF EXISTS h_barents.riversegments;
CREATE TABLE h_barents.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_barent AS ie
    ON hre.main_riv = ie.main_riv
);--73691

ALTER TABLE h_barents.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_barents_riversegments_main_riv ON h_barents.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_barents_riversegments ON h_barents.riversegments USING GIST(geom);


CREATE SCHEMA h_norwegian;
DROP TABLE IF EXISTS h_norwegian.riversegments;
CREATE TABLE h_norwegian.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_norwegian AS ie
    ON hre.main_riv = ie.main_riv
);--12884

ALTER TABLE h_norwegian.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_norwegian_riversegments_main_riv ON h_norwegian.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_norwegian_riversegments ON h_norwegian.riversegments USING GIST(geom);


CREATE SCHEMA h_biscayiberian;
DROP TABLE IF EXISTS h_biscayiberian.riversegments;
CREATE TABLE h_biscayiberian.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_biscay_iberian AS ie
    ON hre.main_riv = ie.main_riv
);--39247

ALTER TABLE h_biscayiberian.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_biscayiberian_riversegments_main_riv ON h_biscayiberian.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_biscayiberian_riversegments ON h_biscayiberian.riversegments USING GIST(geom);


CREATE SCHEMA h_medwest;
DROP TABLE IF EXISTS h_medwest.riversegments;
CREATE TABLE h_medwest.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--25230

ALTER TABLE h_medwest.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_medwest_riversegments_main_riv ON h_medwest.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_medwest_riversegments ON h_medwest.riversegments USING GIST(geom);


CREATE SCHEMA h_medcentral;
DROP TABLE IF EXISTS h_medcentral.riversegments;
CREATE TABLE h_medcentral.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--3715

ALTER TABLE h_medcentral.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_medcentral_riversegments_main_riv ON h_medcentral.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_medcentral_riversegments ON h_medcentral.riversegments USING GIST(geom);


CREATE SCHEMA h_medeast;
DROP TABLE IF EXISTS h_medeast.riversegments;
CREATE TABLE h_medeast.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_east AS ie
    ON hre.main_riv = ie.main_riv
    WHERE ie.main_riv NOT IN (20609968, 20611270, 20769237, 20768814, 20768815, 20767177, 20766726, 20614993)
);--20655

ALTER TABLE h_medeast.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_medeast_riversegments_main_riv ON h_medeast.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_medeast_riversegments ON h_medeast.riversegments USING GIST(geom);


CREATE SCHEMA h_adriatic;
DROP TABLE IF EXISTS h_adriatic.riversegments;
CREATE TABLE h_adriatic.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_adriatic AS ie
    ON hre.main_riv = ie.main_riv
);--16660

ALTER TABLE h_adriatic.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_adriatic_riversegments_main_riv ON h_adriatic.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_adriatic_riversegments ON h_adriatic.riversegments USING GIST(geom);


CREATE SCHEMA h_blacksea;
DROP TABLE IF EXISTS h_blacksea.riversegments;
CREATE TABLE h_blacksea.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_black_sea AS ie
    ON hre.main_riv = ie.main_riv
);--125235

ALTER TABLE h_blacksea.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_blacksea_riversegments_main_riv ON h_blacksea.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_blacksea_riversegments ON h_blacksea.riversegments USING GIST(geom);


CREATE SCHEMA h_southmedwest;
DROP TABLE IF EXISTS h_southmedwest.riversegments;
CREATE TABLE h_southmedwest.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_medwest AS ie
    ON hre.main_riv = ie.main_riv
);--9154

ALTER TABLE h_southmedwest.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_southmedwest_riversegments_main_riv ON h_southmedwest.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_southmedwest_riversegments ON h_southmedwest.riversegments USING GIST(geom);


CREATE SCHEMA h_southmedcentral;
DROP TABLE IF EXISTS h_southmedcentral.riversegments;
CREATE TABLE h_southmedcentral.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_medcentral AS ie
    ON hre.main_riv = ie.main_riv
);--7097

ALTER TABLE h_southmedcentral.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_southmedcentral_riversegments_main_riv ON h_southmedcentral.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_southmedcentral_riversegments ON h_southmedcentral.riversegments USING GIST(geom);


CREATE SCHEMA h_southmedeast;
DROP TABLE IF EXISTS h_southmedeast.riversegments;
CREATE TABLE h_southmedeast.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_medeast AS ie
    ON hre.main_riv = ie.main_riv
);--137575

ALTER TABLE h_southmedeast.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_southmedeast_riversegments_main_riv ON h_southmedeast.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_southmedeast_riversegments ON h_southmedeast.riversegments USING GIST(geom);


CREATE SCHEMA h_southatlantic;
DROP TABLE IF EXISTS h_southatlantic.riversegments;
CREATE TABLE h_southatlantic.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_atlantic AS ie
    ON hre.main_riv = ie.main_riv
);--21183

ALTER TABLE h_southatlantic.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_southatlantic_riversegments_main_riv ON h_southatlantic.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_southatlantic_riversegments ON h_southatlantic.riversegments USING GIST(geom);



-------------- Step 5 : Select all corresponding catchments --------------
DROP TABLE IF EXISTS h_baltic30to31.catchments;
CREATE TABLE h_baltic30to31.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic30to31.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
); --3638

ALTER TABLE h_baltic30to31.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic30to31_catchments_main_bas ON h_baltic30to31.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic30to31_catchments ON h_baltic30to31.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_baltic27to29_32.catchments;
CREATE TABLE h_baltic27to29_32.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic27to29_32.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	WHERE hce.shape NOT IN (
			SELECT existing.shape
	    	FROM h_baltic30to31.catchments AS existing)
);--4934

ALTER TABLE h_baltic27to29_32.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic27to29_32_catchments_main_bas ON h_baltic27to29_32.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic27to29_32_catchments ON h_baltic27to29_32.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_baltic22to26.catchments;
CREATE TABLE h_baltic22to26.catchments AS (
    SELECT DISTINCT ON (hce.hybas_id) hce.*
    FROM tempo.hydro_small_catchments_europe AS hce
    JOIN h_baltic22to26.riversegments AS rs
    ON ST_Intersects(hce.shape, rs.geom)
    LEFT JOIN (
        SELECT shape FROM h_baltic30to31.catchments
        UNION ALL
        SELECT shape FROM h_baltic27to29_32.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3878

ALTER TABLE h_baltic22to26.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic22to26_catchments_main_bas ON h_baltic22to26.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic22to26_catchments ON h_baltic22to26.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nseanorth.catchments;
CREATE TABLE h_nseanorth.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nseanorth.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic30to31.catchments
        UNION ALL
        SELECT shape FROM h_baltic27to29_32.catchments
        UNION ALL
        SELECT shape FROM h_baltic22to26.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1603

ALTER TABLE h_nseanorth.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nseanorth_catchments_main_bas ON h_nseanorth.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nseanorth_catchments ON h_nseanorth.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nseauk.catchments;
CREATE TABLE h_nseauk.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nseauk.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--962

ALTER TABLE h_nseauk.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nseauk_catchments_main_bas ON h_nseauk.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nseauk_catchments ON h_nseauk.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nseasouth.catchments;
CREATE TABLE h_nseasouth.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nseasouth.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic22to26.catchments
        UNION ALL
        SELECT shape FROM h_nseanorth.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--4595

ALTER TABLE h_nseasouth.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nseasouth_catchments_main_bas ON h_nseasouth.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nseasouth_catchments ON h_nseasouth.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_celtic.catchments;
CREATE TABLE h_celtic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_celtic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nseauk.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1278

ALTER TABLE h_celtic.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_celtic_catchments_main_bas ON h_celtic.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_celtic_catchments ON h_celtic.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_iceland.catchments;
CREATE TABLE h_iceland.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_iceland.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--686

ALTER TABLE h_iceland.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_iceland_catchments_main_bas ON h_iceland.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_iceland_catchments ON h_iceland.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_svalbard.catchments;
CREATE TABLE h_svalbard.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_svalbard.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--343

ALTER TABLE h_svalbard.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_svalbard_catchments_main_bas ON h_svalbard.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_svalbard_catchments ON h_svalbard.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_barents.catchments;
CREATE TABLE h_barents.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_barents.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic30to31.catchments
        UNION ALL
        SELECT shape FROM h_baltic27to29_32.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--9838

ALTER TABLE h_barents.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_barents_catchments_main_bas ON h_barents.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_barents_catchments ON h_barents.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_norwegian.catchments;
CREATE TABLE h_norwegian.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_norwegian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic30to31.catchments
        UNION ALL
        SELECT shape FROM h_barents.catchments
        UNION ALL
        SELECT shape FROM h_nseanorth.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--520

ALTER TABLE h_norwegian.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_norwegian_catchments_main_bas ON h_norwegian.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_norwegian_catchments ON h_norwegian.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_biscayiberian.catchments;
CREATE TABLE h_biscayiberian.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_biscayiberian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nseasouth.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--5031

ALTER TABLE h_biscayiberian.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_biscayiberian_catchments_main_bas ON h_biscayiberian.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_biscayiberian_catchments ON h_biscayiberian.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_medwest.catchments;
CREATE TABLE h_medwest.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_medwest.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nseasouth.catchments
        UNION ALL
        SELECT shape FROM h_biscayiberian.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3094

ALTER TABLE h_medwest.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_medwest_catchments_main_bas ON h_medwest.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_medwest_catchments ON h_medwest.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_medcentral.catchments;
CREATE TABLE h_medcentral.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_medcentral.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_medwest.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--525

ALTER TABLE h_medcentral.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_medcentral_catchments_main_bas ON h_medcentral.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_medcentral_catchments ON h_medcentral.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_medeast.catchments;
CREATE TABLE h_medeast.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_medeast.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_medcentral.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3069

ALTER TABLE h_medeast.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_medeast_catchments_main_bas ON h_medeast.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_medeast_catchments ON h_medeast.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_adriatic.catchments;
CREATE TABLE h_adriatic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_adriatic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nseasouth.catchments
        UNION ALL
        SELECT shape FROM h_medwest.catchments
        UNION ALL
        SELECT shape FROM h_medcentral.catchments
        UNION ALL
        SELECT shape FROM h_medeast.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1732

ALTER TABLE h_adriatic.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_adriatic_catchments_main_bas ON h_adriatic.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_adriatic_catchments_geom ON h_adriatic.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_blacksea.catchments;
CREATE TABLE h_blacksea.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_blacksea.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nseasouth.catchments
        UNION ALL
        SELECT shape FROM h_baltic22to26.catchments
        UNION ALL
        SELECT shape FROM h_adriatic.catchments
        UNION ALL
        SELECT shape FROM h_baltic27to29_32.catchments
        UNION ALL
        SELECT shape FROM h_medeast.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--18163

ALTER TABLE h_blacksea.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_blacksea_catchments_main_bas ON h_blacksea.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_blacksea_catchments ON h_blacksea.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_southmedeast.catchments;
CREATE TABLE h_southmedeast.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_southmedeast.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_medeast.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--23042

ALTER TABLE h_southmedeast.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_southmedeast_catchments_main_bas ON h_southmedeast.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_southmedeast_catchments ON h_southmedeast.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_southmedcentral.catchments;
CREATE TABLE h_southmedcentral.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_southmedcentral.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_southmedeast.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1151

ALTER TABLE h_southmedcentral.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_southmedcentral_catchments_main_bas ON h_southmedcentral.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_southmedcentral_catchments ON h_southmedcentral.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_southmedwest.catchments;
CREATE TABLE h_southmedwest.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_southmedwest.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_southmedcentral.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1425

ALTER TABLE h_southmedwest.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_southmedwest_catchments_main_bas ON h_southmedwest.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_southmedwest_catchments ON h_southmedwest.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_southatlantic.catchments;
CREATE TABLE h_southatlantic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_southatlantic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_southmedwest.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3502

ALTER TABLE h_southatlantic.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_southatlantic_catchments_main_bas ON h_southatlantic.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_southatlantic_catchments ON h_southatlantic.catchments USING GIST(shape);


------------------------ Step 6 : Retrieving missing endoheric basins with ST_Envelope ------------------------


DROP TABLE IF EXISTS tempo.oneendo_3031;
CREATE TABLE tempo.oneendo_3031 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM h_baltic30to31.catchments AS ha);--320
CREATE INDEX idx_tempo_oneendo_3031 ON tempo.oneendo_3031 USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_3031
    ON ba.shape && oneendo_3031.geom
    AND ST_Intersects(ba.shape, oneendo_3031.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_barents.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic30to31.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic30to31.catchments
SELECT *
FROM filtered_basin;--32

INSERT INTO h_baltic30to31.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic30to31.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic30to31.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--1



DROP TABLE IF EXISTS tempo.oneendo_3229_27;
CREATE TABLE tempo.oneendo_3229_27 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_baltic27to29_32.catchments AS ha);--683 (bc islands)
CREATE INDEX idx_tempo_oneendo_3229_27 ON tempo.oneendo_3229_27 USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_3229_27
    ON ba.shape && oneendo_3229_27.geom
    AND ST_Intersects(ba.shape, oneendo_3229_27.geom)
    WHERE ba.main_bas != 2120068680
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_barents.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
),
filtered_basin AS (
    SELECT DISTINCT ON (eb.hybas_id) eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic27to29_32.catchments
SELECT *
FROM filtered_basin;--52

INSERT INTO h_baltic27to29_32.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic27to29_32.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic27to29_32.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--12


DROP TABLE IF EXISTS tempo.oneendo_26_22;
CREATE TABLE tempo.oneendo_26_22 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_baltic22to26.catchments AS ha);--94
CREATE INDEX idx_tempo_oneendo_26_22 ON tempo.oneendo_26_22 USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_26_22
    ON ba.shape && oneendo_26_22.geom
    AND ST_Intersects(ba.shape, oneendo_26_22.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic22to26.catchments
SELECT *
FROM filtered_basin;--50


INSERT INTO h_baltic22to26.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic22to26.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic22to26.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--17


DROP TABLE IF EXISTS tempo.oneendo_nsean;
CREATE TABLE tempo.oneendo_nsean AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_nseanorth.catchments AS ha);--381
CREATE INDEX idx_tempo_oneendo_nsean ON tempo.oneendo_nsean USING GIST(geom);
	

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_nsean
    ON ba.shape && oneendo_nsean.geom
    AND ST_Intersects(ba.shape, oneendo_nsean.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
),
filtered_basin AS (
    SELECT DISTINCT ON (hybas_id) eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nseanorth.catchments
SELECT *
FROM filtered_basin;--27


INSERT INTO h_nseanorth.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nseanorth.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nseanorth.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--55


DROP TABLE IF EXISTS tempo.oneendo_norwegian;
CREATE TABLE tempo.oneendo_norwegian AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_norwegian.catchments AS ha);--341
CREATE INDEX idx_tempo_oneendo_norwegian ON tempo.oneendo_norwegian USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_norwegian
    ON ba.shape && oneendo_norwegian.geom
    AND ST_Intersects(ba.shape, oneendo_norwegian.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_barents.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_norwegian.catchments
SELECT *
FROM filtered_basin;--10

INSERT INTO h_norwegian.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_norwegian.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_norwegian.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--14



-- Ok
DROP TABLE IF EXISTS tempo.oneendo_barent;
CREATE TABLE tempo.oneendo_barent AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_barents.catchments AS ha);--351
CREATE INDEX idx_tempo_oneendo_barent ON tempo.oneendo_barent USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM tempo.hydro_small_catchments_europe AS ba
    JOIN tempo.oneendo_barent
    ON ba.shape && oneendo_barent.geom
    AND ST_Intersects(ba.shape, oneendo_barent.geom)
    WHERE ba.main_bas != 2120068680
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_barents.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_barents.catchments
SELECT *
FROM filtered_basin;--188
SELECT * from h_barents.catchments;
INSERT INTO h_barents.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_barents.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_barents.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--1045



DROP TABLE IF EXISTS tempo.oneendo_nseauk;
CREATE TABLE tempo.oneendo_nseauk AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_nseauk.catchments AS ha);--32
CREATE INDEX idx_tempo_oneendo_nseauk ON tempo.oneendo_nseauk USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_nseauk
    ON ba.shape && oneendo_nseauk.geom
    AND ST_Intersects(ba.shape, oneendo_nseauk.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_celtic.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseauk.catchments
    ),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nseauk.catchments
SELECT *
FROM filtered_basin;--35

INSERT INTO h_nseauk.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nseauk.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nseauk.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--28


-- still missing a few islands
DROP TABLE IF EXISTS tempo.oneendo_celtic;
CREATE TABLE tempo.oneendo_celtic AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_celtic.catchments AS ha);--327
CREATE INDEX idx_tempo_oneendo_celtic ON tempo.oneendo_celtic USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_celtic
    ON ba.shape && oneendo_celtic.geom
    AND ST_Intersects(ba.shape, oneendo_celtic.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_celtic.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseauk.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_celtic.catchments
SELECT *
FROM filtered_basin;--57

INSERT INTO h_celtic.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_celtic.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_celtic.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--7



-- few islands missing
DROP TABLE IF EXISTS tempo.oneendo_iceland;
CREATE TABLE tempo.oneendo_iceland AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_iceland.catchments AS ha);--108
CREATE INDEX idx_tempo_oneendo_iceland ON tempo.oneendo_iceland USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_iceland
    ON ba.shape && oneendo_iceland.geom
    AND ST_Intersects(ba.shape, oneendo_iceland.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_iceland.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_iceland.catchments
SELECT *
FROM filtered_basin;--11

INSERT INTO h_iceland.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_iceland.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_iceland.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--0


DROP TABLE IF EXISTS tempo.oneendo_svalbard;
CREATE TABLE tempo.oneendo_svalbard AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_svalbard.catchments AS ha);--96
CREATE INDEX idx_tempo_oneendo_svalbard ON tempo.oneendo_svalbard USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_svalbard
    ON ba.shape && oneendo_svalbard.geom
    AND ST_Intersects(ba.shape, oneendo_svalbard.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_svalbard.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_svalbard.catchments
SELECT DISTINCT ON (hybas_id) *
FROM filtered_basin;--30

INSERT INTO h_svalbard.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_svalbard.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_svalbard.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--70

------ From here I'm going to start adding some exceptions on main_bas

-- still missing some (NL)
DROP TABLE IF EXISTS tempo.oneendo_nseas;
CREATE TABLE tempo.oneendo_nseas AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM h_nseasouth.catchments AS ha);--91
CREATE INDEX idx_tempo_oneendo_nseas ON tempo.oneendo_nseas USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_nseas
    ON ba.shape && oneendo_nseas.geom
    AND ST_Intersects(ba.shape, oneendo_nseas.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_biscayiberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape
    FROM basinatlas.basinatlas_v10_lev12
    WHERE main_bas = 2120016510
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nseasouth.catchments
SELECT *
FROM filtered_basin;--71 (1 min)


INSERT INTO h_nseasouth.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nseasouth.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nseasouth.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--5



DROP TABLE IF EXISTS tempo.oneendo_bisciber;
CREATE TABLE tempo.oneendo_bisciber AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_biscayiberian.catchments AS ha);--67
CREATE INDEX idx_tempo_oneendo_bisciber ON tempo.oneendo_bisciber USING GIST(geom);
	

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_bisciber
    ON ba.shape && oneendo_bisciber.geom
    AND ST_Intersects(ba.shape, oneendo_bisciber.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscayiberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape
    FROM basinatlas.basinatlas_v10_lev12
    WHERE main_bas = ANY(ARRAY[2120017150, 2120017480, 2120018070])
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_biscayiberian.catchments
SELECT *
FROM filtered_basin;--62


INSERT INTO h_biscayiberian.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_biscayiberian.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_biscayiberian.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--57


DROP TABLE IF EXISTS tempo.oneendo_medw;
CREATE TABLE tempo.oneendo_medw AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_medwest.catchments AS ha);--75
CREATE INDEX idx_tempo_oneendo_medw ON tempo.oneendo_medw USING GIST(geom);
	

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_medw
    ON ba.shape && oneendo_medw.geom
    AND ST_Intersects(ba.shape, oneendo_medw.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscayiberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape
    FROM basinatlas.basinatlas_v10_lev12
    WHERE main_bas = ANY(ARRAY[2120013730, 2120014560, 2120013800])
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_medwest.catchments
SELECT *
FROM filtered_basin;--151


INSERT INTO h_medwest.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_medwest.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_medwest.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--269


DROP TABLE IF EXISTS tempo.oneendo_medc;
CREATE TABLE tempo.oneendo_medc AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.4,FALSE) geom
	FROM h_medcentral.catchments AS ha);--56
CREATE INDEX idx_tempo_oneendo_medc ON tempo.oneendo_medc USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_medc
    ON ba.shape && oneendo_medc.geom
    AND ST_Intersects(ba.shape, oneendo_medc.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape 
    FROM h_medeast.catchments
    UNION ALL
    SELECT shape
    FROM basinatlas.basinatlas_v10_lev12
    WHERE main_bas = ANY(ARRAY[2120011730, 2120014300, 2120087740, 2120099800, 2120045580, 2120045160, 2120010660,
    							2120010620, 2120010580, 2120010540, 2120045200, 2120011640, 2120011620])
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_medcentral.catchments
SELECT *
FROM filtered_basin;--86


INSERT INTO h_medcentral.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_medcentral.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_medcentral.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--198


DROP TABLE IF EXISTS tempo.oneendo_mede;
CREATE TABLE tempo.oneendo_mede AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.5,FALSE) geom
	FROM h_medeast.catchments AS ha);--243
CREATE INDEX idx_tempo_oneendo_mede ON tempo.oneendo_mede USING GIST(geom);


WITH excluded_basins AS (
    SELECT geom FROM h_blacksea.riversegments
    UNION ALL
    SELECT geom FROM h_adriatic.riversegments
    UNION ALL
    SELECT geom FROM h_medcentral.riversegments
    UNION ALL
    SELECT geom FROM h_medeast.riversegments
    UNION ALL
    SELECT geom
    FROM tempo.hydro_riversegments_europe
    WHERE main_riv = ANY(ARRAY[20641990, 20641991, 20641880, 20635552, 20769237, 20768814, 20768815,
    						   20767177, 20766726])
),
riversegments_in_zone AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe rs
    JOIN tempo.oneendo_mede o
    ON rs.geom && o.geom
    WHERE rs.endorheic = 1
    AND ST_Intersects(rs.geom, o.geom)
),
filtered_segments AS (
    SELECT rsz.*
    FROM riversegments_in_zone rsz
    LEFT JOIN excluded_basins exb
    ON rsz.geom && exb.geom
    AND ST_Equals(rsz.geom, exb.geom)
    WHERE exb.geom IS NULL
),
final_segments AS (
    SELECT DISTINCT ON (rs.hyriv_id) rs.*
    FROM tempo.hydro_riversegments_europe rs
    WHERE rs.main_riv IN (
        SELECT DISTINCT fs.main_riv
        FROM filtered_segments fs
    )
)
INSERT INTO h_medeast.riversegments
SELECT DISTINCT ON (fs.hyriv_id) fs.*
FROM final_segments fs;--3903 30min



INSERT INTO h_medeast.catchments
SELECT DISTINCT ON (c.hybas_id) c.*
FROM tempo.hydro_small_catchments_europe c
JOIN h_medeast.riversegments r
ON c.shape && r.geom
AND ST_Intersects(c.shape, r.geom)
WHERE NOT EXISTS (
    SELECT *
    FROM h_medeast.catchments ex
    WHERE c.shape && ex.shape
    AND ST_Equals(c.shape, ex.shape)
);--696



DROP TABLE IF EXISTS tempo.oneendo_bsea;
CREATE TABLE tempo.oneendo_bsea AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_blacksea.catchments AS ha);--25
CREATE INDEX idx_tempo_oneendo_bsea ON tempo.oneendo_bsea USING GIST(geom);


WITH excluded_basins AS (
    SELECT geom 
    FROM h_blacksea.riversegments
    UNION ALL
    SELECT geom 
    FROM h_baltic22to26.riversegments
    UNION ALL
    SELECT geom 
    FROM h_baltic27to29_32.riversegments
    UNION ALL
    SELECT geom 
    FROM h_medeast.riversegments
    UNION ALL
    SELECT geom 
    FROM h_nseasouth.riversegments
    UNION ALL
    SELECT geom 
    FROM h_adriatic.riversegments
    UNION ALL
    SELECT geom
    FROM tempo.hydro_riversegments_europe
    WHERE main_riv = ANY(ARRAY[20490321, 20539064, 20518667])
),
riversegments_in_zone AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe rs
    JOIN tempo.oneendo_bsea o
    ON rs.geom && o.geom
    WHERE rs.endorheic = 1
    AND ST_Intersects(rs.geom, o.geom)
),
filtered_segments AS (
    SELECT rsz.*
    FROM riversegments_in_zone rsz
    LEFT JOIN excluded_basins exb
    ON rsz.geom && exb.geom
    AND ST_Equals(rsz.geom, exb.geom)
    WHERE exb.geom IS NULL
),
final_segments AS (
    SELECT DISTINCT ON (rs.hyriv_id) rs.*
    FROM tempo.hydro_riversegments_europe rs
    WHERE rs.main_riv IN (
        SELECT DISTINCT fs.main_riv
        FROM filtered_segments fs
    )
)
INSERT INTO h_blacksea.riversegments
SELECT DISTINCT ON (fs.hyriv_id) fs.*
FROM final_segments fs;--2018


INSERT INTO h_blacksea.catchments
SELECT DISTINCT ON (c.hybas_id) c.*
FROM tempo.hydro_small_catchments_europe c
JOIN h_blacksea.riversegments r
ON c.shape && r.geom
AND ST_Intersects(c.shape, r.geom)
WHERE NOT EXISTS (
    SELECT *
    FROM h_blacksea.catchments ex
    WHERE c.shape && ex.shape
    AND ST_Equals(c.shape, ex.shape)
);--400


DROP TABLE IF EXISTS tempo.oneendo_adriatic;
CREATE TABLE tempo.oneendo_adriatic AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.2,FALSE) geom
	FROM h_adriatic.catchments AS ha);--150
CREATE INDEX idx_tempo_oneendo_adriatic ON tempo.oneendo_adriatic USING GIST(geom);


WITH excluded_basins AS (
    SELECT geom 
    FROM h_medwest.riversegments
    UNION ALL
    SELECT geom 
    FROM h_nseasouth.riversegments
    UNION ALL
    SELECT geom 
    FROM h_adriatic.riversegments
    UNION ALL
    SELECT geom 
    FROM h_medcentral.riversegments
    UNION ALL
    SELECT geom 
    FROM h_medeast.riversegments
    UNION ALL
    SELECT geom 
    FROM h_blacksea.riversegments
),
riversegments_in_zone AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe rs
    JOIN tempo.oneendo_adriatic o
    ON rs.geom && o.geom
    WHERE rs.endorheic = 1
    AND ST_Intersects(rs.geom, o.geom)
),
filtered_segments AS (
    SELECT rsz.*
    FROM riversegments_in_zone rsz
    LEFT JOIN excluded_basins exb
    ON rsz.geom && exb.geom
    AND ST_Equals(rsz.geom, exb.geom)
    WHERE exb.geom IS NULL
),
final_segments AS (
    SELECT DISTINCT ON (rs.hyriv_id) rs.*
    FROM tempo.hydro_riversegments_europe rs
    WHERE rs.main_riv IN (
        SELECT DISTINCT fs.main_riv
        FROM filtered_segments fs
    )
)
INSERT INTO h_adriatic.riversegments
SELECT DISTINCT ON (fs.hyriv_id) fs.*
FROM final_segments fs; --1536

INSERT INTO h_adriatic.catchments
SELECT DISTINCT ON (c.hybas_id) c.*
FROM tempo.hydro_small_catchments_europe c
JOIN h_adriatic.riversegments r
ON c.shape && r.geom
AND ST_Intersects(c.shape, r.geom)
WHERE NOT EXISTS (
    SELECT *
    FROM h_adriatic.catchments ex
    WHERE c.shape && ex.shape
    AND ST_Equals(c.shape, ex.shape)
);--327




------------------------ Step 7 : Retrieving last islands and basins along the coast ------------------------

WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_Intersects(c.shape, ia.geom)
	WHERE ia.subdivisio=ANY(ARRAY['31','30'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape
    FROM tempo.hydro_small_catchments_europe
    WHERE hybas_id = 2120029210
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic30to31.catchments
SELECT *
FROM filtered_basin;--2



WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_Intersects(c.shape, ia.geom)
	WHERE ia.subdivisio=ANY(ARRAY['32','29','28','27'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic27to29_32.catchments
SELECT *
FROM filtered_basin;--9


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_Intersects(c.shape, ia.geom)
	WHERE ia.subdivisio=ANY(ARRAY['26', '25', '24','22'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic22to26.catchments
SELECT *
FROM filtered_basin;--0


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 13
),
excluded_basins AS (
    SELECT shape 
    FROM h_iceland.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_iceland.catchments
SELECT *
FROM filtered_basin;--2

-- Norwegian Ok, Barent Ok, UK Ok.
WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 11
),
excluded_basins AS (
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape
    FROM h_nseauk.catchments
    UNION ALL
    SELECT shape
    FROM h_nseanorth.catchments
    UNION ALL
    SELECT shape
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape
    FROM h_biscayiberian.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nseasouth.catchments
SELECT *
FROM filtered_basin;--20


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 9
),
excluded_basins AS (
    SELECT shape 
    FROM h_celtic.catchments
    UNION ALL
    SELECT shape
    FROM h_nseauk.catchments
    UNION ALL
    SELECT shape
    FROM tempo.hydro_small_catchments_europe
    WHERE hybas_id = 2120021410
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_celtic.catchments
SELECT *
FROM filtered_basin;--10


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 2
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscayiberian.catchments
    UNION ALL
    SELECT shape
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_biscayiberian.catchments
SELECT *
FROM filtered_basin;--1


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.f_subarea IN ('37.1')
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscayiberian.catchments
    UNION ALL
    SELECT shape
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_medwest.catchments
SELECT *
FROM filtered_basin;--14


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.f_subarea IN ('37.2')
	AND er.f_division NOT IN ('37.2.1')
),
excluded_basins AS (
    SELECT shape 
    FROM h_medeast.catchments
    UNION ALL
    SELECT shape
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape
    FROM tempo.hydro_small_catchments_europe
    WHERE hybas_id = ANY(ARRAY[2120045160, 2120045580])
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_medcentral.catchments
SELECT *
FROM filtered_basin;--3


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.f_subarea IN ('37.3')
	AND er.f_division NOT IN ('37.3.2','37.4.1')
),
excluded_basins AS (
    SELECT shape 
    FROM h_medeast.catchments
    UNION ALL
    SELECT shape
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape
    FROM h_blacksea.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_medeast.catchments
SELECT *
FROM filtered_basin;--67


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.f_division IN ('37.4.2','37.4.3')
),
excluded_basins AS (
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM h_medeast.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_blacksea.catchments
SELECT *
FROM filtered_basin;--82


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN tempo."GSAs_simplified_division" AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.f_division IN ('37.2.1')
),
excluded_basins AS (
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_nseasouth.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_medcentral.catchments
    UNION ALL
    SELECT shape 
    FROM h_medeast.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_adriatic.catchments
SELECT *
FROM filtered_basin;--63


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ref.tr_fishingarea_fia AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.fia_division = ANY(ARRAY['27.2.b','27.1.b'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_svalbard.catchments
    UNION ALL
    SELECT shape
    FROM h_barents.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_svalbard.catchments
SELECT *
FROM filtered_basin;--25


--1:42:52 to run everything

DROP TABLE IF EXISTS tempo.riversegments_baltic;
CREATE TABLE tempo.riversegments_baltic (LIKE h_baltic30to31.riversegments);
ALTER TABLE h_baltic30to31.riversegments INHERIT tempo.riversegments_baltic;
ALTER TABLE h_baltic22to26.riversegments INHERIT tempo.riversegments_baltic;
ALTER TABLE h_baltic27to29_32.riversegments INHERIT tempo.riversegments_baltic;
CREATE INDEX idx_tempo_balt_catchments ON tempo.catchments_baltic USING GIST(geom);


DROP TABLE IF EXISTS tempo.catchments_baltic;
CREATE TABLE tempo.catchments_baltic (LIKE h_baltic30to31.catchments);
ALTER TABLE h_baltic30to31.catchments INHERIT tempo.catchments_baltic;
ALTER TABLE h_baltic22to26.catchments INHERIT tempo.catchments_baltic;
ALTER TABLE h_baltic27to29_32.catchments INHERIT tempo.catchments_baltic;


DROP TABLE IF EXISTS tempo.riversegments_nas;
CREATE TABLE tempo.riversegments_nas (LIKE h_barents.riversegments);
ALTER TABLE h_barents.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_biscayiberian.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_celtic.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_iceland.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_norwegian.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_nseanorth.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_nseasouth.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_nseauk.riversegments INHERIT tempo.riversegments_nas;
ALTER TABLE h_svalbard.riversegments INHERIT tempo.riversegments_nas;

DROP TABLE IF EXISTS tempo.catchments_nas;
CREATE TABLE tempo.catchments_nas (LIKE h_barents.catchments);
ALTER TABLE h_barents.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_biscayiberian.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_celtic.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_iceland.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_norwegian.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_nseanorth.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_nseasouth.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_nseauk.catchments INHERIT tempo.catchments_nas;
ALTER TABLE h_svalbard.catchments INHERIT tempo.catchments_nas;

DROP TABLE IF EXISTS tempo.catchments_nac;
CREATE TABLE tempo.catchments_nac AS(
WITH selectlarge AS (
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id = ANY(ARRAY[7020024600,7020038340])),
selectsmall AS (
SELECT *
FROM basinatlas.basinatlas_v10_lev12 bs
WHERE EXISTS (
  SELECT 1
  FROM selectlarge bl
  WHERE ST_Within(bs.shape,bl.shape)
  )
)
SELECT * FROM selectsmall
);--30504
CREATE INDEX idx_tempo_nac_catchments ON tempo.catchments_nac USING GIST(shape);

DROP TABLE IF EXISTS tempo.riversegments_nac;
CREATE TABLE tempo.riversegments_nac AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.catchments_nac e
		WHERE ST_Intersects(r.geom,e.shape)
	)
);--434740
CREATE INDEX idx_tempo_nac_riversegments ON tempo.riversegments_nac USING GIST(geom);


DROP TABLE IF EXISTS tempo.riversegments_eel;
CREATE TABLE tempo.riversegments_eel (LIKE h_baltic30to31.riversegments);
ALTER TABLE h_adriatic.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_baltic30to31.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_baltic22to26.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_baltic27to29_32.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_barents.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_biscayiberian.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_blacksea.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_celtic.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_iceland.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_medcentral.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_medeast.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_medwest.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_norwegian.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_nseanorth.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_nseasouth.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_nseauk.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_southatlantic.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_southmedcentral.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_southmedeast.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_southmedwest.riversegments INHERIT tempo.riversegments_eel;
ALTER TABLE h_svalbard.riversegments INHERIT tempo.riversegments_eel;
CREATE INDEX idx_tempo_eel_riv ON tempo.riversegments_eel USING GIST(geom);


DROP TABLE IF EXISTS tempo.catchments_eel;
CREATE TABLE tempo.catchments_eel (LIKE h_baltic30to31.catchments);
ALTER TABLE h_adriatic.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_baltic30to31.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_baltic22to26.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_baltic27to29_32.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_barents.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_biscayiberian.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_blacksea.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_celtic.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_iceland.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_medcentral.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_medeast.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_medwest.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_norwegian.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_nseanorth.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_nseasouth.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_nseauk.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_southatlantic.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_southmedcentral.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_southmedeast.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_southmedwest.catchments INHERIT tempo.catchments_eel;
ALTER TABLE h_svalbard.catchments INHERIT tempo.catchments_eel;
CREATE INDEX idx_tempo_eel_catchments ON tempo.catchments_eel USING GIST(shape);



