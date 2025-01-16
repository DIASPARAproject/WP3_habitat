
-- Modifying SRID

DROP INDEX IF EXISTS ices_areas.ices_areas_geom_idx;
CREATE INDEX ices_areas_geom_idx
	ON ices_areas."ices_areas_20160601_cut_dense_3857"
	USING GIST(geom);



DROP INDEX IF EXISTS ices_ecoregions.ices_ecoregions_wkb_geometry_geom_idx;
CREATE INDEX ices_ecoregions_wkb_geometry_geom_idx
	ON ices_ecoregions."ices_ecoregions_20171207_erase_esri"
	USING GIST(geom);


DROP INDEX IF EXISTS tempo.ne_10m_admin_0_countries_wkb_geometry_geom_idx;
CREATE INDEX ne_10m_admin_0_countries_wkb_geometry_geom_idx
	ON tempo.ne_10m_admin_0_countries
	USING GIST(geom);

-- Selecting southern mediterranean data from hydroatlas
DROP TABLE IF EXISTS tempo.hydro_large_catchments;
CREATE TABLE tempo.hydro_large_catchments AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id =1020034170
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev03
WHERE hybas_id = ANY(ARRAY[1030029810,1030040300,1030040310,1030031860,1030040220,1030040250,1030027430])
);--8


-- Selecting south med data from hydroatlas (small catchments)
DROP TABLE IF EXISTS tempo.hydro_small_catchments;
CREATE TABLE tempo.hydro_small_catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--75523
CREATE INDEX idx_tempo_hydro_small_catchments ON tempo.hydro_small_catchments USING GIST(shape);

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


-- Selecting south med data from riveratlas
DROP TABLE IF EXISTS tempo.hydro_riversegments;
CREATE TABLE tempo.hydro_riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.hydro_small_catchments e
		WHERE ST_Intersects(r.geom,e.shape)
	)
);--434512
CREATE INDEX idx_tempo_hydro_riversegments ON tempo.hydro_riversegments USING GIST(geom);


-- Selecting european data from riveratlas
CREATE TABLE tempo.hydro_riversegments_europe AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM tempo.hydro_small_catchments_europe e
		WHERE ST_Intersects(r.geom,e.shape)
	)
); --586605 1h59 (shorter when index is used !!)

-- Creating regional subdivisions following the ICES Areas and Ecoregions
-- Step 1 : Selecting the most downstream riversegments
-- EUROPE
DROP TABLE IF EXISTS tempo.riveratlas_mds;
CREATE TABLE tempo.riveratlas_mds AS (
	SELECT *
	FROM tempo.hydro_riversegments_europe
	WHERE hydro_riversegments_europe.hyriv_id = hydro_riversegments_europe.main_riv); --16599


--SOUTH MED
DROP TABLE IF EXISTS tempo.riveratlas_mds_sm;
CREATE TABLE tempo.riveratlas_mds_sm AS (
	SELECT *
	FROM tempo.hydro_riversegments
	WHERE hydro_riversegments.hyriv_id = hydro_riversegments.main_riv); --7829


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
	WHERE t.hyriv_id = dp.hyriv_id; --16599

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
	WHERE t.hyriv_id = dp.hyriv_id; --7829

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
WHERE er.objectid = 13);--1076


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
WHERE er.objectid = 14);--1948


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
WHERE er.objectid = 16);--1387


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
WHERE er.objectid = 2);--646


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_west;
CREATE TABLE tempo.ices_ecoregions_med_west AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 4);--904


DROP TABLE IF EXISTS tempo.ices_ecoregions_med_central;
CREATE TABLE tempo.ices_ecoregions_med_central AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
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
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 8);--1187


DROP TABLE IF EXISTS tempo.ices_ecoregions_adriatic;
CREATE TABLE tempo.ices_ecoregions_adriatic AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 7);--507


DROP TABLE IF EXISTS tempo.ices_ecoregions_black_sea;
CREATE TABLE tempo.ices_ecoregions_black_sea AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 6);--982


-- South Med
DROP TABLE IF EXISTS tempo.ices_ecoregions_south_med_west;
CREATE TABLE tempo.ices_ecoregions_south_med_west AS (
SELECT dp.*
FROM tempo.riveratlas_mds_sm AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 4);--268


DROP TABLE IF EXISTS tempo.ices_ecoregions_south_med_east;
CREATE TABLE tempo.ices_ecoregions_south_med_east AS (
SELECT dp.*
FROM tempo.riveratlas_mds_sm AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 8);--173


DROP TABLE IF EXISTS tempo.ices_ecoregions_south_med_central;
CREATE TABLE tempo.ices_ecoregions_south_med_central AS (
SELECT dp.*
FROM tempo.riveratlas_mds_sm AS dp
JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(er.geom,4326),
    0.01
)
WHERE er.objectid = 5);--329



-- TODO Step 3.5 : Redo with larger buffer to catch missing bassins

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
    WHERE er.objectid IN (4)
      AND cs.name IN ('Spain', 'France','Italy')
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
FROM missing_points AS mp;--5


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
    WHERE er.objectid IN (5)
      AND cs.name IN ('Greece','Italy','Albania','Malta')
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
FROM missing_points AS mp;--12


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
    WHERE er.objectid IN (8)
      AND cs.name IN ('Greece','N. Cyprus','Cyprus','Turkey','Syria','Lebanon','Israel','Palestine')
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
        0.1
    )
    WHERE er.objectid IN (7)
      AND cs.name IN ('Greece','Italy','Slovenia','Croatia','Albania','Montenegro','Bosnia and Herz.')
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
FROM missing_points AS mp;--173


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
    WHERE er.objectid IN (6)
      AND cs.name IN ('Greece','Bulgaria','Romania','Turkey','Ukraine','Russia','Georgia','Palestine')
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
FROM missing_points AS mp;--2



WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
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
    WHERE er.objectid IN (4)
      AND cs.name IN ('Morocco','Algeria','Tunisia')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_south_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_central
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_med_west
SELECT mp.*
FROM missing_points AS mp;--2


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
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
    WHERE er.objectid IN (5)
      AND cs.name IN ('Tunisia','Lybia')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_south_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_central
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_med_central
SELECT mp.*
FROM missing_points AS mp;--3


WITH filtered_points AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds_sm AS dp
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
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
    WHERE er.objectid IN (8)
      AND cs.name IN ('Egypt')
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_east
    UNION ALL
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_central
),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.ices_ecoregions_south_med_east
SELECT mp.*
FROM missing_points AS mp;--11


-- Step 4 : Copy all riversegments with the corresponding main_riv
CREATE SCHEMA h_baltic_3031;
DROP TABLE IF EXISTS h_baltic_3031.riversegments;
CREATE TABLE h_baltic_3031.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3031 AS ia
    ON hre.main_riv = ia.main_riv
);--27529
CREATE INDEX idx_h_baltic_3031_riversegments ON h_baltic_3031.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_3229_27;
DROP TABLE IF EXISTS h_baltic_3229_27.riversegments;
CREATE TABLE h_baltic_3229_27.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3229_27 AS ia
    ON hre.main_riv = ia.main_riv
);--30870
CREATE INDEX idx_h_baltic_3229_27_riversegments ON h_baltic_3229_27.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_26_22;
DROP TABLE IF EXISTS h_baltic_26_22.riversegments;
CREATE TABLE h_baltic_26_22.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_26_22 AS ia
    ON hre.main_riv = ia.main_riv
);--25123
CREATE INDEX idx_h_baltic_26_22_riversegments ON h_baltic_26_22.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_north;
DROP TABLE IF EXISTS h_nsea_north.riversegments;
CREATE TABLE h_nsea_north.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_north AS ie
    ON hre.main_riv = ie.main_riv
);--20338
CREATE INDEX idx_h_nsea_north_riversegments ON h_nsea_north.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_uk;
DROP TABLE IF EXISTS h_nsea_uk.riversegments;
CREATE TABLE h_nsea_uk.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_uk AS ie
    ON hre.main_riv = ie.main_riv
);--9060
CREATE INDEX idx_h_nsea_uk_riversegments ON h_nsea_uk.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_south;
DROP TABLE IF EXISTS h_nsea_south.riversegments;
CREATE TABLE h_nsea_south.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_south AS ie
    ON hre.main_riv = ie.main_riv
);--35954
CREATE INDEX idx_h_nsea_south_riversegments ON h_nsea_south.riversegments USING GIST(geom);


CREATE SCHEMA h_celtic;
DROP TABLE IF EXISTS h_celtic.riversegments;
CREATE TABLE h_celtic.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_celtic AS ie
    ON hre.main_riv = ie.main_riv
);--18962
CREATE INDEX idx_h_celtic_riversegments ON h_celtic.riversegments USING GIST(geom);


CREATE SCHEMA h_iceland;
DROP TABLE IF EXISTS h_iceland.riversegments;
CREATE TABLE h_iceland.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_iceland AS ie
    ON hre.main_riv = ie.main_riv
);--17581
CREATE INDEX idx_h_iceland_riversegments ON h_iceland.riversegments USING GIST(geom);


CREATE SCHEMA h_barent;
DROP TABLE IF EXISTS h_barent.riversegments;
CREATE TABLE h_barent.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_barent AS ie
    ON hre.main_riv = ie.main_riv
);--73679
CREATE INDEX idx_h_barent_riversegments ON h_barent.riversegments USING GIST(geom);


CREATE SCHEMA h_norwegian;
DROP TABLE IF EXISTS h_norwegian.riversegments;
CREATE TABLE h_norwegian.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_norwegian AS ie
    ON hre.main_riv = ie.main_riv
);--12884
CREATE INDEX idx_h_norwegian_riversegments ON h_norwegian.riversegments USING GIST(geom);


CREATE SCHEMA h_biscay_iberian;
DROP TABLE IF EXISTS h_biscay_iberian.riversegments;
CREATE TABLE h_biscay_iberian.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_biscay_iberian AS ie
    ON hre.main_riv = ie.main_riv
);--39247
CREATE INDEX idx_h_biscay_iberian_riversegments ON h_biscay_iberian.riversegments USING GIST(geom);


CREATE SCHEMA h_med_west;
DROP TABLE IF EXISTS h_med_west.riversegments;
CREATE TABLE h_med_west.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--25256
CREATE INDEX idx_h_med_west_riversegments ON h_med_west.riversegments USING GIST(geom);


CREATE SCHEMA h_med_central;
DROP TABLE IF EXISTS h_med_central.riversegments;
CREATE TABLE h_med_central.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--3779
CREATE INDEX idx_h_med_central_riversegments ON h_med_central.riversegments USING GIST(geom);


CREATE SCHEMA h_med_east;
DROP TABLE IF EXISTS h_med_east.riversegments;
CREATE TABLE h_med_east.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_east AS ie
    ON hre.main_riv = ie.main_riv
);--20479
CREATE INDEX idx_h_med_east_riversegments ON h_med_east.riversegments USING GIST(geom);


CREATE SCHEMA h_adriatic;
DROP TABLE IF EXISTS h_adriatic.riversegments;
CREATE TABLE h_adriatic.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_adriatic AS ie
    ON hre.main_riv = ie.main_riv
);--16757
CREATE INDEX idx_h_adriatic_riversegments ON h_adriatic.riversegments USING GIST(geom);


CREATE SCHEMA h_black_sea;
DROP TABLE IF EXISTS h_black_sea.riversegments;
CREATE TABLE h_black_sea.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_black_sea AS ie
    ON hre.main_riv = ie.main_riv
);--127453
CREATE INDEX idx_h_black_sea_riversegments ON h_black_sea.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_west;
DROP TABLE IF EXISTS h_south_med_west.riversegments;
CREATE TABLE h_south_med_west.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--10716
CREATE INDEX idx_h_south_med_west_riversegments ON h_south_med_west.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_central;
DROP TABLE IF EXISTS h_south_med_central.riversegments;
CREATE TABLE h_south_med_central.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--5403
CREATE INDEX idx_h_south_med_central_riversegments ON h_south_med_central.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_east;
DROP TABLE IF EXISTS h_south_med_east.riversegments;
CREATE TABLE h_south_med_east.riversegments AS (
    SELECT hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_east AS ie
    ON hre.main_riv = ie.main_riv
);--136034
CREATE INDEX idx_h_south_med_east_riversegments ON h_south_med_east.riversegments USING GIST(geom);



-- Step 5 : Select all corresponding catchments
DROP TABLE IF EXISTS h_baltic_3031.catchments;
CREATE TABLE h_baltic_3031.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3031.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
); --31490
CREATE INDEX idx_h_baltic_3031_catchments ON h_baltic_3031.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_baltic_3229_27.catchments;
CREATE TABLE h_baltic_3229_27.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3229_27.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	WHERE hce.shape NOT IN (
			SELECT existing.shape
	    	FROM h_baltic_3031.catchments AS existing)
);--35900
CREATE INDEX idx_h_baltic_3229_27_catchments ON h_baltic_3229_27.catchments USING GIST(shape);

--DROP TABLE IF EXISTS h_baltic_26_22.catchments;
--CREATE TABLE h_baltic_26_22.catchments AS (
--	SELECT hce.*
--	FROM tempo.hydro_small_catchments_europe AS hce
--	JOIN h_baltic_26_22.riversegments AS rs
--	ON ST_Intersects(hce.shape,rs.geom)
--	WHERE hce.shape NOT IN (
--			SELECT existing.shape
--	    	FROM h_baltic_3031.catchments, h_baltic_3229_27.catchments AS existing)
--);--29055

DROP TABLE IF EXISTS h_baltic_26_22.catchments;
CREATE TABLE h_baltic_26_22.catchments AS (
    SELECT hce.*
    FROM tempo.hydro_small_catchments_europe AS hce
    JOIN h_baltic_26_22.riversegments AS rs
    ON ST_Intersects(hce.shape, rs.geom)
    LEFT JOIN (
        SELECT shape FROM h_baltic_3031.catchments
        UNION ALL
        SELECT shape FROM h_baltic_3229_27.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--29043
CREATE INDEX idx_h_baltic_26_22_catchments ON h_baltic_26_22.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nsea_north.catchments;
CREATE TABLE h_nsea_north.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_north.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic_3031.catchments
        UNION ALL
        SELECT shape FROM h_baltic_3229_27.catchments
        UNION ALL
        SELECT shape FROM h_baltic_26_22.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--21810
CREATE INDEX idx_h_nsea_north_catchments ON h_nsea_north.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_nsea_uk.catchments;
CREATE TABLE h_nsea_uk.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_uk.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--9863
CREATE INDEX idx_h_nsea_uk_catchments ON h_nsea_uk.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_nsea_south.catchments;
CREATE TABLE h_nsea_south.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_south.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic_26_22.catchments
        UNION ALL
        SELECT shape FROM h_nsea_north.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--40477
CREATE INDEX idx_h_nsea_south_catchments ON h_nsea_south.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_celtic.catchments;
CREATE TABLE h_celtic.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_celtic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_uk.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--19854
CREATE INDEX idx_h_celtic_catchments ON h_celtic.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_iceland.catchments;
CREATE TABLE h_iceland.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_iceland.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--18142
CREATE INDEX idx_h_iceland_catchments ON h_iceland.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_barent.catchments;
CREATE TABLE h_barent.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_barent.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic_3031.catchments
        UNION ALL
        SELECT shape FROM h_baltic_3229_27.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--84202
CREATE INDEX idx_h_barent_catchments ON h_barent.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_norwegian.catchments;
CREATE TABLE h_norwegian.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_norwegian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_baltic_3031.catchments
        UNION ALL
        SELECT shape FROM h_barent.catchments
        UNION ALL
        SELECT shape FROM h_nsea_north.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--13013
CREATE INDEX idx_h_norwegian_catchments ON h_norwegian.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_biscay_iberian.catchments;
CREATE TABLE h_biscay_iberian.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_biscay_iberian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_south.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--44303
CREATE INDEX idx_h_biscay_iberian_catchments ON h_biscay_iberian.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_med_west.catchments;
CREATE TABLE h_med_west.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_south.catchments
        UNION ALL
        SELECT shape FROM h_biscay_iberian.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--28112
CREATE INDEX idx_h_med_west_catchments ON h_med_west.catchments USING GIST(shape);

DROP TABLE IF EXISTS h_med_central.catchments;
CREATE TABLE h_med_central.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_west.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--4118
CREATE INDEX idx_h_med_central_catchments ON h_med_central.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_med_east.catchments;
CREATE TABLE h_med_east.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_central.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--23215
CREATE INDEX idx_h_med_east_catchments ON h_med_east.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_adriatic.catchments;
CREATE TABLE h_adriatic.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_adriatic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_south.catchments
        UNION ALL
        SELECT shape FROM h_med_west.catchments
        UNION ALL
        SELECT shape FROM h_med_central.catchments
        UNION ALL
        SELECT shape FROM h_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--18283
CREATE INDEX idx_h_adriatic_catchments_geom ON h_adriatic.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_black_sea.catchments;
CREATE TABLE h_black_sea.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_black_sea.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_south.catchments
        UNION ALL
        SELECT shape FROM h_baltic_26_22.catchments
        UNION ALL
        SELECT shape FROM h_adriatic.catchments
        UNION ALL
        SELECT shape FROM h_baltic_3229_27.catchments
        UNION ALL
        SELECT shape FROM h_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--146544
CREATE INDEX idx_h_black_sea_catchments ON h_black_sea.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_east.catchments;
CREATE TABLE h_south_med_east.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--160160
CREATE INDEX idx_h_south_med_east_catchments ON h_south_med_east.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_central.catchments;
CREATE TABLE h_south_med_central.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_south_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--6185
CREATE INDEX idx_h_south_med_central_catchments ON h_south_med_central.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_west.catchments;
CREATE TABLE h_south_med_west.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_south_med_central.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--12345
CREATE INDEX idx_h_south_med_west_catchments ON h_south_med_west.catchments USING GIST(shape);



------------------ TESTING STUFF HERE DON'T MIND ME ------------------

-- TODO Try to retrieve missing endoheric basins with ST_Envelope
-- Sélection des bassins endoréiques touchant l'enveloppe géographique de h_adriatic.shape
/*DROP TABLE IF EXISTS tempo.endo_adri;
CREATE TABLE tempo.endo_adri AS (
	SELECT DISTINCT ba.*
	FROM basinatlas.basinatlas_v10_lev12 AS ba
	JOIN h_adriatic.catchments AS ha
	ON ST_Intersects(ba.shape, ST_ConvexHull(ha.shape))
	WHERE ba.endo = 2);--433 --393

INSERT INTO tempo.endo_adri
SELECT DISTINCT ba.*
FROM basinatlas.basinatlas_v10_lev12 AS ba
LEFT JOIN tempo.endo_adri AS ea
ON ST_Equals(ba.shape, ea.shape) -- Comparaison des géométries pour éviter les doublons
WHERE ba.main_bas IN (
    SELECT DISTINCT main_bas
    FROM tempo.endo_adri
)
AND ba.endo = 1;--34*/



DROP TABLE IF EXISTS tempo.convextest;
CREATE TABLE tempo.convextest AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.01,FALSE) geom
	FROM h_biscay_iberian.catchments AS ha);


DROP TABLE IF EXISTS tempo.convextest2;
CREATE TABLE tempo.convextest2 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.01,FALSE) geom
	FROM h_med_west.catchments AS ha);

DROP TABLE IF EXISTS tempo.convextest3;
CREATE TABLE tempo.convextest3 AS (
	SELECT  ST_ConcaveHull((ST_Dump(ST_Union(convextest.geom,convextest2.geom))).geom,0.01,FALSE) geom
	FROM tempo.convextest, tempo.convextest2);


--WIP Use convextest3 to select all missing endoheric basins
-- Use convextest to grab missing endo basins 
-- Compare with basins already in table 1 et in table 2
-- Take missing ones with exception for those already in the neighbouring table + non endo (=0) 

DROP TABLE IF EXISTS tempo.oneendo_3031;
CREATE TABLE tempo.oneendo_3031 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM h_baltic_3031.catchments AS ha);--320
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
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_barent.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3031.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_3031.catchments
SELECT *
FROM filtered_basin;--32


-- NOT GOOOOOOD, I don't want to take anything from the eastern part 
DROP TABLE IF EXISTS tempo.oneendo_3229_27;
CREATE TABLE tempo.oneendo_3229_27 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_baltic_3229_27.catchments AS ha);--683 (bc islands)
CREATE INDEX idx_tempo_oneendo_3229_27 ON tempo.oneendo_3229_27 USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_3229_27
    ON ba.shape && oneendo_3229_27.geom
    AND ST_Intersects(ba.shape, oneendo_3229_27.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_barent.catchments
    UNION ALL
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_3229_27.catchments
SELECT *
FROM filtered_basin;



DROP TABLE IF EXISTS tempo.oneendo_2622;
CREATE TABLE tempo.oneendo_26_22 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_baltic_26_22.catchments AS ha);--93
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
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_26_22.catchments
SELECT *
FROM filtered_basin;--52



DROP TABLE IF EXISTS tempo.oneendo_nsean;
CREATE TABLE tempo.oneendo_nsean AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_nsea_north.catchments AS ha);--381
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
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
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
INSERT INTO h_nsea_north.catchments
SELECT *
FROM filtered_basin;--28



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
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_barent.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
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


-- Not going to work, same problem as before
DROP TABLE IF EXISTS tempo.oneendo_barent;
CREATE TABLE tempo.oneendo_barent AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_barent.catchments AS ha);--351
CREATE INDEX idx_tempo_oneendo_barent ON tempo.oneendo_barent USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_barent
    ON ba.shape && oneendo_barent.geom
    AND ST_Intersects(ba.shape, oneendo_barent.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_barent.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3229_27.catchments
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
INSERT INTO h_barent.catchments
SELECT *
FROM filtered_basin;


DROP TABLE IF EXISTS tempo.oneendo_nseauk;
CREATE TABLE tempo.oneendo_nseauk AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_nsea_uk.catchments AS ha);--32
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
    FROM h_nsea_uk.catchments
    ),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nsea_uk.catchments
SELECT *
FROM filtered_basin;--35


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
    FROM h_nsea_uk.catchments
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


-- still missing some (NL)
DROP TABLE IF EXISTS tempo.oneendo_nseas;
CREATE TABLE tempo.oneendo_nseas AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_nsea_south.catchments AS ha);--91
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
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
    UNION ALL
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_biscay_iberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_west.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nsea_south.catchments
SELECT *
FROM filtered_basin;--95



DROP TABLE IF EXISTS tempo.oneendo_bisciber;
CREATE TABLE tempo.oneendo_bisciber AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_biscay_iberian.catchments AS ha);--67
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
    FROM h_biscay_iberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_west.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_biscay_iberian.catchments
SELECT *
FROM filtered_basin;--65



DROP TABLE IF EXISTS tempo.oneendo_medw;
CREATE TABLE tempo.oneendo_medw AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_med_west.catchments AS ha);--75
CREATE INDEX idx_tempo_oneendo_medw ON tempo.oneendo_medw USING GIST(geom);
	
-- oneendo is too big, problem with adriatic. I'll have to run it again with a smaller indice.
-- Maybe to do before biscay as well
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_medw
    ON ba.shape && oneendo_medw.geom
    AND ST_Intersects(ba.shape, oneendo_medw.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscay_iberian.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_west.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_central.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_med_west.catchments
SELECT *
FROM filtered_basin;--150



DROP TABLE IF EXISTS tempo.oneendo_medc;
CREATE TABLE tempo.oneendo_medc AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_med_central.catchments AS ha);--65
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
    FROM h_med_west.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_east.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_med_central.catchments
SELECT *
FROM filtered_basin;--84


DROP TABLE IF EXISTS tempo.oneendo_mede;
CREATE TABLE tempo.oneendo_mede AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.5,FALSE) geom
	FROM h_med_east.catchments AS ha);--226
CREATE INDEX idx_tempo_oneendo_mede ON tempo.oneendo_mede USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_mede
    ON ba.shape && oneendo_mede.geom
    AND ST_Intersects(ba.shape, oneendo_mede.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_east.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_med_east.catchments
SELECT *
FROM filtered_basin;


DROP TABLE IF EXISTS tempo.oneendo_bsea;
CREATE TABLE tempo.oneendo_bsea AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.01,FALSE) geom
	FROM h_black_sea.catchments AS ha);--38
CREATE INDEX idx_tempo_oneendo_bsea ON tempo.oneendo_bsea USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_bsea
    ON ba.shape && oneendo_bsea.geom
    AND ST_Intersects(ba.shape, oneendo_bsea.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_east.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_black_sea.catchments
SELECT *
FROM filtered_basin;


-- hmmmmmmmmmmm
DROP TABLE IF EXISTS tempo.oneendo_adriatic;
CREATE TABLE tempo.oneendo_adriatic AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_adriatic.catchments AS ha);--152
CREATE INDEX idx_tempo_oneendo_adriatic ON tempo.oneendo_adriatic USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_adriatic
    ON ba.shape && oneendo_adriatic.geom
    AND ST_Intersects(ba.shape, oneendo_adriatic.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_med_west.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_east.catchments
    UNION ALL
    SELECT shape 
    FROM h_black_sea.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_adriatic.catchments
SELECT *
FROM filtered_basin;





-- Donc la je teste l'intéraction et tout pour récupérer les basins manquants. MAIS il en manque quand même
-- C'est chiant


------------------------------------------------------------