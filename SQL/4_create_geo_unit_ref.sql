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
	ref.tr_level_lev(lev_code) ON UPDATE CASCADE ON DELETE CASCADE;
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
    geom,
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
  geom,
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
    'river_section' AS are_lev_code,
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

WITH outlets AS (
  SELECT DISTINCT trb.main_riv, wgb.name
  FROM tempo.riversegments_baltic trb
  JOIN janis.wgbast_combined wgb
    ON ST_Intersects(trb.geom, ST_Buffer(wgb.geom, 0.01))
  WHERE trb.ord_clas = 1
    AND trb.hyriv_id = trb.main_riv
),
main_stretch AS (
  SELECT trb.*, o.name
  FROM tempo.riversegments_baltic trb
  JOIN outlets o
    ON trb.main_riv = o.main_riv
  WHERE trb.ord_clas = 1
)
SELECT DISTINCT ON (hyriv_id) geom, name
FROM main_stretch;






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

SELECT insert_fishing_subdivision('d.31', 5685);
SELECT insert_fishing_subdivision('d.30', 5685);
SELECT insert_fishing_subdivision('d.32', 5685);
SELECT insert_fishing_subdivision('d.27', 5685);
SELECT insert_fishing_subdivision('d.28', 5685);
SELECT insert_fishing_subdivision('d.29', 5685);
SELECT insert_fishing_subdivision('d.24', 5685);
SELECT insert_fishing_subdivision('d.25', 5685);
SELECT insert_fishing_subdivision('d.26', 5685);
SELECT insert_fishing_subdivision('c.22', 5684);
SELECT insert_fishing_subdivision('b.23', 5684);

SELECT * FROM refbast.tr_area_are;





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
  ref.tr_level_lev(lev_code) ON UPDATE CASCADE ON DELETE CASCADE;
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

-- CEDRIC STOPPED THERE ...
--SELECT are_id, are_code FROM refnas.tr_area_are;
														


--------------------- finding a way to add names to baltic rivers --------------------------
--WITH add_names AS (
--    SELECT DISTINCT 
--        c.shape, 
--        c.main_bas, 
--        r."Name" AS river_name
--    FROM h_baltic30to31.catchments c
--    JOIN janis.reared_salmon_rivers_accessible_sections r
--        ON ST_Intersects(r.geom, c.shape)
--    WHERE c.order_ = 1
--    UNION ALL
--    SELECT DISTINCT 
--        c.shape, 
--        c.main_bas, 
--        w."Name" AS river_name
--    FROM h_baltic30to31.catchments c
--    JOIN janis.wild_salmon_rivers_accessible_sections w
--        ON ST_Intersects(w.geom, c.shape)
--    WHERE c.order_ = 1
--),
--basin_names AS(
--	SELECT c.shape, c.main_bas, a.river_name AS river_name
--    FROM h_baltic30to31.catchments c
--    INNER JOIN add_names a ON c.main_bas = a.main_bas
--    WHERE c.order_ = 1
--)
--SELECT DISTINCT ON (shape) * FROM basin_names;
--
--
--WITH add_names AS (
--    SELECT DISTINCT 
--        c.shape, 
--        c.main_bas, 
--        r.name AS river_name
--    FROM h_baltic30to31.catchments c
--    JOIN janis."WGBAST_points" r
--        ON ST_DWithin(r.geom, c.shape,0.1)
--    WHERE c.order_ = 1
--),
--basin_names AS(
--	SELECT c.shape, c.main_bas, a.river_name AS river_name
--    FROM h_baltic30to31.catchments c
--    INNER JOIN add_names a ON c.main_bas = a.main_bas
--    WHERE c.order_ = 1
--)
--SELECT DISTINCT ON (shape) * FROM basin_names;
--
--
--
--SELECT * FROM h_baltic30to31.catchments c 
--WHERE C.order_ = 1;
--SELECT * FROM h_baltic30to31.riversegments r 
--WHERE r.ord_clas = 1;


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
INSERT INTO ref.tr_level_lev VALUES( 
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
       2 AS are_are_id,
       'postsmolt 1' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 2
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.4.T','21.4.S','21.4.R']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 2' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;



-- Post smolt 3
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.4.V','21.3.O','21.3.P']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 3' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;

-- Post smolt 4
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.3.K','21.3.L']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 4' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- Post smolt 5
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.2.G','21.2.H']))
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       'postsmolt 5' AS are_code,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        geom AS geom_polygon,
		NULL AS geom_line
        FROM geomunion;


-- WGLD
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.0.A','21.1.A','21.1.B','21.0.B','21.1.C','21.1.D','21.1.E']))
UPDATE refnas.tr_area_are
SET geom_polygon = geom
FROM geomunion
WHERE are_code = 'GLD fishery';


-- Fisheries A
WITH geomunion AS(
	SELECT ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia tff 
	WHERE fia_level = 'Division' AND fia_division = ANY(ARRAY['21.2.J','21.3.K','21.3.L','21.3.O','21.2.G','21.1.F','21.2.H',
															'21.3.M','21.3.L','21.3.N']))
UPDATE refnas.tr_area_are
SET geom_polygon = geom
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
SELECT update_geom_from_wgnas('FR', 44);
SELECT update_geom_from_wgnas('FI', 44);
SELECT update_geom_from_wgnas('RU_AK', 44);
SELECT update_geom_from_wgnas('RU_KB', 44);
SELECT update_geom_from_wgnas('RU_KW', 44);
SELECT update_geom_from_wgnas('RU_RP', 44);
SELECT update_geom_from_wgnas('EW', 44);
SELECT update_geom_from_wgnas('IR', 44);
SELECT update_geom_from_wgnas('SC_EA', 44);
SELECT update_geom_from_wgnas('SC_WE', 44);
SELECT update_geom_from_wgnas('IC_NE', 44);
SELECT update_geom_from_wgnas('IC_SW', 44);
SELECT update_geom_from_wgnas('NI_FB', 44);
SELECT update_geom_from_wgnas('NI_FO', 44);
SELECT update_geom_from_wgnas('SW', 44);
SELECT update_geom_from_wgnas('NO_SE', 44);
SELECT update_geom_from_wgnas('NO_NO', 44);
SELECT update_geom_from_wgnas('NO_SW', 44);
SELECT update_geom_from_wgnas('NO_MI', 44);

SELECT update_geom_from_wgnas('NAC', NULL);
SELECT update_geom_from_wgnas('US', 61);
SELECT update_geom_from_wgnas('QC', 61);
SELECT update_geom_from_wgnas('NF', 61);
SELECT update_geom_from_wgnas('SF', 61);
SELECT update_geom_from_wgnas('GF', 61);
SELECT update_geom_from_wgnas('LB', 61);


------------------------------- River -------------------------------

DROP FUNCTION IF EXISTS insert_river_areas_nac(p_are_are_id INT, p_ass_unit TEXT, p_excluded_id bigint[]);
CREATE OR REPLACE FUNCTION insert_river_areas_nac(p_are_are_id INT, p_ass_unit TEXT, p_excluded_id bigint[]) 
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
  filtered AS (
    SELECT m.*
    FROM merged m
    LEFT JOIN refnas.tr_area_are a
      ON m.main_bas::TEXT = a.are_code
    WHERE a.are_code IS NULL
  )
  INSERT INTO refnas.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT
    nextval('refnas.seq'),
    p_are_are_id,
    main_bas::TEXT,
    'River',
    false,
    geom,
    NULL
  FROM filtered
  WHERE geom IS NOT NULL
  AND main_bas <> ALL(p_excluded_id);
END;
$$ LANGUAGE plpgsql;



SELECT insert_river_areas_nac(73,'US',ARRAY[]::integer[]);
SELECT insert_river_areas_nac(69,'SF',ARRAY[7120064150,7120036180,7120036200,7120036270,7120036420,7120036560,7120035860,7120036230]);
SELECT insert_river_areas_nac(59,'NF',ARRAY[]::integer[]);
SELECT insert_river_areas_nac(70,'GF',ARRAY[]::integer[]);
SELECT insert_river_areas_nac(82,'LB',ARRAY[7120033390,7120033110,7120032940,7120032780,7120032730,7120032800,7120032690,7120032930]);
SELECT insert_river_areas_nac(58,'QC',ARRAY[]::integer[]);



DROP FUNCTION IF EXISTS insert_river_areas_nas(p_are_are_id INT, p_ass_unit TEXT, p_excluded_id bigint[]);
CREATE OR REPLACE FUNCTION insert_river_areas_nas(p_are_are_id INT, p_ass_unit TEXT, p_excluded_id bigint[]) 
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
  filtered AS (
    SELECT m.*
    FROM merged m
    LEFT JOIN refnas.tr_area_are a
      ON m.main_bas::TEXT = a.are_code
    WHERE a.are_code IS NULL
  )
  INSERT INTO refnas.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line
  )
  SELECT
    nextval('refnas.seq'),
    p_are_are_id,
    main_bas::TEXT,
    'River',
    false,
    geom,
    NULL
  FROM filtered
  WHERE geom IS NOT NULL
  AND main_bas <> ALL(p_excluded_id);
END;
$$ LANGUAGE plpgsql;


SELECT insert_river_areas_nas(80,'FR',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(67,'FI',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(60,'RU_AK',ARRAY[2120043040,2120043080]::integer[]);
SELECT insert_river_areas_nas(68,'RU_KB',ARRAY[2120039590,2120040190,2120040210,2120040230,2120040150,2120040160,2120040170,2120040180]::integer[]);
SELECT insert_river_areas_nas(64,'RU_KW',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(66,'RU_RP',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(61,'EW',ARRAY[2120052940]::integer[]);
SELECT insert_river_areas_nas(63,'NI_FB',ARRAY[2120055740]::integer[]);
SELECT insert_river_areas_nas(75,'NI_FO',ARRAY[2120055750,2120055770,2120055300]::integer[]);
SELECT insert_river_areas_nas(74,'IR',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(77,'SC_EA',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(62,'SC_WE',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(76,'IC_SW',ARRAY[2120057770,2120058240,2120058560]::integer[]);
SELECT insert_river_areas_nas(56,'IC_NE',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(71,'SW',ARRAY[]::integer[]);
SELECT insert_river_areas_nas(81,'NO_SE',ARRAY[2120035150,2120035190,2120035250,2120035630,2120036280,2120036340,2120034510,2120034520,2120034540]::integer[]);
SELECT insert_river_areas_nas(65,'NO_NO',ARRAY[2120037610]::integer[]);
SELECT insert_river_areas_nas(79,'NO_SW',ARRAY[2120035780]::integer[]);
SELECT insert_river_areas_nas(78,'NO_MI',ARRAY[]::integer[]);



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
    'river_section' AS are_lev_code,
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
    'river_section' AS are_lev_code,
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
  SELECT DISTINCT trb.main_riv, rdg.rivername
  FROM tempo.riversegments_baltic trb
  JOIN janis.rivers_db_graeme rdg
    ON ST_DWithin(trb.geom, rdg.geom, 200)
  WHERE trb.ord_clas = 1
    AND trb.hyriv_id = trb.main_riv
),
main_stretch AS (
  SELECT trb.*, o.rivername
  FROM tempo.riversegments_baltic trb
  JOIN outlets o
    ON trb.main_riv = o.main_riv
  WHERE trb.ord_clas = 1
)
SELECT DISTINCT ON (hyriv_id) geom, rivername
FROM main_stretch;


------------------------------- Subarea -------------------------------


INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
SELECT 
  nextval('refnas.seq') AS are_id,
  1 AS are_are_id,
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
 
 
       
