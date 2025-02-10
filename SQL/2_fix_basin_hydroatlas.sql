
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
);--9


-- Selecting south med data from hydroatlas (small catchments)
DROP TABLE IF EXISTS tempo.hydro_small_catchments;
CREATE TABLE tempo.hydro_small_catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
  SELECT 1
  FROM tempo.hydro_large_catchments hlce
  WHERE ST_Within(ba.shape,hlce.shape)
  )
);--75554
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
);--434740
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
	WHERE hydro_riversegments.hyriv_id = hydro_riversegments.main_riv); --7996


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
	WHERE t.hyriv_id = dp.hyriv_id; --7996

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
	WHERE er.objectid = 4
);--904


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
	WHERE er.objectid = 5
);--467


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
	WHERE er.objectid = 8
);--1187


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
	WHERE er.objectid = 7
);--507


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
	WHERE er.objectid = 6
);--982


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
	WHERE er.objectid = 4
);--268


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
	WHERE er.objectid = 8
);--173


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
	WHERE er.objectid = 5
);--329


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
	WHERE er.fia_division = ANY(ARRAY['27.2.b', '27.1.b'])
	AND dp.geom NOT IN (
	    SELECT existing.geom
	    FROM tempo.ices_ecoregions_barent AS existing)
); --1363
CREATE INDEX idx_tempo_ices_areas_svalbard ON tempo.ices_areas_svalbard USING GIST(downstream_point);

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
      AND dp.hyriv_id != 20615722
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
FROM missing_points AS mp;--172


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
    SELECT downstream_point FROM tempo.ices_ecoregions_south_med_west
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
CREATE SCHEMA h_baltic_3031;
DROP TABLE IF EXISTS h_baltic_3031.riversegments;
CREATE TABLE h_baltic_3031.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3031 AS ia
    ON hre.main_riv = ia.main_riv
);--27389

ALTER TABLE h_baltic_3031.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic_3031_riversegments_main_riv ON h_baltic_3031.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic_3031_riversegments ON h_baltic_3031.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_3229_27;
DROP TABLE IF EXISTS h_baltic_3229_27.riversegments;
CREATE TABLE h_baltic_3229_27.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_3229_27 AS ia
    ON hre.main_riv = ia.main_riv
);--30869

ALTER TABLE h_baltic_3229_27.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic_3229_27_riversegments_main_riv ON h_baltic_3229_27.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic_3229_27_riversegments ON h_baltic_3229_27.riversegments USING GIST(geom);


CREATE SCHEMA h_baltic_26_22;
DROP TABLE IF EXISTS h_baltic_26_22.riversegments;
CREATE TABLE h_baltic_26_22.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_areas_26_22 AS ia
    ON hre.main_riv = ia.main_riv
);--25120

ALTER TABLE h_baltic_26_22.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_baltic_26_22_riversegments_main_riv ON h_baltic_26_22.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_baltic_26_22_riversegments ON h_baltic_26_22.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_north;
DROP TABLE IF EXISTS h_nsea_north.riversegments;
CREATE TABLE h_nsea_north.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_north AS ie
    ON hre.main_riv = ie.main_riv
);--20338

ALTER TABLE h_nsea_north.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nsea_north_riversegments_main_riv ON h_nsea_north.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nsea_north_riversegments ON h_nsea_north.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_uk;
DROP TABLE IF EXISTS h_nsea_uk.riversegments;
CREATE TABLE h_nsea_uk.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_uk AS ie
    ON hre.main_riv = ie.main_riv
);--9060

ALTER TABLE h_nsea_uk.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nsea_uk_riversegments_main_riv ON h_nsea_uk.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nsea_uk_riversegments ON h_nsea_uk.riversegments USING GIST(geom);


CREATE SCHEMA h_nsea_south;
DROP TABLE IF EXISTS h_nsea_south.riversegments;
CREATE TABLE h_nsea_south.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_nsea_south AS ie
    ON hre.main_riv = ie.main_riv
);--35954

ALTER TABLE h_nsea_south.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_nsea_south_riversegments_main_riv ON h_nsea_south.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_nsea_south_riversegments ON h_nsea_south.riversegments USING GIST(geom);


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


CREATE SCHEMA h_barent;
DROP TABLE IF EXISTS h_barent.riversegments;
CREATE TABLE h_barent.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_barent AS ie
    ON hre.main_riv = ie.main_riv
);--73691

ALTER TABLE h_barent.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_barent_riversegments_main_riv ON h_barent.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_barent_riversegments ON h_barent.riversegments USING GIST(geom);


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


CREATE SCHEMA h_biscay_iberian;
DROP TABLE IF EXISTS h_biscay_iberian.riversegments;
CREATE TABLE h_biscay_iberian.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_biscay_iberian AS ie
    ON hre.main_riv = ie.main_riv
);--39247

ALTER TABLE h_biscay_iberian.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_biscay_iberian_riversegments_main_riv ON h_biscay_iberian.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_biscay_iberian_riversegments ON h_biscay_iberian.riversegments USING GIST(geom);


CREATE SCHEMA h_med_west;
DROP TABLE IF EXISTS h_med_west.riversegments;
CREATE TABLE h_med_west.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--25256

ALTER TABLE h_med_west.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_med_west_riversegments_main_riv ON h_med_west.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_med_west_riversegments ON h_med_west.riversegments USING GIST(geom);


CREATE SCHEMA h_med_central;
DROP TABLE IF EXISTS h_med_central.riversegments;
CREATE TABLE h_med_central.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--3779

ALTER TABLE h_med_central.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_med_central_riversegments_main_riv ON h_med_central.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_med_central_riversegments ON h_med_central.riversegments USING GIST(geom);


CREATE SCHEMA h_med_east;
DROP TABLE IF EXISTS h_med_east.riversegments;
CREATE TABLE h_med_east.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_med_east AS ie
    ON hre.main_riv = ie.main_riv
);--20479

ALTER TABLE h_med_east.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_med_east_riversegments_main_riv ON h_med_east.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_med_east_riversegments ON h_med_east.riversegments USING GIST(geom);


CREATE SCHEMA h_adriatic;
DROP TABLE IF EXISTS h_adriatic.riversegments;
CREATE TABLE h_adriatic.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_adriatic AS ie
    ON hre.main_riv = ie.main_riv
);--16631

ALTER TABLE h_adriatic.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_adriatic_riversegments_main_riv ON h_adriatic.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_adriatic_riversegments ON h_adriatic.riversegments USING GIST(geom);


CREATE SCHEMA h_black_sea;
DROP TABLE IF EXISTS h_black_sea.riversegments;
CREATE TABLE h_black_sea.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.ices_ecoregions_black_sea AS ie
    ON hre.main_riv = ie.main_riv
);--127453

ALTER TABLE h_black_sea.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_black_sea_riversegments_main_riv ON h_black_sea.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_black_sea_riversegments ON h_black_sea.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_west;
DROP TABLE IF EXISTS h_south_med_west.riversegments;
CREATE TABLE h_south_med_west.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_west AS ie
    ON hre.main_riv = ie.main_riv
);--10716

ALTER TABLE h_south_med_west.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_south_med_west_riversegments_main_riv ON h_south_med_west.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_south_med_west_riversegments ON h_south_med_west.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_central;
DROP TABLE IF EXISTS h_south_med_central.riversegments;
CREATE TABLE h_south_med_central.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_central AS ie
    ON hre.main_riv = ie.main_riv
);--5403

ALTER TABLE h_south_med_central.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_south_med_central_riversegments_main_riv ON h_south_med_central.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_south_med_central_riversegments ON h_south_med_central.riversegments USING GIST(geom);


CREATE SCHEMA h_south_med_east;
DROP TABLE IF EXISTS h_south_med_east.riversegments;
CREATE TABLE h_south_med_east.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_med_east AS ie
    ON hre.main_riv = ie.main_riv
);--136034

ALTER TABLE h_south_med_east.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_south_med_east_riversegments_main_riv ON h_south_med_east.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_south_med_east_riversegments ON h_south_med_east.riversegments USING GIST(geom);


CREATE SCHEMA h_south_atlantic;
DROP TABLE IF EXISTS h_south_atlantic.riversegments;
CREATE TABLE h_south_atlantic.riversegments AS (
    SELECT DISTINCT ON (hre.geom) hre.*
    FROM tempo.hydro_riversegments AS hre
    JOIN tempo.ices_ecoregions_south_atlantic AS ie
    ON hre.main_riv = ie.main_riv
);--21183

ALTER TABLE h_south_atlantic.riversegments
ADD CONSTRAINT pk_hyriv_id PRIMARY KEY (hyriv_id);

CREATE INDEX idx_h_south_atlantic_riversegments_main_riv ON h_south_atlantic.riversegments USING BTREE(main_riv);
CREATE INDEX idx_h_south_atlantic_riversegments ON h_south_atlantic.riversegments USING GIST(geom);



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




-------------- Step 5 : Select all corresponding catchments --------------
DROP TABLE IF EXISTS h_baltic_3031.catchments;
CREATE TABLE h_baltic_3031.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3031.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
); --3638

ALTER TABLE h_baltic_3031.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic_3031_catchments_main_bas ON h_baltic_3031.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic_3031_catchments ON h_baltic_3031.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_baltic_3229_27.catchments;
CREATE TABLE h_baltic_3229_27.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_baltic_3229_27.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	WHERE hce.shape NOT IN (
			SELECT existing.shape
	    	FROM h_baltic_3031.catchments AS existing)
);--4934

ALTER TABLE h_baltic_3229_27.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic_3229_27_catchments_main_bas ON h_baltic_3229_27.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic_3229_27_catchments ON h_baltic_3229_27.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_baltic_26_22.catchments;
CREATE TABLE h_baltic_26_22.catchments AS (
    SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--3878

ALTER TABLE h_baltic_26_22.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_baltic_26_22_catchments_main_bas ON h_baltic_26_22.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_baltic_26_22_catchments ON h_baltic_26_22.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nsea_north.catchments;
CREATE TABLE h_nsea_north.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--1602

ALTER TABLE h_nsea_north.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nsea_north_catchments_main_bas ON h_nsea_north.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nsea_north_catchments ON h_nsea_north.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nsea_uk.catchments;
CREATE TABLE h_nsea_uk.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_nsea_uk.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--962

ALTER TABLE h_nsea_uk.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nsea_uk_catchments_main_bas ON h_nsea_uk.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nsea_uk_catchments ON h_nsea_uk.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_nsea_south.catchments;
CREATE TABLE h_nsea_south.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--4592

ALTER TABLE h_nsea_south.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_nsea_south_catchments_main_bas ON h_nsea_south.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_nsea_south_catchments ON h_nsea_south.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_celtic.catchments;
CREATE TABLE h_celtic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_celtic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_uk.catchments
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


DROP TABLE IF EXISTS h_barent.catchments;
CREATE TABLE h_barent.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--9838

ALTER TABLE h_barent.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_barent_catchments_main_bas ON h_barent.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_barent_catchments ON h_barent.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_norwegian.catchments;
CREATE TABLE h_norwegian.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--520

ALTER TABLE h_norwegian.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_norwegian_catchments_main_bas ON h_norwegian.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_norwegian_catchments ON h_norwegian.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_biscay_iberian.catchments;
CREATE TABLE h_biscay_iberian.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_biscay_iberian.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_nsea_south.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--5031

ALTER TABLE h_biscay_iberian.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_biscay_iberian_catchments_main_bas ON h_biscay_iberian.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_biscay_iberian_catchments ON h_biscay_iberian.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_med_west.catchments;
CREATE TABLE h_med_west.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--3100

ALTER TABLE h_med_west.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_med_west_catchments_main_bas ON h_med_west.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_med_west_catchments ON h_med_west.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_med_central.catchments;
CREATE TABLE h_med_central.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_west.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--531

ALTER TABLE h_med_central.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_med_central_catchments_main_bas ON h_med_central.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_med_central_catchments ON h_med_central.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_med_east.catchments;
CREATE TABLE h_med_east.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_central.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3100

ALTER TABLE h_med_east.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_med_east_catchments_main_bas ON h_med_east.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_med_east_catchments ON h_med_east.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_adriatic.catchments;
CREATE TABLE h_adriatic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--1738

ALTER TABLE h_adriatic.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_adriatic_catchments_main_bas ON h_adriatic.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_adriatic_catchments_geom ON h_adriatic.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_black_sea.catchments;
CREATE TABLE h_black_sea.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
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
);--18462

ALTER TABLE h_black_sea.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_black_sea_catchments_main_bas ON h_black_sea.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_black_sea_catchments ON h_black_sea.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_east.catchments;
CREATE TABLE h_south_med_east.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_east.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--22792

ALTER TABLE h_south_med_east.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_south_med_east_catchments_main_bas ON h_south_med_east.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_south_med_east_catchments ON h_south_med_east.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_central.catchments;
CREATE TABLE h_south_med_central.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_central.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_south_med_east.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--881

ALTER TABLE h_south_med_central.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_south_med_central_catchments_main_bas ON h_south_med_central.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_south_med_central_catchments ON h_south_med_central.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_south_med_west.catchments;
CREATE TABLE h_south_med_west.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_med_west.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_south_med_central.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--1661

ALTER TABLE h_south_med_west.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_south_med_west_catchments_main_bas ON h_south_med_west.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_south_med_west_catchments ON h_south_med_west.catchments USING GIST(shape);



DROP TABLE IF EXISTS h_south_atlantic.catchments;
CREATE TABLE h_south_atlantic.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments AS hce
	JOIN h_south_atlantic.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
	LEFT JOIN (
        SELECT shape FROM h_south_med_west.catchments
    ) AS excluded
    ON hce.shape && excluded.shape
    AND ST_Equals(hce.shape, excluded.shape)
    WHERE excluded.shape IS NULL
);--3502

ALTER TABLE h_south_atlantic.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_south_atlantic_catchments_main_bas ON h_south_atlantic.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_south_atlantic_catchments ON h_south_atlantic.catchments USING GIST(shape);


DROP TABLE IF EXISTS h_svalbard.catchments;
CREATE TABLE h_svalbard.catchments AS (
	SELECT DISTINCT ON (hce.hybas_id) hce.*
	FROM tempo.hydro_small_catchments_europe AS hce
	JOIN h_svalbard.riversegments AS rs
	ON ST_Intersects(hce.shape,rs.geom)
);--336

ALTER TABLE h_svalbard.catchments
ADD CONSTRAINT pk_hybas_id PRIMARY KEY (hybas_id);

CREATE INDEX idx_h_svalbard_catchments_main_bas ON h_svalbard.catchments USING BTREE(main_bas);
CREATE INDEX idx_h_svalbard_catchments ON h_svalbard.catchments USING GIST(shape);


------------------ TESTING STUFF HERE DON'T MIND ME ------------------

-- TODO Try to retrieve missing endoheric basins with ST_Envelope
-- Sélection des bassins endoréiques touchant l'enveloppe géographique de h_adriatic.shape

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

INSERT INTO h_baltic_3031.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic_3031.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic_3031.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--1



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
    WHERE ba.main_bas != 2120068680
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
    SELECT DISTINCT ON (eb.hybas_id) eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_3229_27.catchments
SELECT *
FROM filtered_basin;--52

INSERT INTO h_baltic_3229_27.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic_3229_27.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic_3229_27.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--12


DROP TABLE IF EXISTS tempo.oneendo_26_22;
CREATE TABLE tempo.oneendo_26_22 AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_baltic_26_22.catchments AS ha);--94
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
FROM filtered_basin;--50


INSERT INTO h_baltic_26_22.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_baltic_26_22.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_baltic_26_22.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--17


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
    SELECT DISTINCT ON (hybas_id) eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nsea_north.catchments
SELECT *
FROM filtered_basin;--27


INSERT INTO h_nsea_north.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nsea_north.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nsea_north.riversegments ex
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
	FROM h_barent.catchments AS ha);--351
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
FROM filtered_basin;--359

INSERT INTO h_barent.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_barent.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_barent.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--1045



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

INSERT INTO h_nsea_uk.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nsea_uk.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nsea_uk.riversegments ex
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
INSERT INTO h_nsea_south.catchments
SELECT *
FROM filtered_basin;--71 (1 min)


INSERT INTO h_nsea_south.riversegments
SELECT r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_nsea_south.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_nsea_south.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--5


--WITH riversegments_in_zone AS (
--    SELECT rs.*
--    FROM tempo.hydro_riversegments_europe AS rs
--    JOIN tempo.oneendo_nseas
--    ON rs.geom && oneendo_nseas.geom
--    AND ST_Intersects(rs.geom, oneendo_nseas.geom)
--    WHERE rs.endorheic = 1
--),
--excluded_segments AS (
--    SELECT rs.*
--    FROM tempo.hydro_riversegments_europe AS rs
--    JOIN (
--        SELECT shape 
--    FROM h_baltic_26_22.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_nsea_north.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_black_sea.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_adriatic.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_biscay_iberian.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_med_west.catchments
--    UNION ALL
--    SELECT shape 
--    FROM h_nsea_south.catchments
--    ) AS excluded_basins
--    ON rs.geom && excluded_basins.shape
--    AND ST_Intersects(rs.geom, excluded_basins.shape)
--),
--filtered_segments AS (
--    SELECT rsz.*
--    FROM riversegments_in_zone rsz
--    LEFT JOIN excluded_segments exs
--    ON rsz.geom && exs.geom
--    AND ST_Equals(rsz.geom, exs.geom)
--    WHERE exs.geom IS NULL
--),
--final_segments AS (
--    SELECT rs.*
--    FROM tempo.hydro_riversegments_europe AS rs
--    WHERE rs.main_riv IN (
--        SELECT DISTINCT fs.main_riv
--        FROM filtered_segments fs
--    )
--)
----INSERT INTO h_med_east.riversegments
--SELECT *
--FROM final_segments;

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
INSERT INTO h_biscay_iberian.catchments
SELECT *
FROM filtered_basin;--62


INSERT INTO h_biscay_iberian.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_biscay_iberian.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_biscay_iberian.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--57


DROP TABLE IF EXISTS tempo.oneendo_medw;
CREATE TABLE tempo.oneendo_medw AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_med_west.catchments AS ha);--75
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
INSERT INTO h_med_west.catchments
SELECT *
FROM filtered_basin;--152


INSERT INTO h_med_west.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_med_west.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_med_west.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--273


DROP TABLE IF EXISTS tempo.oneendo_medc;
CREATE TABLE tempo.oneendo_medc AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.4,FALSE) geom
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
    UNION ALL
    SELECT shape
    FROM basinatlas.basinatlas_v10_lev12
    WHERE main_bas = ANY(ARRAY[2120011730, 2120014300, 2120087740, 2120099800, 2120045580, 2120045160, 2120010660,
    							2120010620, 2120010580, 2120010540, 2120045200])
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
FROM filtered_basin;--87


INSERT INTO h_med_central.riversegments
SELECT DISTINCT ON (r.hyriv_id) r.*
FROM tempo.hydro_riversegments_europe r
JOIN h_med_central.catchments c
ON r.geom && c.shape
AND ST_Intersects(r.geom, c.shape)
WHERE NOT EXISTS (
    SELECT *
    FROM h_med_central.riversegments ex
    WHERE r.geom && ex.geom
    AND ST_Equals(r.geom, ex.geom)
);--244


DROP TABLE IF EXISTS tempo.oneendo_mede;
CREATE TABLE tempo.oneendo_mede AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.5,FALSE) geom
	FROM h_med_east.catchments AS ha);--226
CREATE INDEX idx_tempo_oneendo_mede ON tempo.oneendo_mede USING GIST(geom);



-- test with riversegments
WITH riversegments_in_zone AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    JOIN tempo.oneendo_mede
    ON rs.geom && oneendo_mede.geom
    AND ST_Intersects(rs.geom, oneendo_mede.geom)
    WHERE rs.endorheic = 1
),
excluded_segments AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    JOIN (
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
        UNION ALL
        SELECT geom
        FROM tempo.hydro_riversegments_europe
        WHERE main_riv = ANY(ARRAY[20641990, 20641991, 20641880])
    ) AS excluded_basins
    ON rs.geom && excluded_basins.shape
    AND ST_Intersects(rs.geom, excluded_basins.shape)
),
filtered_segments AS (
    SELECT rsz.*
    FROM riversegments_in_zone rsz
    LEFT JOIN excluded_segments exs
    ON rsz.geom && exs.geom
    AND ST_Equals(rsz.geom, exs.geom)
    WHERE exs.geom IS NULL
),
final_segments AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    WHERE rs.main_riv IN (
        SELECT DISTINCT fs.main_riv
        FROM filtered_segments fs
    )
)
INSERT INTO h_med_east.riversegments
SELECT *
FROM final_segments;--3941 (16 min?!)


INSERT INTO h_med_east.catchments
SELECT DISTINCT ON (c.hybas_id) c.*
FROM tempo.hydro_small_catchments_europe c
JOIN h_med_east.riversegments r
ON c.shape && r.geom
AND ST_Intersects(c.shape, r.geom)
WHERE NOT EXISTS (
    SELECT *
    FROM h_med_east.catchments ex
    WHERE c.shape && ex.shape
    AND ST_Equals(c.shape, ex.shape)
);--705


DROP TABLE IF EXISTS tempo.oneendo_mede;
CREATE TABLE tempo.oneendo_mede AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.05,FALSE) geom
	FROM h_med_east.catchments AS ha);--234
CREATE INDEX idx_tempo_oneendo_mede ON tempo.oneendo_mede USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM tempo.hydro_small_catchments_europe AS ba
    JOIN tempo.oneendo_mede
    ON ba.shape && oneendo_mede.geom
    AND ST_Intersects(ba.shape, oneendo_mede.geom)
    WHERE endo = ANY(ARRAY[1, 2])
),
excluded_basins AS (
    SELECT shape 
    FROM h_med_east.catchments
    UNION ALL
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
    FROM tempo.hydro_small_catchments_europe
    WHERE main_bas = ANY(ARRAY[2120085960, 2120100150, 2120102750, 2120108140, 2120108130])
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
FROM filtered_basin;--89


SELECT 
    geom, 
    COUNT(*) AS duplicate_count
FROM h_svalbard.riversegments
GROUP BY geom
HAVING COUNT(*) > 1;



DROP TABLE IF EXISTS tempo.oneendo_bsea;
CREATE TABLE tempo.oneendo_bsea AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.1,FALSE) geom
	FROM h_black_sea.catchments AS ha);--38
CREATE INDEX idx_tempo_oneendo_bsea ON tempo.oneendo_bsea USING GIST(geom);

WITH riversegments_in_zone AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    WHERE rs.endorheic = 1
    AND rs.main_riv != 20490321
    AND EXISTS (
        SELECT * FROM tempo.oneendo_bsea ob
        WHERE rs.geom && ob.geom
        AND ST_Intersects(rs.geom, ob.geom)
    )
),
excluded_segments AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    JOIN (
        SELECT shape 
        FROM h_black_sea.catchments
        UNION ALL
        SELECT shape 
        FROM h_baltic_26_22.catchments
        UNION ALL
        SELECT shape 
        FROM h_baltic_3229_27.catchments
        UNION ALL
        SELECT shape 
        FROM h_med_east.catchments
        UNION ALL
        SELECT shape 
        FROM h_nsea_south.catchments
        UNION ALL
        SELECT shape 
        FROM h_adriatic.catchments
    ) AS excluded_basins
    ON rs.geom && excluded_basins.shape
    AND ST_Intersects(rs.geom, excluded_basins.shape)
),
filtered_segments AS (
    SELECT rsz.*
    FROM riversegments_in_zone rsz
    LEFT JOIN excluded_segments exs
    ON rsz.geom && exs.geom
    AND ST_Equals(rsz.geom, exs.geom)
    WHERE exs.geom IS NULL
),
final_segments AS (
    SELECT rs.*
    FROM tempo.hydro_riversegments_europe AS rs
    WHERE rs.main_riv IN (
        SELECT DISTINCT fs.main_riv
        FROM filtered_segments fs
    )
)
--INSERT INTO h_black_sea.riversegments
SELECT *
FROM final_segments;--1675


INSERT INTO h_black_sea.catchments
SELECT DISTINCT ON (c.hybas_id) c.*
FROM tempo.hydro_small_catchments_europe c
JOIN h_black_sea.riversegments r
ON c.shape && r.geom
AND ST_Intersects(c.shape, r.geom)
WHERE NOT EXISTS (
    SELECT *
    FROM h_black_sea.catchments ex
    WHERE c.shape && ex.shape
    AND ST_Equals(c.shape, ex.shape)
);--320

--------------- HERE -----------------
DROP TABLE IF EXISTS tempo.oneendo_bsea;
CREATE TABLE tempo.oneendo_bsea AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.001,FALSE) geom
	FROM h_black_sea.catchments AS ha);--38
CREATE INDEX idx_tempo_oneendo_bsea ON tempo.oneendo_bsea USING GIST(geom);

WITH endo_basins AS (	
    SELECT ba.*
    FROM tempo.hydro_small_catchments_europe AS ba
    JOIN tempo.oneendo_bsea
    ON ba.shape && oneendo_bsea.geom
    AND ST_Intersects(ba.shape, oneendo_bsea.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_black_sea.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_med_east.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape
    FROM tempo.hydro_small_catchments_europe
    WHERE main_bas = 2120068680
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
--INSERT INTO h_black_sea.catchments
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
--INSERT INTO h_adriatic.catchments
SELECT *
FROM filtered_basin;

------------------------------------------------------------

-- Retrieving last islands and basins along the coast


WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_Intersects(c.shape, ia.geom)
	WHERE ia.subdivisio=ANY(ARRAY['31','30'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3229_27.catchments
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
INSERT INTO h_baltic_3031.catchments
SELECT *
FROM filtered_basin;--2

-- Donc la je teste l'intéraction et tout pour récupérer les basins manquants. MAIS il en manque quand même
-- C'est chiant


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
	ON ST_Intersects(c.shape, ia.geom)
	WHERE ia.subdivisio=ANY(ARRAY['32','29','28','27'])
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic_3031.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_3229_27.catchments
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
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_3229_27.catchments
    UNION ALL
    SELECT shape 
    FROM h_nsea_north.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic_26_22.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_baltic_26_22.catchments
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
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape
    FROM h_nsea_uk.catchments
    UNION ALL
    SELECT shape
    FROM h_nsea_north.catchments
    UNION ALL
    SELECT shape
    FROM h_baltic_26_22.catchments
    UNION ALL
    SELECT shape
    FROM h_biscay_iberian.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_nsea_south.catchments
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
    FROM h_nsea_uk.catchments
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
    FROM h_biscay_iberian.catchments
    UNION ALL
    SELECT shape
    FROM h_nsea_south.catchments
    UNION ALL
    SELECT shape
    FROM h_med_west.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_biscay_iberian.catchments
SELECT *
FROM filtered_basin;--1


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 4
),
excluded_basins AS (
    SELECT shape 
    FROM h_biscay_iberian.catchments
    UNION ALL
    SELECT shape
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape
    FROM h_med_west.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_med_west.catchments
SELECT *
FROM filtered_basin;--15


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 5
),
excluded_basins AS (
    SELECT shape 
    FROM h_med_east.catchments
    UNION ALL
    SELECT shape
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape
    FROM h_med_west.catchments
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
INSERT INTO h_med_central.catchments
SELECT *
FROM filtered_basin;--2


WITH last_basin AS (
	SELECT DISTINCT ON (c.hybas_id) c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
	ON ST_Intersects(c.shape, er.geom)
	WHERE er.objectid = 8
),
excluded_basins AS (
    SELECT shape 
    FROM h_med_east.catchments
    UNION ALL
    SELECT shape
    FROM h_med_central.catchments
    UNION ALL
    SELECT shape
    FROM h_black_sea.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO h_med_east.catchments
SELECT *
FROM filtered_basin;--116


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
    FROM h_barent.catchments
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
FROM filtered_basin;--7

