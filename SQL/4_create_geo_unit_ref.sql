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





---------------------------- NAS -------------------------------------

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
        
        
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom_polygon, geom_line)
WITH fisherieswgnas AS (  
     SELECT DISTINCT DATABASE.area         
    FROM refsalmoglob.database WHERE area NOT LIKE '%fish%' AND AREA NOT LIKE '%coun%')
SELECT nextval('refnas.seq') AS are_id,
       2 AS are_are_id,
       area,
       'Assessment_unit' AS are_lev_code,
        true AS are_ismarine,
        NULL AS geom_polygon,
		NULL AS geom_line
        FROM fisherieswgnas; --28
       

        
        
        
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
 
 
       
