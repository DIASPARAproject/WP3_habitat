
ALTER TABLE ices_areas.ices_areas_20160601_cut_dense_3857
RENAME COLUMN wkb_geometry TO geom;

ALTER TABLE ices_ecoregions.ices_ecoregions_20171207_erase_esri
RENAME COLUMN wkb_geometry TO geom;

ALTER TABLE tempo.ne_10m_admin_0_countries
RENAME COLUMN wkb_geometry TO geom;

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
JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
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
JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(ia.geom,4326),
    0.01
)
WHERE ia.subdivisio=ANY(ARRAY['32','29','28','27'])); --569


DROP TABLE IF EXISTS tempo.ices_areas_26_22;
CREATE TABLE tempo.ices_areas_26_22 AS (
SELECT dp.*
FROM tempo.riveratlas_mds AS dp
JOIN ices_areas."ices_areas_20160601_cut_dense_3857" AS ia
ON ST_DWithin(
    dp.downstream_point,
    ST_Transform(ia.geom,4326),
    0.02
)
WHERE ia.subdivisio=ANY(ARRAY['26','25','24','22'])); --463


-- ICES Ecoregions
DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_north;
CREATE TABLE tempo.ices_ecoregions_nsea_north AS (
    SELECT dp.*
    FROM tempo.riveratlas_mds AS dp
    JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(er.geom, 4326),
        0.04
    )
    JOIN tempo.ne_10m_admin_0_countries AS cs
    ON ST_DWithin(
        dp.downstream_point,
        ST_Transform(cs.geom, 4326),
        0.02
    )
    WHERE er.objectid = 11
      AND cs.name IN ('Norway','Sweden')
);--1269

DROP TABLE IF EXISTS tempo.ices_ecoregions_nsea_north;
CREATE TABLE tempo.ices_ecoregions_nsea_north AS (
    WITH ecoregion_points AS (
        SELECT DISTINCT dp.*
        FROM tempo.riveratlas_mds AS dp
        JOIN ices_ecoregions."ices_ecoregions_20171207_erase_esri" AS er
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(er.geom, 4326),
            0.04
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(cs.geom, 4326),
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
            ST_Transform(ia.geom, 4326),
            0.04
        )
        JOIN tempo.ne_10m_admin_0_countries AS cs
        ON ST_DWithin(
            dp.downstream_point,
            ST_Transform(cs.geom, 4326),
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
        -- Sélection des points provenant des écorégions
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
        -- Sélection des points provenant des ICES Areas (subdivision '23')
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
    -- Combinaison des résultats avec suppression des doublons
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


--WITH filtered_points AS (
--    SELECT dp.*
--    FROM tempo.riveratlas_mds AS dp
--    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
--    ON ST_DWithin(
--        dp.downstream_point,
--        ST_Transform(er.geom, 4326),
--        0.1
--    )
--    JOIN tempo.ne_10m_admin_0_countries AS cs
--    ON ST_DWithin(
--        dp.downstream_point,
--        ST_Transform(cs.geom, 4326),
--        0.02
--    )
--    WHERE er.objectid = 11
--      AND cs.name IN ('Norway','Sweden')
--),
--excluded_points AS (
--    SELECT downstream_point
--    FROM tempo.ices_areas_26_22
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_areas_3229_27
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_areas_3031
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_ecoregions_barent
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_north
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_ecoregions_norwegian
--    UNION ALL
--    SELECT downstream_point FROM tempo.ices_ecoregions_nsea_south
--),
--missing_points AS (
--    SELECT fp.*
--    FROM filtered_points AS fp
--    LEFT JOIN excluded_points AS ep
--    ON ST_Equals(fp.downstream_point, ep.downstream_point)
--    WHERE ep.downstream_point IS NULL
--)
--INSERT INTO tempo.ices_ecoregions_nsea_north
--SELECT mp.*
--FROM missing_points AS mp;--14


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
FROM missing_points AS mp;--33


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
FROM missing_points AS mp;--68


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
);--12896
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


DROP TABLE IF EXISTS h_baltic_3229_27.catchments;
CREATE TABLE h_baltic_3229_27.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3229_27.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--35901


DROP TABLE IF EXISTS h_baltic_26_22.catchments;
CREATE TABLE h_baltic_26_22.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_26_22.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--29055


DROP TABLE IF EXISTS h_nsea_north.catchments;
CREATE TABLE h_nsea_north.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_north.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--21858


DROP TABLE IF EXISTS h_nsea_uk.catchments;
CREATE TABLE h_nsea_uk.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_uk.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--9863


DROP TABLE IF EXISTS h_nsea_south.catchments;
CREATE TABLE h_nsea_south.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_south.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--40486


DROP TABLE IF EXISTS h_celtic.catchments;
CREATE TABLE h_celtic.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_celtic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--19882


DROP TABLE IF EXISTS h_iceland.catchments;
CREATE TABLE h_iceland.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_iceland.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--18142


DROP TABLE IF EXISTS h_barent.catchments;
CREATE TABLE h_barent.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_barent.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--84190


DROP TABLE IF EXISTS h_norwegian.catchments;
CREATE TABLE h_norwegian.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_norwegian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--13287


DROP TABLE IF EXISTS h_biscay_iberian.catchments;
CREATE TABLE h_biscay_iberian.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_biscay_iberian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--44324


DROP TABLE IF EXISTS h_med_west.catchments;
CREATE TABLE h_med_west.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--28115


DROP TABLE IF EXISTS h_med_central.catchments;
CREATE TABLE h_med_central.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--4125


DROP TABLE IF EXISTS h_med_east.catchments;
CREATE TABLE h_med_east.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--23257


DROP TABLE IF EXISTS h_adriatic.catchments;
CREATE TABLE h_adriatic.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_adriatic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--18305


DROP TABLE IF EXISTS h_black_sea.catchments;
CREATE TABLE h_black_sea.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_black_sea.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--146575


DROP TABLE IF EXISTS h_south_med_west.catchments;
CREATE TABLE h_south_med_west.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--12347


DROP TABLE IF EXISTS h_south_med_central.catchments;
CREATE TABLE h_south_med_central.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--6188


DROP TABLE IF EXISTS h_south_med_east.catchments;
CREATE TABLE h_south_med_east.catchments AS (
	SELECT hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--160160



-- TODO Try to retrieve missing endoheric basins with ST_Envelope



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



-- TODO add wso_id from ccm to hydroatlas





ALTER TABLE w2020.catchments
RENAME shape TO geom;
ALTER TABLE w2021.catchments
RENAME shape TO geom;
ALTER TABLE w2022.catchments
RENAME shape TO geom;


CREATE INDEX hydroatlas_catchments_geom_idx ON w2020.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2021.catchments USING GIST(geom);
CREATE INDEX hydroatlas_catchments_geom_idx ON w2022.catchments USING GIST(geom);