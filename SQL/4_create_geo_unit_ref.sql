-- Creating Baltic Stock tr

ALTER TABLE REF.tr_area_are OWNER TO diaspara_admin;

DROP TABLE IF EXISTS refbast.tr_area_are;
CREATE TABLE refbast.tr_area_are () INHERITS (ref.tr_area_are);
ALTER TABLE refbast.tr_area_are OWNER TO diaspara_admin;


ALTER TABLE refbast.tr_area_are
	ALTER COLUMN are_wkg_code SET DEFAULT 'WGBAST';
ALTER TABLE refbast.tr_area_are ADD CONSTRAINT tr_area_area_pkey 
	PRIMARY KEY (are_id);
ALTER TABLE refbast.tr_area_are
ADD CONSTRAINT fk_are_are_id FOREIGN KEY (are_are_id)
	REFERENCES refbast.tr_area_are (are_id) ON DELETE CASCADE
	ON UPDATE CASCADE;
 ALTER TABLE refbast.tr_area_are
	ADD CONSTRAINT uk_are_code UNIQUE (are_code);
ALTER TABLE refbast.tr_area_are
	ADD CONSTRAINT fk_area_lev_code FOREIGN KEY (are_lev_code) REFERENCES
	ref.tr_habitatlevel_lev(lev_code) ON UPDATE CASCADE ON DELETE CASCADE;
 ALTER TABLE refbast.tr_area_are
	ADD CONSTRAINT fk_area_wkg_code FOREIGN KEY (are_wkg_code) REFERENCES
	ref.tr_icworkinggroup_wkg(wkg_code) ON UPDATE CASCADE ON DELETE CASCADE;

DROP SEQUENCE IF EXISTS refbast.seq;
CREATE SEQUENCE refbast.seq;
ALTER SEQUENCE refbast.seq RESTART WITH 2;
ALTER SEQUENCE refbast.seq OWNER TO diaspara_admin;
ALTER TABLE refbast.tr_area_are OWNER TO diaspara_admin;


-------------------------------- Stock level --------------------------------
INSERT INTO refbast.tr_area_are (are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
VALUES (1, 'Temporary Parent', 'Stock', true, NULL, NULL);


INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refbast.seq') AS are_id,
	1 AS are_are_id,
	'Baltic marine' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	true AS are_ismarine,
	ST_Union(geom) AS geom_polygon,
	NULL AS geom_line
	FROM ref.tr_fishingarea_fia 
	WHERE"fia_level"='Division' AND "fia_division" IN ('27.3.b, c','27.3.d');

INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refbast.seq') AS are_id,
	1 AS are_are_id,
	'Baltic inland' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
	FROM tempo.catchments_baltic
	WHERE rtrim(tableoid::regclass::text, '.catchments') IN ('h_baltic30to31', 'h_baltic22to26', 'h_baltic27to29_32');


WITH unioned_polygons AS (
  SELECT (ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(geom_polygon))).geom)),0.0001,FALSE)) AS geom
  FROM refbast.tr_area_are
),
area_check AS (
  SELECT geom, ST_Area(geom) AS area
  FROM unioned_polygons
),
filtered_polygon AS (
  SELECT geom
  FROM area_check
  WHERE area > 1
)
UPDATE refbast.tr_area_are
SET 
  are_are_id = NULL,
  are_code = 'Baltic',
  are_lev_code = 'Stock',
  are_ismarine = NULL,
  geom_polygon = (SELECT ST_Multi(geom) FROM filtered_polygon),
  geom_line = NULL
WHERE are_id = 1;



-------------------------------- Country level --------------------------------
DROP FUNCTION IF EXISTS insert_country_baltic(country TEXT);
CREATE OR REPLACE FUNCTION insert_country_baltic(country TEXT)
RETURNS VOID AS 
$$
BEGIN
  INSERT INTO refbast.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT 
    nextval('refbast.seq') AS are_id,
    3 AS are_are_id,
    cou_iso3code AS are_code,
    'Country' AS are_lev_code,
    false AS are_ismarine,
    geom AS geom_polygon,
    NULL AS geom_line
  FROM ref.tr_country_cou
  WHERE cou_iso3code = country;
END;
$$ LANGUAGE plpgsql;


SELECT insert_country_baltic('FIN');
SELECT insert_country_baltic('SWE');
SELECT insert_country_baltic('EST');
SELECT insert_country_baltic('LVA');
SELECT insert_country_baltic('LTU');
SELECT insert_country_baltic('POL');
SELECT insert_country_baltic('DEU');
SELECT insert_country_baltic('DNK');
SELECT insert_country_baltic('RUS');

	
-------------------------------- Assessment unit level --------------------------------
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 1
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'1 Northeastern Bothnian Bay' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;
	
	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 2
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'2 Western Bothnian Bay' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;

	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 3
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'3 Bothnian Sea' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;

	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 4
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'4 Western Main Basin' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;
	
	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 5
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'5 Eastern Main Basin' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;




INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
	SELECT trc.geom AS geom, trc.main_riv
	FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
	WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 6
),
retrieve_rivers AS(
	SELECT DISTINCT trc.geom
	FROM tempo.riversegments_baltic trc, unit_selection us
	WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
retrieve_catchments AS (
	SELECT DISTINCT ST_Union(tbc.shape) AS geom
	FROM tempo.catchments_baltic tbc, retrieve_rivers rr
	WHERE ST_Intersects(tbc.shape,rr.geom)
	AND tbc.main_bas <> 2120027530
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'6 Gulf of Finland' AS are_code,
		'Assessment_unit' AS are_lev_code,
		--are_wkg_code,
		false AS is_marine,
		ST_Union(geom) AS geom_polygon,
		NULL AS geom_line
		FROM retrieve_catchments;

	
	
-------------------------------- Rivers level --------------------------------
DROP FUNCTION IF EXISTS insert_river_areas(p_are_are_id INT, p_ass_unit INT);
CREATE OR REPLACE FUNCTION insert_river_areas(p_are_are_id INT, p_ass_unit INT) 
RETURNS VOID AS $$
BEGIN
  WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_baltic trc
    JOIN janis.bast_assessment_units jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE trc.ord_clas = 1
      AND jau."Ass_unit" = p_ass_unit
  ),
  all_segments AS (
    SELECT trc.main_riv, trc.geom
    FROM tempo.riversegments_baltic trc
    JOIN unit_riv ur ON ur.main_riv = trc.main_riv
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.hybas_id, tcb.main_bas, trc.main_riv, tcb.shape
    FROM tempo.catchments_baltic tcb
    JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
  ),
  deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, shape
    FROM catchments_with_riv
  ),
  merged AS (
    SELECT main_riv, MIN(main_bas) AS main_bas, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_riv
  )
  INSERT INTO refbast.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT 
    nextval('refbast.seq'),
    p_are_are_id,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM merged
  WHERE geom IS NOT NULL;
  
END;
$$ LANGUAGE plpgsql;



SELECT insert_river_areas(13,1);
SELECT insert_river_areas(14,2);
SELECT insert_river_areas(15,3);
SELECT insert_river_areas(16,4);
SELECT insert_river_areas(17,5);

-- for assessment unit 6 a main_bas exclusion is needed
WITH unit_riv AS (
  SELECT DISTINCT trc.main_riv
  FROM tempo.riversegments_baltic trc
  JOIN janis.bast_assessment_units jau
    ON ST_Intersects(trc.geom, jau.geom)
  WHERE trc.ord_clas = 1
    AND jau."Ass_unit" = 6
),
all_segments AS (
  SELECT trc.main_riv, trc.geom
  FROM tempo.riversegments_baltic trc
  JOIN unit_riv ur ON ur.main_riv = trc.main_riv
),
catchments_with_riv AS (
  SELECT DISTINCT tcb.hybas_id, tcb.main_bas, trc.main_riv, tcb.shape
  FROM tempo.catchments_baltic tcb
  JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
),
deduplicated AS (
  SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, shape
  FROM catchments_with_riv
),
merged AS (
  SELECT main_riv, MIN(main_bas) AS main_bas, ST_Union(shape) AS geom
  FROM deduplicated
  GROUP BY main_riv
)
INSERT INTO refbast.tr_area_are (
  are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
)
SELECT 
  nextval('refbast.seq'),
  18,
  main_bas::TEXT,
  'River',
  false,
  ST_Multi(geom),
  NULL
FROM merged
WHERE geom IS NOT NULL
  AND main_bas <> 2120027530;
	


-------------------------------- River section level --------------------------------
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH river_level AS (
  SELECT are_id, geom_polygon
  FROM refbast.tr_area_are
  WHERE are_lev_code = 'River'
),
river_segments AS (
  SELECT DISTINCT ON (rs.hyriv_id)
    nextval('refbast.seq') AS are_id,
    rl.are_id AS are_are_id,
    rs.hyriv_id::TEXT AS are_code,
    'River_section' AS are_lev_code,
    false AS is_marine,
    NULL,
    rs.geom
  FROM tempo.riversegments_baltic rs
  JOIN river_level rl
    ON ST_Intersects(rs.geom, rl.geom_polygon)
    WHERE rs.ord_clas = 1
)
SELECT DISTINCT ON (are_code) * FROM river_segments;
	

-------------------------------- Matching names to rivers --------------------------------
--CREATE INDEX idx_tempo_janis_wgbast ON janis.wgbast_combined USING GIST(geom);
WITH add_names AS (
    SELECT DISTINCT ON
    	(c.hyriv_id)
        c.geom, 
        c.main_riv, 
        c.hyriv_id,
        r."name" AS river_name
    FROM tempo.riversegments_baltic c
    JOIN janis.wgbast_combined r
        ON ST_Intersects(r.geom, c.geom)
    WHERE c.ord_clas = 1
),
basin_names AS (
    SELECT 
    	c.geom,
        c.hyriv_id,
        c.main_riv, 
        a.river_name
    FROM tempo.riversegments_baltic c
    INNER JOIN add_names a ON c.main_riv = a.main_riv
    WHERE c.ord_clas = 1
),
deduplicated_names AS (
    SELECT DISTINCT ON (hyriv_id) geom,hyriv_id, river_name
    FROM basin_names
)
UPDATE refbast.tr_area_are t
SET are_name = d.river_name
FROM deduplicated_names d
WHERE t.are_code = d.hyriv_id::TEXT;--3718


-- ICES Divisions
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH select_division AS (
	SELECT geom FROM ref.tr_fishingarea_fia tff
	WHERE tff.fia_level = 'Division' AND tff.fia_division = '27.3.b, c'
)
SELECT nextval('refbast.seq') AS are_id,
		2 AS are_are_id,
		'27.3.b, c' AS are_code,
		'Division' AS are_lev_code,
		--are_wkg_code,
		true AS is_marine,
		geom AS geom_polygon,
		NULL AS geom_line
		FROM select_division;


INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH select_division AS (
	SELECT geom FROM ref.tr_fishingarea_fia tff
	WHERE tff.fia_level = 'Division' AND tff.fia_division = '27.3.d'
)
SELECT nextval('refbast.seq') AS are_id,
		2 AS are_are_id,
		'27.3.d' AS are_code,
		'Division' AS are_lev_code,
		--are_wkg_code,
		true AS is_marine,
		geom AS geom_polygon,
		NULL AS geom_line
		FROM select_division;

--  Subdivision grouping 300 and 200 in the historical database

	/*
INSERT INTO ref.tr_habitatlevel_lev VALUES( 
  'Subdivision Grouping',
  'Groups of subdivision from ICES used in the Baltic');
*/ 
	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, are_name, geom_polygon, geom_line)
WITH select_division AS (
  SELECT geom FROM ref.tr_fishingarea_fia tff
  WHERE  tff.fia_level = 'Subdivision' AND tff.fia_subdivision IN ('27.3.d.30','27.3.d.31')
)
SELECT 7023,
    2 AS are_are_id,
    '27.3.d.30-31' AS are_code,
    'Subdivision_grouping' AS are_lev_code,
    --are_wkg_code,
    true AS is_marine,
    'Gulf of Bothnia (300)',
    st_union(geom) AS geom_polygon,
    NULL AS geom_line
    FROM select_division;

INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, are_name, geom_polygon, geom_line)
WITH select_division AS (
  SELECT geom FROM ref.tr_fishingarea_fia tff
  WHERE  tff.fia_level = 'Subdivision' AND tff.fia_subdivision IN ('27.3.d.22','27.3.d.23','27.3.d.24','27.3.d.25','27.3.d.26','27.3.d.27','27.3.d.28','27.3.d.29')
)
SELECT 7024,
    2 AS are_are_id,
    '27.3.d.22-29' AS are_code,
    'Subdivision_grouping' AS are_lev_code,
    --are_wkg_code,
    true AS is_marine,
    'Main Baltic (200)',
    st_union(geom) AS geom_polygon,
    NULL AS geom_line
    FROM select_division;


-- ICES subdivision
	
DROP FUNCTION IF EXISTS insert_fishing_subdivision(subdiv TEXT, p_are_are_id INT);
CREATE OR REPLACE FUNCTION insert_fishing_subdivision(subdiv TEXT, p_are_are_id INT)
RETURNS VOID AS 
$$
DECLARE 
  p_are_code TEXT;
BEGIN
  p_are_code := '27.3.' || subdiv;

  EXECUTE '
    INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH select_subdivision AS (
      SELECT geom FROM ref.tr_fishingarea_fia tff 
      WHERE tff.fia_level = ''Subdivision'' AND tff.fia_subdivision = ''' || p_are_code || '''
    )
    SELECT nextval(''refbast.seq'') AS are_id,
           ' || p_are_are_id || ' AS are_are_id,
           ''' || p_are_code || ''' AS are_code,
           ''Subdivision'' AS are_lev_code,
           true AS is_marine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM select_subdivision;
  ';
END;
$$ LANGUAGE plpgsql;

-- attention might not be exactly this (check - in the current DB it's 7024 or 7023)
-- So the number might not be OK (I added the subdivision grouping later.)
SELECT insert_fishing_subdivision('d.31', 7023);
SELECT insert_fishing_subdivision('d.30', 7023);
SELECT insert_fishing_subdivision('d.32', 7011);
SELECT insert_fishing_subdivision('d.27', 7024);
SELECT insert_fishing_subdivision('d.28', 7024);
SELECT insert_fishing_subdivision('d.29', 7024);
SELECT insert_fishing_subdivision('d.24', 7024);
SELECT insert_fishing_subdivision('d.25', 7024);
SELECT insert_fishing_subdivision('d.26', 7024);
SELECT insert_fishing_subdivision('c.22', 7024);
SELECT insert_fishing_subdivision('b.23', 7024);


INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_wkg_code, are_ismarine, are_name, geom_polygon, geom_line)
WITH select_division AS (
  SELECT geom FROM ref.tr_fishingarea_fia tff
  WHERE  tff.fia_code IN ('27.3.d.28.1')
)
SELECT 7025,
    7016 AS are_are_id,
    '27.3.d.28.1' AS are_code,
    'Subdivision' AS are_lev_code,
    'WGBAST' AS are_wkg_code,
    true AS is_marine,
    'Gulf of Riga' AS are_name,
    geom AS geom_polygon,
    NULL AS geom_line
    FROM select_division;--1

INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_wkg_code, are_ismarine, are_name, geom_polygon, geom_line)
WITH select_division AS (
  SELECT geom FROM ref.tr_fishingarea_fia tff
  WHERE  tff.fia_code IN ('27.3.d.28.2')
)
SELECT 7026,
    7016 AS are_are_id,
    '27.3.d.28.2' AS are_code,
    'Subdivision' AS are_lev_code,
    'WGBAST' AS are_wkg_code,
    true AS is_marine,
    'East of Gotland (Open Sea)' AS are_name,
    geom AS geom_polygon,
    NULL AS geom_line
    FROM select_division;--1   

-- fix names and country
UPDATE refbast.tr_area_are
  SET are_name='Baltic marine'
  WHERE are_id=2;
UPDATE refbast.tr_area_are
  SET are_name='Baltic inland'
  WHERE are_id=3;
UPDATE refbast.tr_area_are
  SET are_name='Whole stock Baltic'
  WHERE are_id=1;
UPDATE refbast.tr_area_are
  SET are_code='FN',are_name='Finland'
  WHERE are_id=4;
UPDATE refbast.tr_area_are
  SET are_code='SW',are_name='Sweden'
  WHERE are_id=5;
UPDATE refbast.tr_area_are
  SET are_code='EE',are_name='Estonia'
  WHERE are_id=6;
UPDATE refbast.tr_area_are
  SET are_code='LV',are_name='Latvia'
  WHERE are_id=7;
UPDATE refbast.tr_area_are
  SET are_code='LT',are_name='Lithuania'
  WHERE are_id=8;
UPDATE refbast.tr_area_are
  SET are_code='PL',are_name='Poland'
  WHERE are_id=9;
UPDATE refbast.tr_area_are
  SET are_code='DE',are_name='Germany'
  WHERE are_id=10;
UPDATE refbast.tr_area_are
  SET are_code='DK',are_name='Denmark'
  WHERE are_id=11;
UPDATE refbast.tr_area_are
  SET are_code='RU',are_name='Russia'
  WHERE are_id=12;



-- Fix error with division alongside adding an intermediate level 200 and 300
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7016;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7018;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7019;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7020;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7021;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7022;
UPDATE refbast.tr_area_are
  SET are_are_id=7011
  WHERE are_id=7023;
UPDATE refbast.tr_area_are
  SET are_are_id=7011
  WHERE are_id=7024;
UPDATE refbast.tr_area_are
  SET are_are_id=7023
  WHERE are_id=7012;
UPDATE refbast.tr_area_are
  SET are_are_id=7023
  WHERE are_id=7013;
UPDATE refbast.tr_area_are
  SET are_are_id=7011
  WHERE are_id=7014;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7015;
UPDATE refbast.tr_area_are
  SET are_are_id=7024
  WHERE are_id=7017;

------------------------------------- NAS -------------------------------------

-- Creating NAS Stock Unit

--CREATE SCHEMA refnas;

DROP TABLE IF EXISTS refnas.tr_area_are;
CREATE TABLE refnas.tr_area_are () INHERITS (ref.tr_area_are);
ALTER TABLE refnas.tr_area_are  OWNER TO diaspara_admin;
GRANT SELECT ON refnas.tr_area_are  TO diaspara_read;

ALTER TABLE refnas.tr_area_are
ALTER COLUMN are_wkg_code SET DEFAULT 'WGNAS';
ALTER TABLE refnas.tr_area_are ADD CONSTRAINT tr_area_area_pkey 
PRIMARY KEY (are_id);
ALTER TABLE refnas.tr_area_are
ADD CONSTRAINT fk_are_are_id FOREIGN KEY (are_are_id) 
  REFERENCES refnas.tr_area_are (are_id) ON DELETE CASCADE
  ON UPDATE CASCADE;
 ALTER TABLE refnas.tr_area_are
ADD CONSTRAINT uk_are_code UNIQUE (are_code);
ALTER TABLE refnas.tr_area_are
ADD CONSTRAINT fk_area_lev_code FOREIGN KEY (are_lev_code) REFERENCES
  ref.tr_habitatlevel_lev(lev_code) ON UPDATE CASCADE ON DELETE CASCADE;
 ALTER TABLE refnas.tr_area_are
ADD CONSTRAINT fk_area_wkg_code FOREIGN KEY (are_wkg_code) REFERENCES
  ref.tr_icworkinggroup_wkg(wkg_code) ON UPDATE CASCADE ON DELETE CASCADE;

DROP SEQUENCE IF EXISTS refnas.seq;
CREATE SEQUENCE refnas.seq;

INSERT INTO refnas.tr_area_are (are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
VALUES (1, 'Temporary Parent', 'Stock', true, NULL, NULL);

ALTER SEQUENCE refnas.seq RESTART WITH 2;

INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH selected_level AS (
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia
	WHERE "fia_level" = 'Division' AND "fia_area" = '27'
	AND "fia_division" NOT IN ('27.3.b, c','27.3.d'))
SELECT nextval('refnas.seq') AS are_id,
	1 AS are_are_id,
	'NEAC marine' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	true AS are_ismarine,
	geom AS _polygon,
	NULL AS geom_line
	FROM selected_level;
	
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refnas.seq') AS are_id,
	1 AS are_are_id,
	'NEAC inland' AS are_code,
	'Stock' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_nas
WHERE REGEXP_REPLACE(tableoid::regclass::text, '\.catchments$', '') IN (
	'h_barents', 'h_biscayiberian', 'h_celtic', 'h_iceland',
	'h_norwegian', 'h_nseanorth', 'h_nseasouth', 'h_nseauk',
	'h_svalbard'
); --1 SERVER OK



WITH unioned_polygons AS (
  SELECT (ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(geom_polygon))).geom)),0.0001,FALSE)) AS geom
  FROM refnas.tr_area_are
),
area_check AS (
  SELECT geom, ST_Area(geom) AS area
  FROM unioned_polygons
),
filtered_polygon AS (
  SELECT geom
  FROM area_check
  WHERE area > 1
)
UPDATE refnas.tr_area_are
SET 
  are_are_id = NULL,
  are_code = 'NEAC',
  are_lev_code = 'Stock',
  are_ismarine = NULL,
  geom_polygon = (SELECT ST_Multi(geom) FROM filtered_polygon),
  geom_line = NULL
WHERE are_id = 1; --1  SERVER OK


INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH selected_level AS (
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia
	WHERE "fia_level" = 'Division' AND "fia_area" = '21')
	--AND "fia_division" NOT IN ('27.3.b, c','27.3.d'))
SELECT nextval('refnas.seq') AS are_id,
	NULL AS are_are_id,
	'NAC marine' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	true AS are_ismarine,
	geom AS geom_polygon,
	NULL AS geom_line
	FROM selected_level; --1



------------------------------- Country level -------------------------------
DROP FUNCTION IF EXISTS insert_country_nas(country TEXT);
CREATE OR REPLACE FUNCTION insert_country_nas(country TEXT)
RETURNS VOID AS 
$$
BEGIN
  EXECUTE '
    INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH country_selection AS (
      SELECT ST_MULTI(ST_Union(tbc.shape)) AS geom, rc.cou_iso3code
      FROM tempo.catchments_nas tbc
      JOIN ref.tr_country_cou rc 
      ON ST_Intersects(tbc.shape, rc.geom)
      WHERE rc.cou_iso3code = ''' || country || '''
      GROUP BY rc.cou_iso3code
    )
    SELECT nextval(''refnas.seq'') AS are_id,
           3 AS are_are_id,
           ''' || country || ''' AS are_code,
           ''Country'' AS are_lev_code,
           false AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM country_selection;
  ';
END;
$$ LANGUAGE plpgsql;

ALTER SEQUENCE refnas.seq RESTART WITH 5;
SELECT insert_country_nas('FIN');
SELECT insert_country_nas('SWE');
SELECT insert_country_nas('NOR');
SELECT insert_country_nas('FRA');
SELECT insert_country_nas('SJM');
SELECT insert_country_nas('ESP');
SELECT insert_country_nas('DEU');
SELECT insert_country_nas('DNK');
SELECT insert_country_nas('RUS');
SELECT insert_country_nas('PRT');
SELECT insert_country_nas('NLD');
-- CEDRIC FAILS THERE (HAD TO ADD st_multi to function)
SELECT insert_country_nas('BEL');
SELECT insert_country_nas('IRL');
SELECT insert_country_nas('ISL');
SELECT insert_country_nas('GBR');
SELECT insert_country_nas('LUX');
SELECT insert_country_nas('CZE');



-- cedric inserting values from salmoglob
--SELECT max(are_id)+1 FROM refnas.tr_area_are
-- TODO : I'm not sure about the level, some of the countries are subcountries,
-- so will need to reference countries
-- I'm not sure this is an assessment unit, I think it's just used to store the conservation limits
ALTER SEQUENCE refnas.seq RESTART WITH 22;
DELETE FROM refnas.tr_area_are WHERE are_id >=22;
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH countrieswgnas AS (  
     SELECT DISTINCT DATABASE.area         
    FROM refsalmoglob.database WHERE area LIKE '%coun%')
SELECT nextval('refnas.seq') AS are_id,
       3 AS are_are_id,
       area,
       'Assessment_unit' AS are_lev_code,
        false AS are_ismarine,
        NULL AS geom_polygon,
		NULL AS geom_line
        FROM countrieswgnas; --17
        
-- this is fixed once both on the localhost and server.
-- I'm adding a level corresponding to 'Fishery'
/*
INSERT INTO ref.tr_habitatlevel_lev VALUES( 
  'Fisheries',
  'Specific fisheries area used by some working groups (WGNAS), e.g. FAR fishery,
GLD fishery, LB fishery, LB/SPM/swNF fishery, neNF fishery');
*/        
        
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH fisherieswgnas AS (  
     SELECT DISTINCT DATABASE.area         
    FROM refsalmoglob.database WHERE area LIKE '%fish%')
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       area,
       'Fisheries' AS are_lev_code,
        true AS are_ismarine,
        NULL AS geom_polygon,
		NULL AS geom_line
        FROM fisherieswgnas; --5
        
        

        
---------------------- Creating marine areas ----------------------
-- Post smolt 6
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['27.8.a','27.8.b','27.8.c','27.8.d']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 6' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 7
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['27.7.j','27.7.h','27.7.g','27.7.f','27.4.c','27.7.e','27.7.b','27.7.d','27.7.a']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 7' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 8
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['27.6.a','27.4.b','27.4.a']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 8' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 9
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = '27.14.b')
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 9' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 1
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.4.X','21.4.W','21.5.Y']))
SELECT nextval('refnas.seq') AS are_id,
       4 AS are_are_id,
       'postsmolt 1' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        ST_Multi(geom) AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 2
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.4.T','21.4.S','21.4.R']))
SELECT nextval('refnas.seq') AS are_id,
       4 AS are_are_id,
       'postsmolt 2' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        ST_Multi(geom) AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;



-- Post smolt 3
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.4.V','21.3.O','21.3.P']))
SELECT nextval('refnas.seq') AS are_id,
       4 AS are_are_id,
       'postsmolt 3' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        ST_Multi(geom) AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;

-- Post smolt 4
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.3.K','21.3.L']))
SELECT nextval('refnas.seq') AS are_id,
       4 AS are_are_id,
       'postsmolt 4' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        ST_Multi(geom) AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 5
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.2.G','21.2.H']))
SELECT nextval('refnas.seq') AS are_id,
       4 AS are_are_id,
       'postsmolt 5' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        ST_Multi(geom) AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- WGLD
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.0.A','21.1.A','21.1.B','21.0.B','21.1.C','21.1.D','21.1.E']))
UPDATE refnas.tr_area_are
SET geom_polygon = geom,
	are_are_id = 4
FROM geomunion
WHERE are_code = 'GLD fishery';


-- Fisheries A
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.3.K','21.3.L','21.3.O','21.2.G','21.1.F','21.2.H',
															'21.3.M','21.3.L','21.3.N']))
UPDATE refnas.tr_area_are
SET geom_polygon = geom,
	are_are_id = 4
FROM geomunion
WHERE are_code = 'LB/SPM/swNF fishery';

													
-- Fisheries B
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['27.2.a','27.5.b']))
UPDATE refnas.tr_area_are
SET geom_polygon = geom
FROM geomunion
WHERE are_code = 'FAR fishery';

					

INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH fisherieswgnas AS (  
     SELECT DISTINCT DATABASE.area         
    FROM refsalmoglob.database WHERE area NOT LIKE '%fish%' AND AREA NOT LIKE '%coun%')
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       area,
       'Assessment_unit' AS are_lev_code,
        false AS are_ismarine,
        NULL AS geom_polygon,
		NULL AS geom_line
        FROM fisherieswgnas; --28
       

DROP FUNCTION IF EXISTS update_geom_from_wgnas(p_are_code TEXT, p_are_are_id INT);
CREATE OR REPLACE FUNCTION update_geom_from_wgnas(p_are_code TEXT, p_are_are_id INT)
RETURNS void AS
$$
BEGIN
  UPDATE refnas.tr_area_are tgt
  SET 
    geom_polygon = src.geom,
    are_are_id = p_are_are_id
  FROM janis.wgnas_su src
  WHERE tgt.are_code = p_are_code
    AND src.su_ab = p_are_code
    AND tgt.are_lev_code = 'Assessment_unit';
END;
$$ LANGUAGE plpgsql;



SELECT update_geom_from_wgnas('NEC', NULL);
SELECT update_geom_from_wgnas('FR', 3);
SELECT update_geom_from_wgnas('FI', 3);
SELECT update_geom_from_wgnas('RU_AK', 3);
SELECT update_geom_from_wgnas('RU_KB', 3);
SELECT update_geom_from_wgnas('RU_KW', 3);
SELECT update_geom_from_wgnas('RU_RP', 3);
SELECT update_geom_from_wgnas('EW', 3);
SELECT update_geom_from_wgnas('IR', 3);
SELECT update_geom_from_wgnas('SC_EA', 3);
SELECT update_geom_from_wgnas('SC_WE', 3);
SELECT update_geom_from_wgnas('IC_NE', 3);
SELECT update_geom_from_wgnas('IC_SW', 3);
SELECT update_geom_from_wgnas('NI_FB', 3);
SELECT update_geom_from_wgnas('NI_FO', 3);
SELECT update_geom_from_wgnas('SW', 3);
SELECT update_geom_from_wgnas('NO_SE', 3);
SELECT update_geom_from_wgnas('NO_NO', 3);
SELECT update_geom_from_wgnas('NO_SW', 3);
SELECT update_geom_from_wgnas('NO_MI', 3);

SELECT update_geom_from_wgnas('NAC', NULL);
SELECT update_geom_from_wgnas('US', NULL);
SELECT update_geom_from_wgnas('QC', NULL);
SELECT update_geom_from_wgnas('NF', NULL);
SELECT update_geom_from_wgnas('SF', NULL);
SELECT update_geom_from_wgnas('GF', NULL);
SELECT update_geom_from_wgnas('LB', NULL);


------------------------------- River -------------------------------

DROP FUNCTION IF EXISTS insert_river_areas_nac(p_ass_unit TEXT, p_excluded_id bigint[]);
CREATE OR REPLACE FUNCTION insert_river_areas_nac(
  p_ass_unit TEXT,
  p_excluded_id bigint[]
) 
RETURNS VOID AS $$
BEGIN
  WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_nac trc 
    JOIN janis.wgnas_su jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE trc.ord_clas = 1
      AND jau.su_ab = p_ass_unit
  ),
  river_segments AS (
    SELECT *
    FROM tempo.riversegments_nac
    WHERE main_riv IN (SELECT main_riv FROM unit_riv)
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.main_bas, tcb.shape
    FROM tempo.catchments_nac tcb
    JOIN river_segments rs
      ON ST_Intersects(tcb.shape, rs.geom)
  ),
  merged AS (
    SELECT main_bas, ST_Union(shape) AS geom
    FROM catchments_with_riv
    GROUP BY main_bas
  ),
  base_area AS (
    SELECT are_id AS are_are_id
    FROM refnas.tr_area_are
    WHERE are_code = p_ass_unit
    LIMIT 1
  ),
  filtered AS (
    SELECT m.*, b.are_are_id
    FROM merged m
    CROSS JOIN base_area b
    LEFT JOIN refnas.tr_area_are a
      ON m.main_bas::TEXT = a.are_code
    WHERE a.are_code IS NULL
  )
  INSERT INTO refnas.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT
    nextval('refnas.seq'),
    are_are_id,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM filtered
  WHERE geom IS NOT NULL
  AND main_bas <> ALL(p_excluded_id);
END;
$$ LANGUAGE plpgsql;


SELECT insert_river_areas_nac('US',ARRAY[]::integer[]);
SELECT insert_river_areas_nac('SF',ARRAY[7120064150,7120036180,7120036200,7120036270,7120036420,7120036560,7120035860,7120036230]);
SELECT insert_river_areas_nac('NF',ARRAY[]::integer[]);
SELECT insert_river_areas_nac('GF',ARRAY[]::integer[]);
SELECT insert_river_areas_nac('LB',ARRAY[7120033390,7120033110,7120032940,7120032780,7120032730,7120032800,7120032690,7120032930]);
SELECT insert_river_areas_nac('QC',ARRAY[]::integer[]);



DROP FUNCTION IF EXISTS insert_river_areas_nas(p_ass_unit TEXT, p_excluded_id bigint[]);
CREATE OR REPLACE FUNCTION insert_river_areas_nas(
  p_ass_unit TEXT,
  p_excluded_id bigint[]
) 
RETURNS VOID AS $$
BEGIN
  WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_nas trc 
    JOIN janis.wgnas_su jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE trc.ord_clas = 1
      AND jau.su_ab = p_ass_unit
  ),
  river_segments AS (
    SELECT *
    FROM tempo.riversegments_nas
    WHERE main_riv IN (SELECT main_riv FROM unit_riv)
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.main_bas, tcb.shape
    FROM tempo.catchments_nas tcb
    JOIN river_segments rs
      ON ST_Intersects(tcb.shape, rs.geom)
  ),
  merged AS (
    SELECT main_bas, ST_Union(shape) AS geom
    FROM catchments_with_riv
    GROUP BY main_bas
  ),
  base_area AS (
    SELECT are_id AS are_are_id
    FROM refnas.tr_area_are
    WHERE are_code = p_ass_unit
    LIMIT 1
  ),
  filtered AS (
    SELECT m.*, b.are_are_id
    FROM merged m
    CROSS JOIN base_area b
    LEFT JOIN refnas.tr_area_are a
      ON m.main_bas::TEXT = a.are_code
    WHERE a.are_code IS NULL
  )
  INSERT INTO refnas.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT
    nextval('refnas.seq'),
    are_are_id,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM filtered
  WHERE geom IS NOT NULL
  AND main_bas <> ALL(p_excluded_id);
END;
$$ LANGUAGE plpgsql;



SELECT insert_river_areas_nas('FR',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('FI',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('RU_AK',ARRAY[2120043040,2120043080]::integer[]);
SELECT insert_river_areas_nas('RU_KB',ARRAY[2120039590,2120040190,2120040210,2120040230,2120040150,2120040160,2120040170,2120040180]::integer[]);
SELECT insert_river_areas_nas('RU_KW',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('RU_RP',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('EW',ARRAY[2120052940]::integer[]);
SELECT insert_river_areas_nas('NI_FB',ARRAY[2120055740]::integer[]);
SELECT insert_river_areas_nas('NI_FO',ARRAY[2120055750,2120055770,2120055300]::integer[]);
SELECT insert_river_areas_nas('IR',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('SC_EA',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('SC_WE',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('IC_SW',ARRAY[2120057770,2120058240,2120058560]::integer[]);
SELECT insert_river_areas_nas('IC_NE',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('SW',ARRAY[]::integer[]);
SELECT insert_river_areas_nas('NO_SE',ARRAY[2120035150,2120035190,2120035250,2120035630,2120036280,2120036340,2120034510,2120034520,2120034540]::integer[]);
SELECT insert_river_areas_nas('NO_NO',ARRAY[2120037610]::integer[]);
SELECT insert_river_areas_nas('NO_SW',ARRAY[2120035780]::integer[]);
SELECT insert_river_areas_nas('NO_MI',ARRAY[]::integer[]);



-------------------------------- River section level --------------------------------
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH river_level AS (
  SELECT are_id, geom_polygon
  FROM refnas.tr_area_are
  WHERE are_lev_code = 'River'
),
river_segments AS (
  SELECT DISTINCT ON (rs.hyriv_id)
    nextval('refnas.seq') AS are_id,
    rl.are_id AS are_are_id,
    rs.hyriv_id::TEXT AS are_code,
    'River_section' AS are_lev_code,
    false AS is_marine,
    NULL,
    rs.geom
  FROM tempo.riversegments_nas rs
  JOIN river_level rl
    ON ST_Intersects(rs.geom, rl.geom_polygon)
    WHERE rs.ord_clas = 1
)
SELECT DISTINCT ON (are_code) * FROM river_segments;--29339



INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH river_level AS (
  SELECT are_id, geom_polygon
  FROM refnas.tr_area_are
  WHERE are_lev_code = 'River'
),
river_segments AS (
  SELECT DISTINCT ON (rs.hyriv_id)
    nextval('refnas.seq') AS are_id,
    rl.are_id AS are_are_id,
    rs.hyriv_id::TEXT AS are_code,
    'River_section' AS are_lev_code,
    false AS is_marine,
    NULL,
    rs.geom
  FROM tempo.riversegments_nac rs
  JOIN river_level rl
    ON ST_Intersects(rs.geom, rl.geom_polygon)
    WHERE rs.ord_clas = 1
)
SELECT DISTINCT ON (are_code) * FROM river_segments;--14936



---------------------------- matching names to rivers ---------------------------- 

WITH outlets AS (
  SELECT DISTINCT trb.main_riv, rdg.rivername AS river_name
  FROM tempo.riversegments_nas trb
  JOIN janis.rivers_db_graeme rdg
    ON ST_DWithin(trb.geom, rdg.geom, 0.01)
  WHERE trb.ord_clas = 1
    AND trb.hyriv_id = trb.main_riv
),
outlets2 AS (
  SELECT DISTINCT trb.main_riv, rdg.rivername AS river_name
  FROM tempo.riversegments_nas trb
  JOIN janis.rivers_db_graeme rdg
    ON ST_DWithin(trb.geom, rdg.geom, 0.05)
  WHERE trb.ord_clas = 1
    AND trb.hyriv_id = trb.main_riv
    AND trb.main_riv NOT IN (SELECT main_riv FROM outlets)
),
all_outlets AS (
  SELECT * FROM outlets
  UNION
  SELECT * FROM outlets2
),
main_stretch AS (
  SELECT trb.*, ao.river_name
  FROM tempo.riversegments_nas trb
  JOIN all_outlets ao
    ON trb.main_riv = ao.main_riv
  WHERE trb.ord_clas = 1
),
river_with_counts AS (
  SELECT main_riv, COUNT(*) AS segment_count
  FROM main_stretch
  GROUP BY main_riv
  HAVING COUNT(*) > 1
),
final_stretch AS (
  SELECT ms.*
  FROM main_stretch ms
  JOIN river_with_counts rc
    ON ms.main_riv = rc.main_riv
)
UPDATE refnas.tr_area_are t
SET are_name = f.river_name
FROM final_stretch f
WHERE t.are_code = f.hyriv_id::TEXT;


------------------------------- Subarea -------------------------------


INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT 
  nextval('refnas.seq') AS are_id,
  2 AS are_are_id,
  fia_code AS are_code,
  'Subarea' AS are_lev_code,
  true AS are_ismarine,
  geom AS geom_polygon,
  NULL AS geom_line
FROM ref.tr_fishingarea_fia
WHERE fia_level = 'Subarea'
  AND fia_area = '27'; --12


 
 ------------------------------- Division -------------------------------


INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT 
  nextval('refnas.seq') AS are_id,
  subarea.are_id AS are_are_id,
  div.fia_code AS are_code,
  'Division' AS are_lev_code,
  true AS are_ismarine,
  div.geom AS geom_polygon,
  NULL AS geom_line
FROM ref.tr_fishingarea_fia div
JOIN refnas.tr_area_are subarea
  ON subarea.are_code = split_part(div.fia_code, '.', 1) || '.' || split_part(div.fia_code, '.', 2)
WHERE div.fia_level = 'Division'
  AND div.fia_area = '27'
  AND subarea.are_lev_code = 'Subarea'; --38
 
 
  
  
------------------------------------ WGEEL ------------------------------------
-- DELETE FROM refeel.tr_area_are;
--  ALTER TABLE dat.t_stock_sto
--  DROP CONSTRAINT fk_sto_are_code;
--  ALTER TABLE dat.t_stock_sto
--  ADD CONSTRAINT fk_sto_are_code FOREIGN KEY (sto_are_code)
--    REFERENCES "ref".tr_area_are (are_code) 
--    ON UPDATE CASCADE ON DELETE RESTRICT;
--   
--  ALTER TABLE dateel.t_stock_sto
--  DROP CONSTRAINT fk_sto_are_code;
--  ALTER TABLE dateel.t_stock_sto
--  ADD CONSTRAINT fk_sto_are_code FOREIGN KEY (sto_are_code)
--    REFERENCES "refeel".tr_area_are (are_code) 
--    ON UPDATE CASCADE ON DELETE RESTRICT;
  
  
  

DROP TABLE IF EXISTS refeel.tr_area_are;
CREATE TABLE refeel.tr_area_are () INHERITS (ref.tr_area_are);
ALTER TABLE refeel.tr_area_are OWNER TO diaspara_admin;


ALTER TABLE refeel.tr_area_are
	ALTER COLUMN are_wkg_code SET DEFAULT 'WGEEL';
ALTER TABLE refeel.tr_area_are ADD CONSTRAINT tr_area_area_pkey 
	PRIMARY KEY (are_id);
ALTER TABLE refeel.tr_area_are
ADD CONSTRAINT fk_are_are_id FOREIGN KEY (are_are_id)
	REFERENCES refeel.tr_area_are (are_id) ON DELETE CASCADE
	ON UPDATE CASCADE;
 ALTER TABLE refeel.tr_area_are
	ADD CONSTRAINT uk_are_code UNIQUE (are_code);
ALTER TABLE refeel.tr_area_are
	ADD CONSTRAINT fk_area_lev_code FOREIGN KEY (are_lev_code) REFERENCES
	ref.tr_habitatlevel_lev(lev_code) ON UPDATE CASCADE ON DELETE CASCADE;
 ALTER TABLE refeel.tr_area_are
	ADD CONSTRAINT fk_area_wkg_code FOREIGN KEY (are_wkg_code) REFERENCES
	ref.tr_icworkinggroup_wkg(wkg_code) ON UPDATE CASCADE ON DELETE CASCADE;



DROP SEQUENCE IF EXISTS refeel.seq;
CREATE SEQUENCE refeel.seq;

-------------------------------- Stock level ------------------------------------

INSERT INTO refeel.tr_area_are (are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
VALUES (1, 'Temporary Parent', 'Stock', true, NULL, NULL);

ALTER SEQUENCE refeel.seq RESTART WITH 2;

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	1 AS are_are_id,
	'Marine' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	true AS are_ismarine,
	ST_Union(geom) AS geom_polygon,
	NULL AS geom_line
	FROM ref.tr_fishingarea_fia 
	WHERE"fia_level"='Major' AND "fia_code" IN ('27','37');

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	1 AS are_are_id,
	'Inland' AS are_code,
	'Stock' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN ('h_adriatic',
  'h_baltic30to31', 'h_baltic22to26', 'h_baltic27to29_32','h_barents',
  'h_biscayiberian','h_blacksea','h_celtic','h_iceland','h_medcentral',
  'h_medeast','h_medwest','h_norwegian','h_nseanorth','h_nseasouth',
  'h_nseauk','h_southatlantic','h_southmedcentral','h_southmedeast',
  'h_southmedwest','h_svalbard'
);

WITH unioned_polygons AS (
  SELECT (ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(geom_polygon))).geom)),0.0001,FALSE)) AS geom
  FROM refeel.tr_area_are
),
area_check AS (
  SELECT geom, ST_Area(geom) AS area
  FROM unioned_polygons
),
filtered_polygon AS (
  SELECT geom
  FROM area_check
  WHERE area > 1
),
final_geom AS (
SELECT ST_Multi(ST_Union(geom)) AS geom
FROM filtered_polygon
)
UPDATE refeel.tr_area_are
SET 
  are_are_id = NULL,
  are_code = 'Europe',
  are_lev_code = 'Stock',
  are_ismarine = NULL,
  geom_polygon = (SELECT geom FROM final_geom),
  geom_line = NULL
WHERE are_id = 1;


-------------------------------- Marine --------------------------------
-------------------------------- Assessment unit level --------------------------------
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine Barents' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('27.14.a','27.5.a','27.2.b','27.2.a','27.1.b','27.1.a','27.14.b');

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine North Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('27.4.c','27.4.b','27.4.a','27.3.a');


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine English Channel' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('27.7.e','27.7.d');



INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine Baltic Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('27.3.d','27.3.b, c');


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine Atlantic' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('27.7.j','27.10.a','27.9.b','27.10.b','27.9.a','27.8.c','27.12.c',
						'27.12.a','27.6.a','27.7.b','34.1.2','34.1.1','27.7.k','27.6.b',
						'27.7.c','27.5.b','27.8.e','27.8.d','27.12.b','27.7.h','27.8.b',
						'27.7.g','27.7.f','27.8.a','27.8.a','27.7.a','34.1.3');


					
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine Mediterranean Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_division IN ('37.1.3','37.2.2','37.1.1','37.3.2','37.1.2','37.2.1')
OR fia_subdivision IN ('37.3.1.22','37.3.1.23','37.4.1.28');


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	2 AS are_are_id,
	'Marine Black Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	true AS are_ismarine,
	ST_Multi(ST_Union(geom)) AS geom_polygon,
	NULL AS geom_line
FROM ref.tr_fishingarea_fia tff 
WHERE fia_subdivision IN ('37.4.2.29','37.4.3.30');


--DELETE FROM refeel.tr_area_are 
--WHERE are_lev_code = 'Assessment_unit' AND are_ismarine = true;



 -------------------------------- Regional level --------------------------------
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('37.1.1.1','37.1.1.2','37.1.1.3','37.1.1.4','37.1.1.5','37.1.1.6',
	  						  '37.1.2.7','37.1.3.8','37.1.3.9','37.1.3.111','37.1.3.10','37.1.3.112')
	  AND are_id = 9
	 GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Western Mediterranean' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('37.1.3.12','37.2.2.13','37.2.2.14','37.2.2.15','37.2.2.16',
	  						  '37.2.2.19','37.2.2.20','37.2.2.212','37.2.2.213','37.2.2.211')
	  AND are_id = 9
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Central Mediterranean' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
      
   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  LEFT JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('37.3.1.22','37.3.1.23','37.3.2.24','37.3.2.25','37.3.2.26','37.3.2.27','37.4.1.28')
	  AND are_id = 9
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Eastern Mediterranean' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;


   
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('37.2.1.17')
	  AND are_id = 9
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Adriatic Sea' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;   
   
   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('37.4.2.29','37.4.3.30')
	  AND are_id = 10
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Black Sea' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;   


	
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Division'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_division IN ('27.9.b','27.9.a','34.1.2','34.1.1')
	  AND are_id = 8
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Southern Atlantic' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   

   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Division'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_division IN ('27.8.b','27.8.c','27.8.a','27.8.e','27.8.d')
	  AND are_id = 8
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Bay of Biscay' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
 
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Division'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_division IN ('27.7.j','27.7.h','27.7.g','27.6.a','27.7.b','27.7.k',
	  						'27.6.b','27.7.c','27.5.b','27.7.a','27.7.f')
	  AND are_id = 8
	 GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'British Isles' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
   
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ta.geom_polygon) AS geom, ta.are_id
      FROM refeel.tr_area_are ta
	  WHERE ta.are_lev_code = 'Assessment_unit'
	  AND ta.are_code = 'Marine North Sea'
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'North Sea' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ta.geom_polygon) AS geom, ta.are_id
      FROM refeel.tr_area_are ta
	  WHERE ta.are_lev_code = 'Assessment_unit'
	  AND ta.are_code = 'Marine English Channel'
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'English Channel' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
   
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ta.geom_polygon) AS geom, ta.are_id
      FROM refeel.tr_area_are ta
	  WHERE ta.are_lev_code = 'Assessment_unit'
	  AND ta.are_code = 'Marine Barents'
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Barents Sea' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('27.3.c.22','27.3.d.25','27.3.d.24','27.3.b.23','27.3.d.26')
	  AND are_id = 7
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Baltic South' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;

   
   
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('27.3.d.28','27.3.d.27','27.3.d.32','27.3.d.29')
	  AND are_id = 7
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Baltic North' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;
   
 
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH region_selection AS (
      SELECT DISTINCT ON (geom) ST_Multi(ST_Union(fi.geom)) AS geom, ta.are_id
      FROM ref.tr_fishingarea_fia fi
	  JOIN refeel.tr_area_are ta
	  ON ST_Intersects(ta.geom_polygon,fi.geom)
	  WHERE fi.fia_level = 'Subdivision'
	  AND ta.are_lev_code = 'Assessment_unit'
	  AND fia_subdivision IN ('27.3.d.30','27.3.d.31')
	  AND are_id = 7
	  GROUP BY ta.are_id
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           'Golf of Bothnia' AS are_code,
           'Regional' AS are_lev_code,
           true AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM region_selection;



--UPDATE ref.tr_fishingarea_fia fi SET geom = t3.geom FROM tempo."37.1.1.1" t3 WHERE fi.fia_code = '37.1.1.1';
--UPDATE ref.tr_fishingarea_fia fi SET geom = t3.geom FROM tempo."37.1.1.3" t3 WHERE fi.fia_code = '37.1.1.3';
--UPDATE ref.tr_fishingarea_fia fi SET geom = t3.geom FROM tempo."27.9.a" t3 WHERE fi.fia_code = '27.9.a';

   
-------------------------------- Division level --------------------------------
  
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH intersections AS (
	    SELECT
	        fi.fia_division,
	        ST_Multi(fi.geom) AS geom,
	        ta.are_id AS are_id,
	        ST_Area(ST_Intersection(ta.geom_polygon, fi.geom)) AS intersection_area
	    FROM ref.tr_fishingarea_fia fi
	    JOIN refeel.tr_area_are ta
	        ON ST_Intersects(ta.geom_polygon, fi.geom)
	    WHERE fi.fia_level = 'Division'
	      AND ta.are_lev_code = 'Regional'
	      AND fi.fia_division NOT IN ('21.6.H', '21.3.M', '21.1.F')
	      AND fi.fia_area NOT IN ('37')
	),
	ranked AS (
	    SELECT DISTINCT ON (fia_division)
	        nextval('refeel.seq') AS are_id,
	        are_id AS are_are_id,
	        fia_division AS are_code,
	        'Division' AS are_lev_code,
	        true AS are_ismarine,
	        geom AS geom_polygon,
	        NULL AS geom_line
	    FROM intersections
	    ORDER BY fia_division, intersection_area DESC
	)
	SELECT *
	FROM ranked;
   
   
-------------------------------- Subivision level --------------------------------

   
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH intersections AS (
    SELECT
        fi.fia_subdivision,
        ST_Multi(fi.geom) AS geom,
        ta.are_id AS are_id,
        ST_Area(ST_Intersection(ta.geom_polygon, fi.geom)) AS intersection_area
    FROM ref.tr_fishingarea_fia fi
    JOIN refeel.tr_area_are ta
        ON ST_Intersects(ta.geom_polygon, fi.geom)
    WHERE fi.fia_level = 'Subdivision'
      AND ta.are_lev_code = 'Regional'
      AND fi.fia_subdivision NOT IN ('27.10.a.1', '27.12.a.1', '27.12.a.3')
),
ranked AS (
    SELECT DISTINCT ON (fia_subdivision)
        nextval('refeel.seq') AS are_id,
        are_id AS are_are_id,
        fia_subdivision AS are_code,
        'Subdivision' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
        NULL AS geom_line
    FROM intersections
    ORDER BY fia_subdivision, intersection_area DESC
)
SELECT *
FROM ranked;



-------------------------------- Inland --------------------------------

------------------------------- Country level -------------------------------

    INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH country_selection AS (
      SELECT rc.geom AS geom, rc.cou_code
      FROM ref.tr_country_cou rc 
	  JOIN refwgeel.tr_country_cou cw
	  ON rc.cou_code = cw.cou_code
	  GROUP BY rc.cou_code
    )
    SELECT nextval('refeel.seq') AS are_id,
           3 AS are_are_id,
           cou_code AS are_code,
           'Country' AS are_lev_code,
           NULL AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM country_selection;


------------------------------- EMU -------------------------------
   
--   INSERT INTO ref.tr_habitatlevel_lev VALUES( 
--  'EMU',
--  'Administrative unit for eel, the hierarchical next level is country.'
--  )
   
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
    WITH emu_selection AS (
      SELECT ST_Multi(re.geom) AS geom, re.emu_cou_code, re.emu_nameshort, ta.are_id
      FROM refwgeel.tr_emu_emu re 
	  JOIN refeel.tr_area_are ta
	  ON ta.are_code = re.emu_cou_code
	  WHERE emu_nameshort NOT ILIKE '%total'
    )
    SELECT nextval('refeel.seq') AS are_id,
           are_id AS are_are_id,
           emu_nameshort AS are_code,
           'EMU' AS are_lev_code,
           NULL AS are_ismarine,
           geom AS geom_polygon,
		   NULL AS geom_line
    FROM emu_selection;
   

   
-------------------------------- Assessment unit level --------------------------------
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland Barents' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN ('h_barents',
  'h_iceland','h_norwegian','h_svalbard');

 
 INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland Baltic Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN (
  'h_baltic30to31', 'h_baltic22to26', 'h_baltic27to29_32');
 

 
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland North Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN ('h_nseanorth','h_nseasouth',
  'h_nseauk');
 
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland Atlantic' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN (
  'h_biscayiberian','h_celtic','h_southatlantic'
 );

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland Meditarranean Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN (
  'h_adriatic','h_medcentral','h_medeast','h_medwest','h_southmedcentral',
  'h_southmedeast','h_southmedwest'
 );

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
	3 AS are_are_id,
	'Inland Black Sea' AS are_code,
	'Assessment_unit' AS are_lev_code,
	false AS are_ismarine,
	ST_Union(shape) AS geom_polygon,
	NULL AS geom_line
FROM tempo.catchments_eel
WHERE regexp_replace(tableoid::regclass::text, '\.catchments$', '') IN (
  'h_blacksea'
 );

-------------------------------- Regional level --------------------------------
--WITH outlets AS (
--	SELECT ce.main_bas, taa.are_code
--	FROM tempo.catchments_eel ce 
--	JOIN refeel.tr_area_are taa 
--	  ON ST_Intersects(ce.shape,taa.geom_polygon)
--	WHERE taa.are_lev_code = 'Regional'
--),
--catchments_grouped AS (
--	SELECT ce.shape, o.are_code
--	FROM tempo.catchments_eel ce
--	JOIN outlets o
--	  ON o.main_bas = ce.main_bas
--),
--merged_shapes AS (
--	SELECT
--	  are_code,
--	  ST_Multi(ST_Union(shape)) AS geom
--	FROM catchments_grouped
--	GROUP BY are_code
--)
--SELECT *
--FROM merged_shapes;




--CREATE OR REPLACE FUNCTION generate_polygons_for_regions()
--RETURNS void AS
--$$
--DECLARE
--    reg RECORD;
--    tbl_name TEXT;
--BEGIN
--    CREATE TABLE IF NOT EXISTS tempo.resul (
--        are_code TEXT,
--        geom GEOMETRY(MultiPolygon, 4326)
--    );
--
--    DROP TABLE IF EXISTS excluded_points_global;
--
--    CREATE TEMP TABLE excluded_points_global (
--        downstream_point GEOMETRY(Point, 4326)
--    ) ON COMMIT PRESERVE ROWS;
--
--    FOR reg IN
--        SELECT DISTINCT are_code
--        FROM refeel.tr_area_are
--        WHERE are_lev_code = 'Regional'
--    LOOP
--        tbl_name := format('tempo.refeel_region_%s', lower(replace(reg.are_code, ' ', '_')));
--
--        EXECUTE format('DROP TABLE IF EXISTS %I;', tbl_name);
--
--        EXECUTE format(
--            'CREATE TABLE %I AS
--             WITH all_sources AS (
--                 SELECT * FROM tempo.riveratlas_mds
--                 UNION
--                 SELECT * FROM tempo.riveratlas_mds_sm
--             ),
--             filtered_points AS (
--                 SELECT dp.*
--                 FROM all_sources dp
--                 JOIN refeel.tr_area_are taa
--                   ON ST_DWithin(dp.downstream_point, taa.geom_polygon, 0.04)
--                 WHERE taa.are_lev_code = ''Regional''
--                   AND taa.are_code = %L
--             ),
--             extended_points AS (
--                 SELECT dp.*
--                 FROM all_sources dp
--                 JOIN refeel.tr_area_are taa
--                   ON ST_DWithin(dp.downstream_point, ST_Transform(taa.geom_polygon, 4326), 0.1)
--                 WHERE taa.are_lev_code = ''Regional''
--                   AND taa.are_code = %L
--             ),
--             all_points AS (
--                 SELECT * FROM filtered_points
--                 UNION
--                 SELECT * FROM extended_points
--             ),
--             points_to_use AS (
--                 SELECT ap.*
--                 FROM all_points ap
--                 LEFT JOIN excluded_points_global epg
--                   ON ST_Equals(ap.downstream_point, epg.downstream_point)
--                 WHERE epg.downstream_point IS NULL
--             )
--             SELECT * FROM points_to_use;',
--            tbl_name, reg.are_code, reg.are_code
--        );
--
--        EXECUTE format($f$
--            WITH all_rivers AS (
--                SELECT * FROM tempo.hydro_riversegments_europe
--                UNION
--                SELECT * FROM tempo.hydro_riversegments
--            ),
--            select_rivers AS (
--                SELECT DISTINCT ON (hre.geom) hre.*
--                FROM all_rivers hre
--                JOIN %I rf ON hre.main_riv = rf.main_riv
--            ),
--            select_catch AS (
--                SELECT ST_Buffer(ST_Union(ST_MakeValid(ce.shape)), 0) AS geom
--                FROM tempo.catchments_eel ce 
--                JOIN select_rivers sr ON ST_Intersects(sr.geom, ce.shape)
--            )
--            INSERT INTO tempo.resul (are_code, geom)
--            SELECT %L, geom FROM select_catch;
--        $f$, tbl_name, reg.are_code);
--
--        EXECUTE format($f$
--            INSERT INTO excluded_points_global (downstream_point)
--            SELECT downstream_point FROM %I;
--        $f$, tbl_name);
--
--        RAISE NOTICE 'Done : %', reg.are_code;
--    END LOOP;
--END;
--$$ LANGUAGE plpgsql;
--
--
--
--
--SELECT generate_polygons_for_regions();
--SELECT * FROM tempo.resul;
--DROP TABLE tempo.resul;

-- Barents Sea
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_catch AS (
		SELECT shape AS geom
		FROM h_iceland.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_norwegian.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_barents.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_svalbard.catchments
	)
	SELECT nextval('refeel.seq') AS are_id,
	       285 AS are_are_id,
	       'Barents inland' AS are_code,
	       'Regional'     AS are_lev_code,
	       false          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_catch;

-- Baltic North
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	SELECT nextval('refeel.seq') AS are_id,
	       286 AS are_are_id,
	       'Golf of Bothnia inland' AS are_code,
	       'Regional'     AS are_lev_code,
	       false          AS are_ismarine,
	       ST_Union(shape) AS geom_polygon,
	       NULL          AS geom_line
	FROM h_baltic30to31.catchments;

-- Baltic Central
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	SELECT nextval('refeel.seq') AS are_id,
		       286 AS are_are_id,
		       'Baltic North inland' AS are_code,
		       'Regional'     AS are_lev_code,
		       false          AS are_ismarine,
		       ST_Union(shape) AS geom_polygon,
		       NULL          AS geom_line
	FROM h_baltic27to29_32.catchments;

-- Baltic South
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	SELECT nextval('refeel.seq') AS are_id,
			       286 AS are_are_id,
			       'Baltic South inland' AS are_code,
			       'Regional'     AS are_lev_code,
			       false          AS are_ismarine,
			       ST_Union(shape) AS geom_polygon,
			       NULL          AS geom_line
	FROM h_baltic22to26.catchments;


-- Western Med
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_catch AS (
		SELECT shape AS geom
		FROM h_medwest.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_southmedwest.catchments
	)
	SELECT nextval('refeel.seq') AS are_id,
			       289 AS are_are_id,
			       'Western Mediterranean inland' AS are_code,
			       'Regional'     AS are_lev_code,
			       false          AS are_ismarine,
			       ST_Union(geom) AS geom_polygon,
			       NULL          AS geom_line
	FROM select_catch;

-- Central Med
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_catch AS (
		SELECT shape AS geom
		FROM h_medcentral.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_southmedcentral.catchments
	)
	SELECT nextval('refeel.seq') AS are_id,
				       289 AS are_are_id,
				       'Central Mediterranean inland' AS are_code,
				       'Regional'     AS are_lev_code,
				       false          AS are_ismarine,
				       ST_Union(geom) AS geom_polygon,
				       NULL          AS geom_line
	FROM select_catch;

-- East Med
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_catch AS (
		SELECT shape AS geom
		FROM h_medeast.catchments
		UNION ALL
		SELECT shape AS geom
		FROM h_southmedeast.catchments
	)
	SELECT nextval('refeel.seq') AS are_id,
				       289 AS are_are_id,
				       'Eastern Mediterranean inland' AS are_code,
				       'Regional'     AS are_lev_code,
				       false          AS are_ismarine,
				       ST_Union(geom) AS geom_polygon,
				       NULL          AS geom_line
	FROM select_catch;


-- Adriatic
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	SELECT nextval('refeel.seq') AS are_id,
				       289 AS are_are_id,
				       'Adriatic inland' AS are_code,
				       'Regional'     AS are_lev_code,
				       false          AS are_ismarine,
				       ST_Union(shape) AS geom_polygon,
				       NULL          AS geom_line
	FROM h_adriatic.catchments;

-- Black Sea
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	SELECT nextval('refeel.seq') AS are_id,
				       290 AS are_are_id,
				       'Black Sea inland' AS are_code,
				       'Regional'     AS are_lev_code,
				       false          AS are_ismarine,
				       ST_Union(shape) AS geom_polygon,
				       NULL          AS geom_line
	FROM h_blacksea.catchments;




-- Step 1 : 

DROP TABLE IF EXISTS tempo.regions_nsea;
CREATE TABLE tempo.regions_nsea AS(
	WITH region_points AS (
	        SELECT DISTINCT dp.*
	        FROM tempo.riveratlas_mds AS dp
	        JOIN refeel.tr_area_are taa 
	        ON ST_DWithin(
	            dp.downstream_point,
	            taa.geom_polygon,
	            0.04
	        )
	        WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'North Sea'
	        AND are_ismarine = true
	    )
	    SELECT * FROM region_points
	    WHERE downstream_point NOT IN (
	        SELECT existing.downstream_point
	        FROM tempo.ices_areas_26_22, tempo.ices_ecoregions_barent AS existing)
);--2166
        
DROP TABLE IF EXISTS tempo.regions_bisles;
CREATE TABLE tempo.regions_bisles AS(
	WITH region_points AS (
	        SELECT DISTINCT dp.*
	        FROM tempo.riveratlas_mds AS dp
	        JOIN refeel.tr_area_are taa 
	        ON ST_DWithin(
	            dp.downstream_point,
	            taa.geom_polygon,
	            0.04
	        )
	        WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'British Isles'
	        AND are_ismarine = true
	    )
	    SELECT * FROM region_points
	    WHERE downstream_point NOT IN (
	        SELECT existing.downstream_point
	        FROM tempo.regions_nsea AS existing)
);--1967

DROP TABLE IF EXISTS tempo.regions_echannel;
CREATE TABLE tempo.regions_echannel AS(
	WITH region_points AS (
	        SELECT DISTINCT dp.*
	        FROM tempo.riveratlas_mds AS dp
	        JOIN refeel.tr_area_are taa 
	        ON ST_DWithin(
	            dp.downstream_point,
	            taa.geom_polygon,
	            0.04
	        )
	        WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'English Channel'
	        AND are_ismarine = true
	    )
	    SELECT * FROM region_points
	    WHERE downstream_point NOT IN (
	        SELECT existing.downstream_point
	        FROM tempo.regions_nsea, tempo.regions_bisles AS existing)
);--386


DROP TABLE IF EXISTS tempo.regions_bbiscay;
CREATE TABLE tempo.regions_bbiscay AS(
	WITH region_points AS (
	        SELECT DISTINCT dp.*
	        FROM tempo.riveratlas_mds AS dp
	        JOIN refeel.tr_area_are taa 
	        ON ST_DWithin(
	            dp.downstream_point,
	            taa.geom_polygon,
	            0.04
	        )
	        WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'Bay of Biscay'
	        AND are_ismarine = true
	    )
	    SELECT * FROM region_points
	    WHERE downstream_point NOT IN (
	        SELECT existing.downstream_point
	        FROM tempo.regions_echannel, tempo.regions_bisles AS existing)
);--375


 CREATE INDEX idx_tr_area_are_geomp
  ON refeel.tr_area_are
  USING GIST (geom_polygon);
 


DROP TABLE IF EXISTS tempo.regions_sat;
CREATE TABLE tempo.regions_sat AS
WITH all_points AS (
    SELECT * FROM tempo.riveratlas_mds
    UNION ALL
    SELECT * FROM tempo.riveratlas_mds_sm
),
filtered_areas AS (
    SELECT geom_polygon
    FROM refeel.tr_area_are
    WHERE are_lev_code = 'Regional'
      AND are_code = 'Southern Atlantic'
      AND are_ismarine = true
),
existing AS (
    SELECT downstream_point FROM tempo.regions_bbiscay
    UNION
    SELECT downstream_point FROM tempo.ices_ecoregions_south_medwest
    UNION
    SELECT downstream_point FROM tempo.ices_ecoregions_med_west
)
SELECT DISTINCT ap.*
FROM all_points ap
JOIN filtered_areas fa
  ON fa.geom_polygon && ST_Expand(ap.downstream_point, 0.04)
 AND ST_DWithin(ap.downstream_point, fa.geom_polygon, 0.04)  
WHERE NOT EXISTS (
    SELECT 1
    FROM existing e
    WHERE ap.downstream_point && e.downstream_point 
      AND ST_Equals(ap.downstream_point, e.downstream_point)
);--658


-- Step 2 : redo buffer

WITH filtered_points AS (
    SELECT DISTINCT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN refeel.tr_area_are taa
    ON ST_DWithin(
        dp.downstream_point,
        taa.geom_polygon,
        0.1
    )
    WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'North Sea'
	        AND are_ismarine = true
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_areas_26_22
    UNION ALL
    SELECT downstream_point
    FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bisles
    UNION ALL
    SELECT downstream_point FROM tempo.regions_nsea
    UNION ALL
    SELECT downstream_point FROM tempo.regions_echannel
   ),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.regions_nsea
SELECT mp.*
FROM missing_points AS mp;--24


WITH filtered_points AS (
    SELECT DISTINCT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN refeel.tr_area_are taa
    ON ST_DWithin(
        dp.downstream_point,
        taa.geom_polygon,
        0.1
    )
    WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'British Isles'
	        AND are_ismarine = true
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_barent
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bisles
    UNION ALL
    SELECT downstream_point FROM tempo.regions_nsea
    UNION ALL
    SELECT downstream_point FROM tempo.regions_echannel
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bbiscay
   ),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.regions_bisles
SELECT mp.*
FROM missing_points AS mp;--28


WITH filtered_points AS (
    SELECT DISTINCT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN refeel.tr_area_are taa
    ON ST_DWithin(
        dp.downstream_point,
        taa.geom_polygon,
        0.1
    )
    WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'English Channel'
	        AND are_ismarine = true
),
excluded_points AS (
    SELECT downstream_point FROM tempo.regions_bisles
    UNION ALL
    SELECT downstream_point FROM tempo.regions_nsea
    UNION ALL
    SELECT downstream_point FROM tempo.regions_echannel
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bbiscay
   ),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.regions_echannel
SELECT mp.*
FROM missing_points AS mp;--0


WITH filtered_points AS (
    SELECT DISTINCT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN refeel.tr_area_are taa
    ON ST_DWithin(
        dp.downstream_point,
        taa.geom_polygon,
        0.1
    )
    WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'Bay of Biscay'
	        AND are_ismarine = true
),
excluded_points AS (
    SELECT downstream_point FROM tempo.regions_bisles
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bbiscay
    UNION ALL
    SELECT downstream_point FROM tempo.regions_echannel
    UNION ALL 
    SELECT downstream_point FROM tempo.regions_sat
   ),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.regions_bbiscay
SELECT mp.*
FROM missing_points AS mp;--0


WITH filtered_points AS (
    SELECT DISTINCT dp.*
	FROM tempo.riveratlas_mds AS dp
	JOIN refeel.tr_area_are taa
    ON ST_DWithin(
        dp.downstream_point,
        taa.geom_polygon,
        0.1
    )
    WHERE taa.are_lev_code = 'Regional'
	        AND taa.are_code = 'Southern Atlantic'
	        AND are_ismarine = true
),
excluded_points AS (
    SELECT downstream_point
    FROM tempo.ices_ecoregions_med_west
    UNION ALL
    SELECT downstream_point
    FROM tempo.ices_ecoregions_south_med_west
    UNION ALL
    SELECT downstream_point FROM tempo.regions_sat
    UNION ALL
    SELECT downstream_point FROM tempo.regions_bbiscay
   ),
missing_points AS (
    SELECT fp.*
    FROM filtered_points AS fp
    LEFT JOIN excluded_points AS ep
    ON ST_Equals(fp.downstream_point, ep.downstream_point)
    WHERE ep.downstream_point IS NULL
)
INSERT INTO tempo.regions_sat
SELECT mp.*
FROM missing_points AS mp;--0

-- Step 3 : Copy all riversegments & catchments with the corresponding main_riv

DROP TABLE IF EXISTS tempo.catch_nsea;
CREATE TABLE tempo.catch_nsea AS (
WITH excluded_catch AS (
	SELECT shape FROM h_baltic22to26.catchments
	UNION ALL
	SELECT shape FROM h_barents.catchments
	)
    SELECT DISTINCT ON (hce.shape) hce.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.regions_nsea rn
    ON hre.main_riv = rn.main_riv
   JOIN tempo.hydro_small_catchments_europe AS hce
   ON ST_Intersects(hce.shape,hre.geom)
   WHERE shape NOT IN (
	        SELECT shape FROM excluded_catch)
);--6157


DROP TABLE IF EXISTS tempo.catch_echannel;
CREATE TABLE tempo.catch_echannel AS (
	WITH excluded_catch AS (
	SELECT shape FROM tempo.catch_nsea
	)
    SELECT DISTINCT ON (hce.shape) hce.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.regions_echannel rn
    ON hre.main_riv = rn.main_riv
   JOIN tempo.hydro_small_catchments_europe AS hce
   ON ST_Intersects(hce.shape,hre.geom)
   WHERE shape NOT IN (
	        SELECT shape FROM excluded_catch)
);--1018


DROP TABLE IF EXISTS tempo.catch_bisles;
CREATE TABLE tempo.catch_bisles AS (
	WITH excluded_catch AS (
		SELECT shape FROM tempo.catch_nsea
		UNION ALL
		SELECT shape FROM tempo.catch_echannel
	)
    SELECT DISTINCT ON (hce.shape) hce.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.regions_bisles rn
    ON hre.main_riv = rn.main_riv
   JOIN tempo.hydro_small_catchments_europe AS hce
   ON ST_Intersects(hce.shape,hre.geom)
   WHERE shape NOT IN (
	        SELECT shape FROM excluded_catch)
);--1232


DROP TABLE IF EXISTS tempo.catch_bbiscay;
CREATE TABLE tempo.catch_bbiscay AS (
	WITH excluded_catch AS (
		SELECT shape FROM tempo.catch_bisles
		UNION ALL
		SELECT shape FROM tempo.catch_echannel
	)
    SELECT DISTINCT ON (hce.shape) hce.*
    FROM tempo.hydro_riversegments_europe AS hre
    JOIN tempo.regions_bbiscay rn
    ON hre.main_riv = rn.main_riv
   JOIN tempo.hydro_small_catchments_europe AS hce
   ON ST_Intersects(hce.shape,hre.geom)
   WHERE shape NOT IN (
	        SELECT shape FROM excluded_catch)
);--2193

DROP TABLE IF EXISTS tempo.catch_sat;
CREATE TABLE tempo.catch_sat AS (
	WITH all_riv AS (
	SELECT *
	FROM tempo.hydro_riversegments_europe
	UNION ALL
	SELECT *
	FROM tempo.hydro_riversegments
	),
	all_catch AS (
	SELECT *
	FROM tempo.hydro_small_catchments
	UNION ALL
	SELECT *
	FROM tempo.hydro_small_catchments_europe
	),
	excluded_catch AS (
	SELECT shape FROM tempo.catch_bbiscay
	UNION ALL
	SELECT shape FROM h_medwest.catchments
	UNION ALL
	SELECT shape FROM h_southmedwest.catchments
	)
    SELECT DISTINCT ON (hce.shape) hce.*
    FROM all_riv AS hre
    JOIN tempo.regions_sat rn
    ON hre.main_riv = rn.main_riv
   JOIN all_catch AS hce
   ON ST_Intersects(hce.shape,hre.geom)
);--5571


-- Step 4 : Retrieving missing endoheric bassins

DROP TABLE IF EXISTS tempo.oneendo_nsea;
CREATE TABLE tempo.oneendo_nsea AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM tempo.catch_nsea AS ha);--475
CREATE INDEX idx_tempo_oneendo_nsea ON tempo.oneendo_nsea USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_nsea
    ON ba.shape && oneendo_nsea.geom
    AND ST_Intersects(ba.shape, oneendo_nsea.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape
    FROM tempo.catch_bisles
    UNION ALL
    SELECT shape
    FROM tempo.catch_nsea
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_nsea
SELECT *
FROM filtered_basin;--127


DROP TABLE IF EXISTS tempo.oneendo_echannel;
CREATE TABLE tempo.oneendo_echannel AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM tempo.catch_echannel AS ha);--495
CREATE INDEX idx_tempo_oneendo_echannel ON tempo.oneendo_echannel USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_echannel
    ON ba.shape && oneendo_echannel.geom
    AND ST_Intersects(ba.shape, oneendo_echannel.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape 
    FROM tempo.catch_bbiscay
    UNION ALL
    SELECT shape
    FROM tempo.catch_bisles
    UNION ALL
    SELECT shape
    FROM tempo.catch_nsea
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_echannel
SELECT *
FROM filtered_basin;--19


DROP TABLE IF EXISTS tempo.oneendo_bbiscay;
CREATE TABLE tempo.oneendo_bbiscay AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM tempo.catch_bbiscay AS ha);--41
CREATE INDEX idx_tempo_oneendo_bbiscay ON tempo.oneendo_bbiscay USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_bbiscay
    ON ba.shape && oneendo_bbiscay.geom
    AND ST_Intersects(ba.shape, oneendo_bbiscay.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape 
    FROM tempo.catch_bbiscay
    UNION ALL
    SELECT shape
    FROM tempo.catch_sat
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_bbiscay
SELECT *
FROM filtered_basin;--33


DROP TABLE IF EXISTS tempo.oneendo_sat;
CREATE TABLE tempo.oneendo_sat AS (
	SELECT  ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(ha.shape))).geom)),0.04,FALSE) geom
	FROM tempo.catch_sat AS ha);--41
CREATE INDEX idx_tempo_oneendo_sat ON tempo.oneendo_sat USING GIST(geom);
	
WITH endo_basins AS (	
    SELECT ba.*
    FROM basinatlas.basinatlas_v10_lev12 AS ba
    JOIN tempo.oneendo_sat
    ON ba.shape && oneendo_sat.geom
    AND ST_Intersects(ba.shape, oneendo_sat.geom)
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_bbiscay
    UNION ALL
    SELECT shape
    FROM tempo.catch_sat
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape
    FROM h_southmedwest.catchments
),
filtered_basin AS (
    SELECT eb.*
    FROM endo_basins eb
    LEFT JOIN excluded_basins exb
    ON eb.shape && exb.shape
    AND ST_Equals(eb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_sat
SELECT *
FROM filtered_basin;--81


--Step 5 : Retrieving last islands and basins along the coast

WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN refeel.tr_area_are taa
	ON ST_Intersects(c.shape, taa.geom_polygon)
	WHERE taa.are_code = 'North Sea'
),
excluded_basins AS (
    SELECT shape 
    FROM h_baltic22to26.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic27to29_32.catchments
    UNION ALL
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape 
    FROM h_norwegian.catchments
    UNION ALL
    SELECT shape 
    FROM h_blacksea.catchments
    UNION ALL
    SELECT shape 
    FROM h_adriatic.catchments
    UNION ALL
    SELECT shape 
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape 
    FROM h_baltic30to31.catchments
    UNION ALL
    SELECT shape
    FROM tempo.catch_bisles
    UNION ALL
    SELECT shape
    FROM tempo.catch_nsea
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_nsea
SELECT *
FROM filtered_basin;--21


WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN refeel.tr_area_are taa
	ON ST_Intersects(c.shape, taa.geom_polygon)
	WHERE taa.are_code = 'British Isles'
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape
    FROM tempo.catch_bisles
    UNION ALL
    SELECT shape
    FROM tempo.catch_nsea
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
INSERT INTO tempo.catch_bisles
SELECT *
FROM filtered_basin;--58

WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN refeel.tr_area_are taa
	ON ST_Intersects(c.shape, taa.geom_polygon)
	WHERE taa.are_code = 'English Channel'
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape
    FROM tempo.catch_bisles
    UNION ALL
    SELECT shape
    FROM tempo.catch_nsea
    UNION ALL
    SELECT shape
    FROM tempo.catch_bbiscay
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
INSERT INTO tempo.catch_echannel
SELECT *
FROM filtered_basin;--5


WITH last_basin AS (
	SELECT c.*
	FROM tempo.hydro_small_catchments_europe AS c
	JOIN refeel.tr_area_are taa
	ON ST_Intersects(c.shape, taa.geom_polygon)
	WHERE taa.are_code = 'Bay of Biscay'
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_echannel
    UNION ALL
    SELECT shape
    FROM tempo.catch_bbiscay
    UNION ALL
    SELECT shape
    FROM tempo.catch_sat
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
INSERT INTO tempo.catch_bbiscay
SELECT *
FROM filtered_basin;--1

WITH all_catch AS (
	SELECT *
	FROM tempo.hydro_small_catchments
	UNION ALL
	SELECT *
	FROM tempo.hydro_small_catchments_europe
	),
last_basin AS (
	SELECT c.*
	FROM all_catch AS c
	JOIN refeel.tr_area_are taa
	ON ST_Intersects(c.shape, taa.geom_polygon)
	WHERE taa.are_code = 'South Atlantic'
),
excluded_basins AS (
    SELECT shape 
    FROM tempo.catch_sat
    UNION ALL
    SELECT shape
    FROM h_medwest.catchments
    UNION ALL
    SELECT shape
    FROM tempo.catch_bbiscay
    UNION ALL
    SELECT shape
    FROM h_southmedwest.catchments
),
filtered_basin AS (
    SELECT lb.*
    FROM last_basin lb
    LEFT JOIN excluded_basins exb
    ON lb.shape && exb.shape
    AND ST_Equals(lb.shape, exb.shape)
    WHERE exb.shape IS NULL
)
INSERT INTO tempo.catch_sat
SELECT *
FROM filtered_basin;


-- Insertion into tr_area_are

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
       287 AS are_are_id,
       'North Sea inland'   AS are_code,
       'Regional'     AS are_lev_code,
       false          AS are_ismarine,
       ST_Union(shape) AS geom_polygon,
       NULL          AS geom_line
FROM tempo.catch_nsea;

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
       287 AS are_are_id,
       'English Channel inland'   AS are_code,
       'Regional'     AS are_lev_code,
       false          AS are_ismarine,
       ST_Union(shape) AS geom_polygon,
       NULL          AS geom_line
FROM tempo.catch_echannel;


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
       288 AS are_are_id,
       'British Isles inland'   AS are_code,
       'Regional'     AS are_lev_code,
       false          AS are_ismarine,
       ST_Union(shape) AS geom_polygon,
       NULL          AS geom_line
FROM tempo.catch_bisles;


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
       288 AS are_are_id,
       'Bay of Biscay inland'   AS are_code,
       'Regional'     AS are_lev_code,
       false          AS are_ismarine,
       ST_Union(shape) AS geom_polygon,
       NULL          AS geom_line
FROM tempo.catch_bbiscay;

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT nextval('refeel.seq') AS are_id,
       288 AS are_are_id,
       'South Atlantic inland'   AS are_code,
       'Regional'     AS are_lev_code,
       false          AS are_ismarine,
       ST_Union(shape) AS geom_polygon,
       NULL          AS geom_line
FROM tempo.catch_sat;
SELECT version()

----------------- Complex ----------------- /!\ Faire tourner
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH complex_selection AS (
  SELECT
    ST_Union(zif_geom) AS geom,
    trim(
      regexp_replace(zif_libelle, '^[^.]*\. *([^,]*).*$', '\1')
    ) AS complexe_nom
  FROM tempo.tr_zoneifremer_zif tzz
  WHERE tzz.zif_loc_level = '144'
  GROUP BY
    trim(
      regexp_replace(zif_libelle, '^[^.]*\. *([^,]*).*$', '\1')
    )
),
complex_with_parent AS (
  SELECT DISTINCT ON (cs.complexe_nom)
         cs.geom,
         cs.complexe_nom,
         ta.are_id AS are_id
  FROM complex_selection cs
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(cs.geom, ta.geom_polygon)
  WHERE ta.are_code <> '37.1.3.112'
  AND ta.are_lev_code = 'Subdivision'
)
SELECT nextval('refeel.seq') AS are_id,
       are_id AS are_are_id,
       complexe_nom   AS are_code,
       'Complex'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line
FROM complex_with_parent;

-------------------- Greece --------------------
-- West
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080046470,2080011590,2080011580,2080011560,2080011550,2080011520,2080011410,
						2080046430,2080011360,2080011380,2080011390,2080011400)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Western Greece'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Peloponnese West
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080011000,2080046420,2080010990,2080010940,2080010930,2080010920,2080010910,
						2080010900,2080010830)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Western Peloponnese'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;
				
				
-- Peloponnese East
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (2090010640,2090010630,2090010620,2090010610,2090010680,2090010660,2090010670,
						2090010600,2090010540,2090010580,2090010590,2090010570,2100010530)
	UNION ALL
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev10
	WHERE hybas_id IN (2100010500)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Eastern Peloponnese'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-- Gulf of Corinth
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (2090011210)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Gulf of Corinth'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Crete
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070045170)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Crete'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-- Central Greece
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08 
	WHERE hybas_id IN (2080010210,2080010050,2080046260,2080046220)
	UNION ALL
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (2090010310)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Central Greece'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- South Aegean Islands
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070045590,2070045870)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'South Aegean Islands'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Central Macedonia
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070009960,2070009740)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Central Macedonia'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- North Aegean Islands
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070046070)
	UNION ALL
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (2090046170,2090046200,2090046210)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'North Aegean Islands'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Eastern Macedonia
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070009650,2070009490,2070009560,2070009570,2070009580,2070009590,2070009600,2070009610)
	UNION ALL 
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080009640)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Eastern Macedonia and Thrace'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-------------------- Albania --------------------
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080011660,2080011650,2080011740)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       298 AS are_are_id,
	       'Southern Albania'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080011900,2080011950)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       298 AS are_are_id,
	       'Northern Albania'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;



-------------------- Turkey --------------------
-- Northwestern Med Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev06
	WHERE hybas_id IN (2060002620,2060002830,2060002840,2060003240,2060003250,2060009230)
	UNION ALL
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (2090046190,2090046150)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Northwestern Med Turkey'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Southwestern Med Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev06
	WHERE hybas_id IN (2060002130,2060002080)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Southwestern Med Turkey'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-- Southeastern Med Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070001730,2070001370,2070001360,2070001320,2070001450,2070001460)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       297 AS are_are_id,
	       'Southeastern Med Turkey'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

-- Eastern Black Sea Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev08
	WHERE hybas_id IN (2080004290)
	UNION ALL
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev06
	WHERE hybas_id IN (2060004140,2060003560)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       299 AS are_are_id,
	       'Eastern Black Sea Turkey'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-- Western Black Sea Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (2070009000)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       299 AS are_are_id,
	       'Western Black Sea Turkey'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-------------------- Tunisia --------------------
-- Northern Tunisia
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (1090031430,1090031390,1090031380,1090031300,1090031230,1090031170,1090031220)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Northern Tunisia'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


-- Northeastern Tunisia
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev09
	WHERE hybas_id IN (1090031470,1090031500,1090031510,1090031520,1090031530,1090031560,1090086570,1090031570,1090031580,1090031610,
						1090031620,1090031640,1090031670)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Northeastern Tunisia'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
	WITH select_complex AS (
	SELECT shape AS geom FROM basinatlas.basinatlas_v10_lev07
	WHERE hybas_id IN (1070032160,1070031860,1070031790,1070031740,1070031810)
	)
	SELECT nextval('refeel.seq') AS are_id,
	       296 AS are_are_id,
	       'Southeastern Tunisia'   AS are_code,
	       'Complex'     AS are_lev_code,
	       FALSE          AS are_ismarine,
	       ST_Union(geom) AS geom_polygon,
	       NULL          AS geom_line
	FROM select_complex;

----------------- Lagoons -----------------
--INSERT INTO ref.tr_habitatlevel_lev VALUES( 
--  'Lagoons',
--  'Shallow body of water seperated from a larger body of water by a narrow landform'
--  );
--DROP TABLE tempo.gfcm_lagoon;
CREATE TABLE tempo.gfcm_lagoon (country varchar, site_code varchar, site_name varchar, lat DOUBLE PRECISION,
								long DOUBLE PRECISION, habitat_type varchar);
COPY tempo.gfcm_lagoon FROM 'D:\workspace\data\Habitat_data_GFCM_xDIASPARA_15072025.csv' csv header;

ALTER TABLE tempo.gfcm_lagoon
	ADD geom geometry;
UPDATE tempo.gfcm_lagoon
	SET geom = ST_SetSRID(ST_MakePoint(long,lat),4326);

SELECT DISTINCT ON (site_code) la.geom, gl.* FROM lakeatlas.lakeatlas_v10_pol la
JOIN tempo.gfcm_lagoon gl
ON ST_DWithin(gl.geom,la.geom,0.1)
WHERE gl.habitat_type = 'LGN';--177

SELECT * FROM tempo.gfcm_lagoon gl WHERE gl.habitat_type = 'LGN';--223

-- are_code seq for lagoons
DROP SEQUENCE IF EXISTS lgr_seq;
CREATE SEQUENCE lgr_seq
  START 1
  INCREMENT 1
  MINVALUE 1
  OWNED BY NONE;
 
CREATE OR REPLACE FUNCTION gen_lgr_code(country_code TEXT)
RETURNS text AS $$
BEGIN
  RETURN country_code || LPAD(nextval('lgr_seq')::text, 3, '0');
END;
$$ LANGUAGE plpgsql;



-- France
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH lagunes_selection AS (
	SELECT lag_polygone AS geom, lag_nom
	FROM tempo.fr_lagoons tl 
)--,
--lag_with_comp AS (
  SELECT DISTINCT ON (ls.lag_nom)
         ls.geom,
         ls.lag_nom,
         ta.are_id AS are_id
  FROM lagunes_selection ls
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(ls.geom, ta.geom_polygon)
  WHERE ta.are_lev_code = 'Complex'
)
SELECT --nextval('refeel.seq') AS are_id,
	   NULL AS are_id,
       are_id AS are_are_id,
       gen_lgr_code('LFR')   AS are_code,
       'Lagoons'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line,
       lag_nom		 AS are_name
FROM lag_with_comp;

-- Greece
DROP SEQUENCE IF EXISTS lgr_seq;
CREATE SEQUENCE lgr_seq
  START 1
  INCREMENT 1
  MINVALUE 1
  OWNED BY NONE;


INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH lagunes_selection AS (
	--SELECT ST_Multi(ST_Union(ggw.geom)) AS geom, gl.site_name FROM tempo.gr_lagoons ggw 
	SELECT DISTINCT ON (ggw.geom) ggw.geom, gl.site_name FROM tempo.gr_lagoons ggw 
	LEFT JOIN tempo.gfcm_lagoon gl ON ST_DWithin(ggw.geom,gl.geom,0.0001)
	AND gl.habitat_type = 'LGN'
	WHERE ggw."LULC" = 521
	--GROUP BY gl.site_name
),
lag_with_comp AS (
  SELECT
         ls.geom,
         ls.site_name,
         ta.are_id AS are_id
  FROM lagunes_selection ls
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(ls.geom, ta.geom_polygon)
  WHERE ta.are_lev_code = 'Complex'
)
SELECT --nextval('refeel.seq') AS are_id,
	   NULL AS are_id,
       are_id AS are_are_id,
       gen_lgr_code('LGR')   AS are_code,
       'Lagoons'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line,
       site_name 	 AS are_name
FROM lag_with_comp;


-- Albania
DROP SEQUENCE IF EXISTS lgr_seq;
CREATE SEQUENCE lgr_seq
  START 1
  INCREMENT 1
  MINVALUE 1
  OWNED BY NONE;
 
 
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH lagunes_selection AS (
	SELECT DISTINCT ON (ggw.geom) ggw.geom, gl.site_name FROM tempo.al_lagoons ggw 
	LEFT JOIN tempo.gfcm_lagoon gl ON ST_DWithin(ggw.geom,gl.geom,0.001)
	AND gl.habitat_type = 'LGN'
	WHERE ggw."LULC" = 521 
),
lag_with_comp AS (
  SELECT
         ls.geom,
         ls.site_name,
         ta.are_id AS are_id
  FROM lagunes_selection ls
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(ls.geom, ta.geom_polygon)
  WHERE ta.are_lev_code = 'Complex'
)
SELECT --nextval('refeel.seq') AS are_id,
	   NULL AS are_id,
       are_id AS are_are_id,
       site_name   AS are_code,
       'Lagoons'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line
FROM lag_with_comp;


-- Turkey
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH lagunes_selection AS (
	SELECT DISTINCT ON (ggw.geom) ggw.geom, gl.site_name FROM tempo.tr_lagoons ggw 
	LEFT JOIN tempo.gfcm_lagoon gl ON ST_DWithin(ggw.geom,gl.geom,0.001)
	AND gl.habitat_type = 'LGN'
	WHERE ggw."LULC" = 521 
),
lag_with_comp AS (
  SELECT
         ls.geom,
         ls.site_name,
         ta.are_id AS are_id
  FROM lagunes_selection ls
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(ls.geom, ta.geom_polygon)
  WHERE ta.are_lev_code = 'Complex'
)
SELECT --nextval('refeel.seq') AS are_id,
	   NULL AS are_id,
       are_id AS are_are_id,
       site_name   AS are_code,
       'Lagoons'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line
FROM lag_with_comp;


-- Tunisia
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH lagunes_selection AS (
	SELECT DISTINCT ON (ggw.geom) ggw.geom, gl.site_name FROM tempo.tn_lagoons ggw 
	LEFT JOIN tempo.gfcm_lagoon gl ON ST_DWithin(ggw.geom,gl.geom,0.001)
	AND gl.habitat_type = 'LGN'
	WHERE ggw."LULC" = 521 
),
lag_with_comp AS (
  SELECT
         ls.geom,
         ls.site_name,
         ta.are_id AS are_id
  FROM lagunes_selection ls
  JOIN refeel.tr_area_are ta
    ON ST_Intersects(ls.geom, ta.geom_polygon)
  WHERE ta.are_lev_code = 'Complex'
)
SELECT --nextval('refeel.seq') AS are_id,
	   NULL AS are_id,
       are_id AS are_are_id,
       site_name   AS are_code,
       'Lagoons'     AS are_lev_code,
       NULL          AS are_ismarine,
       geom          AS geom_polygon,
       NULL          AS geom_line
FROM lag_with_comp;

----------------- River -----------------

INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_riv AS (
    SELECT DISTINCT re.main_riv, taa.are_id
    FROM tempo.riversegments_eel re
    JOIN refeel.tr_area_are taa
      ON ST_Intersects(re.geom, taa.geom_polygon)
    WHERE re.ord_clas = 1
      AND taa.are_lev_code = 'Assessment_unit'
      AND taa.are_ismarine = false
),
all_segments AS (
    SELECT re.main_riv, ur.are_id, re.geom
    FROM tempo.riversegments_eel re
    JOIN unit_riv ur ON ur.main_riv = re.main_riv
),
catchments_with_riv AS (
    SELECT DISTINCT tce.hybas_id, tce.main_bas, re.main_riv, re.are_id, tce.shape
    FROM tempo.catchments_eel tce
    JOIN all_segments re ON ST_Intersects(tce.shape, re.geom)
),
deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, are_id, shape
    FROM catchments_with_riv
),
merged AS (
    SELECT main_bas, MIN(are_id) AS are_id, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_bas
)
SELECT 
    nextval('refeel.seq'),
	are_id,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
FROM merged
WHERE geom IS NOT NULL;

--------------------------- River_section ---------------------------
INSERT INTO refeel.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH river_level AS (
  SELECT are_id, geom_polygon
  FROM refeel.tr_area_are
  WHERE are_lev_code = 'River'
),
river_segments AS (
  SELECT DISTINCT ON (rs.hyriv_id)
    nextval('refeel.seq') AS are_id,
    rl.are_id AS are_are_id,
    rs.hyriv_id::TEXT AS are_code,
    'river_section' AS are_lev_code,
    false AS is_marine,
    NULL,
    rs.geom
  FROM tempo.riversegments_eel rs
  JOIN river_level rl
    ON ST_Intersects(rs.geom, rl.geom_polygon)
    WHERE rs.ord_clas = 1
)
SELECT DISTINCT ON (are_code) * FROM river_segments;


--------------------------- Creating referential to match rivers to basin ---------------------------  

-------- WGBAST
DROP TABLE IF EXISTS refbast.tr_rivernames_riv;
CREATE TABLE refbast.tr_rivernames_riv(
	CONSTRAINT uk_basin_river UNIQUE(riv_are_code,riv_rivername),
	CONSTRAINT fk_riv_wkg_code FOREIGN KEY (riv_wkg_code) REFERENCES
	ref.tr_icworkinggroup_wkg(wkg_code) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_riv_are_code FOREIGN KEY (riv_are_code) REFERENCES
    refbast.tr_area_are(are_code) ON UPDATE CASCADE ON DELETE CASCADE)
    INHERITS(ref.tr_rivernames_riv);
   
ALTER TABLE refbast.tr_rivernames_riv OWNER TO diaspara_admin;
ALTER TABLE refbast.tr_rivernames_riv
	ALTER COLUMN riv_wkg_code SET DEFAULT 'WGBAST';



DROP SEQUENCE IF EXISTS refbast.seq;
CREATE SEQUENCE refbast.seq;
ALTER SEQUENCE refbast.seq OWNER TO diaspara_admin;


WITH line_union AS (
  SELECT "name" AS riv_rivername, ST_Union(geom) AS geom
  FROM janis.wgbast_combined
  GROUP BY "name"
),
select_basin AS (
  SELECT are_code, geom_polygon
  FROM refbast.tr_area_are
  WHERE are_lev_code = 'River'
),
length_calc AS (
  SELECT lu.riv_rivername, sb.are_code AS riv_are_code,
         ST_Length(ST_Intersection(lu.geom, sb.geom_polygon)) AS intersection_length
  FROM line_union lu
  JOIN select_basin sb	
    ON ST_Intersects(lu.geom, sb.geom_polygon)
),
length_select AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY riv_rivername ORDER BY intersection_length DESC) AS rn
  FROM length_calc
)
INSERT INTO refbast.tr_rivernames_riv (
  riv_id,
  riv_are_code,
  riv_rivername
)
SELECT
  nextval('refbast.seq') AS riv_id,
  riv_are_code,
  riv_rivername
FROM length_select
WHERE rn = 1;--119


BEGIN;
UPDATE refbast.tr_area_are as taa SET are_name = trr.riv_rivername
FROM refbast.tr_rivernames_riv as trr WHERE trr.riv_are_code = taa.are_code 
AND taa.are_name IS NULL; --61
COMMIT;

BEGIN;
WITH sec AS (
SELECT * FROM refbast.tr_area_are 
WHERE are_lev_code = 'River_section'),
 riv AS (
 SELECT * FROM refbast.tr_area_are 
WHERE are_lev_code = 'River'
),
sec_rename AS (
SELECT sec.are_id, sec.are_code, sec.are_name 
FROM riv JOIN sec ON riv.are_name = sec.are_name)

UPDATE refbast.tr_area_are SET are_name = tr_area_are.are_name || ' River_section ' || tr_area_are.are_code
FROM sec_rename
WHERE tr_area_are.are_id = sec_rename.are_id
AND are_lev_code ='River_section' ; --2382
COMMIT;

-- I have created landings_wgbast_river_names to create the correspondance with landings table

WITH cor as(
SELECT * FROM refbast.tr_area_are
JOIN refbast.landings_wbast_river_names ON are_name = riv_are_name
WHERE are_lev_code = 'River')
UPDATE refbast.landings_wbast_river_names SET riv_are_code=cor.are_code
FROM cor WHERE cor.are_name = landings_wbast_river_names.riv_are_name; --35

SELECT * FROM refbast.tr_area_are 
WHERE are_lev_code = 'River'
AND are_name LIKE 'man'

-- Save with subrivers
WITH cor as(
SELECT * FROM refbast.tr_area_are
JOIN refbast.landings_wbast_river_names ON are_name = riv_are_name
WHERE are_lev_code = 'River_section')
     parent AS (
 SELECT are.* FROM tr_area_are are JOIN cor as(
SELECT * FROM refbast.tr_area_are
JOIN refbast.landings_wbast_river_names ON are_name = riv_are_name
WHERE are_lev_code = 'River')
UPDATE refbast.landings_wbast_river_names SET riv_are_code=cor.are_code
FROM cor WHERE cor.are_name = landings_wbast_river_names.riv_are_name; --35   
     
     
     )
UPDATE refbast.landings_wbast_river_names SET riv_are_code=cor.are_code
FROM cor WHERE cor.are_name = landings_wbast_river_names.riv_are_name; --35


-- After having set the correspondance between wgbast landings names and are_code
-- I put back some of the names
-- some are not the same, I don't update then
-- there is a trick with NORMALIZE otherwise coming from windows it didn't work...
WITH update_me AS(
SELECT DISTINCT ON (are_id) are_id, are_code, riv_are_name FROM refbast.tr_area_are a JOIN refbast.landings_wbast_river_names lw
ON a.are_code= lw.riv_are_code 
WHERE a.are_name IS NULL)
UPDATE refbast.tr_area_are SET are_name = NORMALIZE(riv_are_name)
FROM update_me WHERE update_me.are_id = tr_area_are.are_id; --11



-------- WGNAS
DROP TABLE IF EXISTS refnas.tr_rivernames_riv;
CREATE TABLE refnas.tr_rivernames_riv(
	CONSTRAINT uk_basin_river UNIQUE(riv_are_code,riv_rivername),
	CONSTRAINT fk_riv_wkg_code FOREIGN KEY (riv_wkg_code) REFERENCES
	ref.tr_icworkinggroup_wkg(wkg_code) ON UPDATE CASCADE ON DELETE CASCADE,
	CONSTRAINT fk_riv_are_code FOREIGN KEY (riv_are_code) REFERENCES
    refnas.tr_area_are(are_code) ON UPDATE CASCADE ON DELETE CASCADE)
    INHERITS(ref.tr_rivernames_riv);
   
ALTER TABLE refnas.tr_rivernames_riv OWNER TO diaspara_admin;
ALTER TABLE refnas.tr_rivernames_riv
	ALTER COLUMN riv_wkg_code SET DEFAULT 'WGNAS';



DROP SEQUENCE IF EXISTS refnas.seq;
CREATE SEQUENCE refnas.seq;
ALTER SEQUENCE refnas.seq OWNER TO diaspara_admin;


INSERT INTO refnas.tr_rivernames_riv (
	riv_id,
	riv_are_code,
	riv_rivername
)
SELECT DISTINCT ON (riv.rivername)
	nextval('refnas.seq') AS riv_id,
	narea.are_code AS riv_are_code,
	riv.rivername AS riv_rivername
FROM janis.rivers_db_graeme riv
JOIN refnas.tr_area_are narea
	ON ST_Intersects(riv.geom, narea.geom_polygon)
WHERE narea.are_lev_code = 'River';--1946




-------------------------------- Country level --------------------------------


--------------------------------- fix Assessment_units --------------------------

--SELECT  max(are_id) FROM refbast.tr_area_are


ALTER SEQUENCE refbast.seq RESTART WITH  7027;


SELECT * FROM refbast.tr_area_are WHERE are_lev_code  ='Assessment_unit';

CREATE TABLE refbast.area_temp( LIKE refbast.tr_area_are);

-- 3 Bothnian Sea (are_id 15)
DELETE FROM refbast.area_temp WHERE are_id = 15;

INSERT INTO refbast.area_temp (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
  SELECT trc.geom AS geom, trc.main_riv
  FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
  WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 3
  --AND main_riv NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code IN ('River', 'River_section'))
),
retrieve_rivers AS(
  SELECT DISTINCT trc.geom
  FROM tempo.riversegments_baltic trc, unit_selection us
  WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
/*
existing AS (SELECT geom_polygon FROM refbast.tr_area_are 
WHERE are_id IN (13,14,16,17,18)), 
catchment_baltic_remaining AS (
   SELECT tbc.* FROM tempo.catchments_baltic tbc,
   existing e
   WHERE NOT st_intersects(e.geom_polygon, tbc.shape)
)
*/

-- exclude Bothnian Bay 3
retrieve_catchments AS (
  SELECT DISTINCT ST_Union(tbc.shape) AS geom
  FROM tempo.catchments_baltic tbc, 
  retrieve_rivers rr--,
  WHERE ST_Intersects(tbc.shape,rr.geom) 
)

SELECT 15 AS are_id,
    3 AS are_are_id,
    '3 Bothnian Sea' AS are_code,
    'Assessment_unit' AS are_lev_code,
    --are_wkg_code,
    false AS is_marine,
    ST_Union(geom) AS geom_polygon,
    NULL AS geom_line
    FROM retrieve_catchments;


WITH subset AS (
SELECT st_union(shape) AS shape FROM tempo.catchments_baltic WHERE main_bas IN (2120031160, 2120030870, 2120030910, 2120031130))
UPDATE refbast.area_temp SET geom_polygon=ST_Union(geom_polygon, shape)
FROM subset WHERE are_id=15;

WITH subset AS (
SELECT * FROM tempo.catchments_baltic WHERE main_bas IN (2120031160))
UPDATE refbast.area_temp SET geom_polygon=ST_Union(geom_polygon, shape)
FROM subset WHERE are_id=15;

UPDATE refbast.tr_area_are SET geom_polygon = area_temp.geom_polygon 
FROM refbast.area_temp
WHERE area_temp.are_id = 15
AND tr_area_are.are_id = 15;



--TODO ADD island + 3 catchments

-- 6 Gulf of Finland

DELETE FROM refbast.area_temp WHERE are_id = 18;
INSERT INTO refbast.area_temp (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
  SELECT trc.geom AS geom, trc.main_riv
  FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
  WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 6
  --AND main_riv NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code IN ('River', 'River_section'))
),
retrieve_rivers AS(
  SELECT DISTINCT trc.geom
  FROM tempo.riversegments_baltic trc, unit_selection us
  WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
/*
existing AS (SELECT geom_polygon FROM refbast.tr_area_are 
WHERE are_id IN (13,14,16,17,18)), 
catchment_baltic_remaining AS (
   SELECT tbc.* FROM tempo.catchments_baltic tbc,
   existing e
   WHERE NOT st_intersects(e.geom_polygon, tbc.shape)
)
*/
retrieve_catchments AS (
  SELECT DISTINCT ST_Union(tbc.shape) AS geom
  FROM tempo.catchments_baltic tbc, 
  retrieve_rivers rr--,
  WHERE ST_Intersects(tbc.shape,rr.geom) 
)

SELECT 18 AS are_id,
    3 AS are_are_id,
    '6 Gulf of Finland' AS are_code,
    'Assessment_unit' AS are_lev_code,
    --are_wkg_code,
    false AS is_marine,
    ST_Union(geom) AS geom_polygon,
    NULL AS geom_line
    FROM retrieve_catchments;


SELECT tbc.* FROM tempo.catchments_baltic tbc,
janis.bast_assessment_units jau
WHERE ST_Intersects(tbc.shape, jau.geom) 
 AND jau."Ass_unit" = 6 


UPDATE refbast.tr_area_are SET geom_polygon = area_temp.geom_polygon 
FROM refbast.area_temp
WHERE area_temp.are_id = 18
AND tr_area_are.are_id = 18;

WITH subset AS (
SELECT st_union(shape) AS shape FROM tempo.catchments_baltic WHERE main_bas IN (2120028930))
UPDATE refbast.tr_area_are SET geom_polygon= st_multi(shape)
FROM subset WHERE are_id=439;
INSERT INTO refbast.area_temp SELECT * FROM refbast.tr_area_are WHERE are_code = '2120028930'
DELETE FROM refbast.area_temp
SELECT * FROM refbast.tr_area_are WHERE are_code = '2120028930'
--5 Eastern Main Basin (17)

DELETE FROM refbast.area_temp WHERE are_id = 17;
INSERT INTO refbast.area_temp (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH unit_selection AS (
  SELECT trc.geom AS geom, trc.main_riv
  FROM tempo.riversegments_baltic trc, janis.bast_assessment_units jau
  WHERE ST_Intersects(trc.geom, jau.geom) AND trc.ord_clas = 1 AND jau."Ass_unit" = 5
  --AND main_riv NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code IN ('River', 'River_section'))
),
retrieve_rivers AS(
  SELECT DISTINCT trc.geom
  FROM tempo.riversegments_baltic trc, unit_selection us
  WHERE trc.main_riv IN (SELECT main_riv FROM unit_selection)
),
/*
existing AS (SELECT geom_polygon FROM refbast.tr_area_are 
WHERE are_id IN (13,14,16,17,18)), 
catchment_baltic_remaining AS (
   SELECT tbc.* FROM tempo.catchments_baltic tbc,
   existing e
   WHERE NOT st_intersects(e.geom_polygon, tbc.shape)
)
*/
retrieve_catchments AS (
  SELECT DISTINCT ST_Union(tbc.shape) AS geom
  FROM tempo.catchments_baltic tbc, 
  retrieve_rivers rr--,
  WHERE ST_Intersects(tbc.shape,rr.geom) 
)

SELECT 17 AS are_id,
    3 AS are_are_id,
    '6 Gulf of Finland' AS are_code,
    'Assessment_unit' AS are_lev_code,
    --are_wkg_code,
    false AS is_marine,
    ST_Union(geom) AS geom_polygon,
    NULL AS geom_line
    FROM retrieve_catchments;


UPDATE refbast.tr_area_are SET geom_polygon = area_temp.geom_polygon 
FROM refbast.area_temp
WHERE area_temp.are_id = 17
AND tr_area_are.are_id = 17;

 
-- Update rivers 15 (3)

 WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_baltic trc
    JOIN janis.bast_assessment_units jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE (trc.ord_clas = 1
      AND jau."Ass_unit" = 3) 
  ),
  all_segments AS (
    SELECT trc.main_riv, trc.geom
    FROM tempo.riversegments_baltic trc
    JOIN unit_riv ur ON ur.main_riv = trc.main_riv
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.hybas_id, tcb.main_bas, trc.main_riv, tcb.shape
    FROM tempo.catchments_baltic tcb
    JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
  ),
  deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, shape
    FROM catchments_with_riv
  ),
  merged AS (
    SELECT main_riv, MIN(main_bas) AS main_bas, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_riv
  )
INSERT INTO refbast.tr_area_are (
  are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT 
    nextval('refbast.seq'),
    15,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM merged
  WHERE geom IS NOT NULL
  AND main_bas NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code='River');
 
 CREATE TABLE temp_missing_basins (are_id integer PRIMARY KEY ,geom public.geometry(multipolygon, 4326) NULL) ;
 DELETE FROM temp_missing_basins;
 INSERT INTO temp_missing_basins SELECT 7101 are_id, st_multi(st_union(shape)) FROM tempo.catchments_baltic WHERE main_bas IN (2120031160);
INSERT INTO temp_missing_basins SELECT 94 are_id, st_multi(st_union(shape)) FROM tempo.catchments_baltic WHERE main_bas IN (2120030480);


UPDATE refbast.tr_area_are SET geom_polygon=geom
FROM temp_missing_basins 
WHERE tr_area_are.are_id=7101
AND temp_missing_basins.are_id = 7101;

UPDATE refbast.tr_area_are SET geom_polygon=geom
FROM temp_missing_basins 
WHERE tr_area_are.are_id=94
AND temp_missing_basins.are_id = 94;
  
-- FIx rivers AU 6  
  WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_baltic trc
    JOIN janis.bast_assessment_units jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE (trc.ord_clas = 1
      AND jau."Ass_unit" = 6)
    
  ),
  all_segments AS (
    SELECT trc.main_riv, trc.geom
    FROM tempo.riversegments_baltic trc
    JOIN unit_riv ur ON ur.main_riv = trc.main_riv
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.hybas_id, tcb.main_bas, trc.main_riv, tcb.shape
    FROM tempo.catchments_baltic tcb
    JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
  ),
  deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, shape
    FROM catchments_with_riv
  ),
  merged AS (
    SELECT main_riv, MIN(main_bas) AS main_bas, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_riv
  )
  INSERT INTO refbast.tr_area_are (
  are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT 
    nextval('refbast.seq'),
    18,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM merged
  WHERE geom IS NOT NULL
  AND main_bas NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code='River'); --10

  
  -- FIx rivers AU 4 - 5 Eastern Main Basin 
  WITH unit_riv AS (
    SELECT DISTINCT trc.main_riv
    FROM tempo.riversegments_baltic trc
    JOIN janis.bast_assessment_units jau
      ON ST_Intersects(trc.geom, jau.geom)
    WHERE (trc.ord_clas = 1
      AND jau."Ass_unit" = 5)
    
  ),
  all_segments AS (
    SELECT trc.main_riv, trc.geom
    FROM tempo.riversegments_baltic trc
    JOIN unit_riv ur ON ur.main_riv = trc.main_riv
  ),
  catchments_with_riv AS (
    SELECT DISTINCT tcb.hybas_id, tcb.main_bas, trc.main_riv, tcb.shape
    FROM tempo.catchments_baltic tcb
    JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
  ),
  deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, main_bas, hybas_id, shape
    FROM catchments_with_riv
  ),
  merged AS (
    SELECT main_riv, MIN(main_bas) AS main_bas, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_riv
  )
  INSERT INTO refbast.tr_area_are (
  are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT 
    nextval('refbast.seq'),
    17,
    main_bas::TEXT,
    'River',
    false,
    ST_Multi(geom),
    NULL
  FROM merged
  WHERE geom IS NOT NULL
  AND main_bas NOT IN (SELECT are_code::integer FROM refbast.tr_area_are WHERE are_lev_code='River'); --7
  */
