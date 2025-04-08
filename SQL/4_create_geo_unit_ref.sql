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


INSERT INTO refbast.tr_area_are (are_id, are_code, are_lev_code, are_ismarine, geom)
VALUES (1, 'Temporary Parent', 'Stock', true, NULL);


INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
SELECT nextval('refbast.seq') AS are_id,
	1 AS are_are_id,
	'Baltic marine' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	true AS are_ismarine,
	ST_Union(geom) AS geom
	FROM ref.tr_fishingarea_fia 
	WHERE"fia_level"='Division' AND "fia_division" IN ('27.3.b, c','27.3.d');

INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
SELECT nextval('refbast.seq') AS are_id,
	1 AS are_are_id,
	'Baltic inland' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	false AS are_ismarine,
	ST_Union(shape) AS geom
	FROM tempo.catchments_baltic
	WHERE rtrim(tableoid::regclass::text, '.catchments') IN ('h_baltic30to31', 'h_baltic22to26', 'h_baltic27to29_32');


WITH unioned_polygons AS (
  SELECT (ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(geom))).geom)),0.0001,FALSE)) AS geom
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
  geom = (SELECT ST_Multi(geom) FROM filtered_polygon)
WHERE are_id = 1;

DROP FUNCTION IF EXISTS insert_country_baltic(country TEXT, p_are_are_id INT);
CREATE OR REPLACE FUNCTION insert_country_baltic(country TEXT)
RETURNS VOID AS 
$$
BEGIN
  EXECUTE '
    INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
    WITH country_selection AS (
      SELECT ST_Union(tbc.shape) AS geom, rc.cou_country
      FROM tempo.catchments_baltic tbc
      JOIN ref.tr_country_cou rc 
      ON ST_Intersects(tbc.shape, rc.geom)
      WHERE rc.cou_country = ''' || country || '''
      GROUP BY rc.cou_country
    )
    SELECT nextval(''refbast.seq'') AS are_id,
           3 AS are_are_id,
           ''' || country || ''' AS are_code,
           ''Country'' AS are_lev_code,
           false AS are_ismarine,
           geom AS geom
    FROM country_selection;
  ';
END;
$$ LANGUAGE plpgsql;

SELECT insert_country_baltic('Finland');
SELECT insert_country_baltic('Sweden');
SELECT insert_country_baltic('Estonia');
SELECT insert_country_baltic('Latvia');
SELECT insert_country_baltic('Lithuania');
SELECT insert_country_baltic('Poland');
SELECT insert_country_baltic('Germany');
SELECT insert_country_baltic('Denmark');
SELECT insert_country_baltic('Russia');

-- Test for Country level
--ALTER SEQUENCE refbast.seq RESTART WITH 4;
--INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
--WITH country_selection AS (
--	SELECT ST_Union(tbc.shape) AS geom, rc.cou_country
--		FROM tempo.catchments_baltic tbc
--		JOIN ref.tr_country_cou rc 
--		ON ST_Intersects(tbc.shape, rc.geom)
--		WHERE rc.cou_country = 'Finland'
--		GROUP BY rc.cou_country
--)
--SELECT nextval('refbast.seq') AS are_id,
--	nextval('refbast.seq') AS are_are_id,
--	'Finland' AS are_code,
--	'Country' AS are_lev_code,
--	--are_wkg_code,
--	false AS is_marine,
--	geom AS geom
--	FROM country_selection;
--
--
--
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Sweden'
--
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Denmark'
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Estonia'
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Latvia'
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Lithuania'
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Poland'
--	
--SELECT tbc.shape, rc.cou_country
--	FROM tempo.catchments_baltic tbc, ref.tr_country_cou rc
--	WHERE ST_Intersects(tbc.shape,rc.geom) AND rc.cou_country = 'Germany'
	
	
	
	
	
	
-- Test for assessment unit level
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;
	
	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;

	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;

	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;
	
	
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;




INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
		ST_Union(geom) AS geom
		FROM retrieve_catchments;

	
	
-- Rivers level
DROP FUNCTION IF EXISTS insert_river_areas(p_are_are_id INT, p_ass_unit INT);
CREATE OR REPLACE FUNCTION insert_area_are(p_are_are_id INT, p_ass_unit INT) 
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
    SELECT DISTINCT tcb.hybas_id, trc.main_riv, tcb.shape
    FROM tempo.catchments_baltic tcb
    JOIN all_segments trc ON ST_Intersects(tcb.shape, trc.geom)
  ),
  deduplicated AS (
    SELECT DISTINCT ON (hybas_id) main_riv, hybas_id, shape
    FROM catchments_with_riv
  ),
  merged AS (
    SELECT main_riv, ST_Union(shape) AS geom
    FROM deduplicated
    GROUP BY main_riv
  )
  INSERT INTO refbast.tr_area_are (
    are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom
  )
  SELECT 
    nextval('refbast.seq'),
    p_are_are_id,
    main_riv,
    'River',
    false,
    geom
  FROM merged
  WHERE geom IS NOT NULL;
  
END;
$$ LANGUAGE plpgsql;

SELECT insert_river_areas(13,1);
SELECT insert_river_areas(14,2);
SELECT insert_river_areas(15,3);
SELECT insert_river_areas(16,4);
SELECT insert_river_areas(17,5);
SELECT insert_river_areas(18,6);
	
	
--DROP FUNCTION IF EXISTS insert_river_areas(p_are_are_id INT, p_ass_unit INT);
--CREATE OR REPLACE FUNCTION insert_river_areas(p_are_are_id INT, p_ass_unit INT)
--RETURNS VOID AS 
--$$
--DECLARE 
--  rec RECORD;
--BEGIN
--  -- Table temporaire pour suivre les hybas_id déjà utilisés
--  CREATE TEMP TABLE tmp_used_hybas (
--    hybas_id BIGINT PRIMARY KEY
--  ) ON COMMIT DROP;
--
--  -- Boucle sur les main_riv concernés
--  FOR rec IN 
--    SELECT DISTINCT trc.main_riv
--    FROM tempo.riversegments_baltic trc
--    JOIN janis.bast_assessment_units jau
--      ON ST_Intersects(trc.geom, jau.geom)
--    WHERE trc.ord_clas = 1 
--      AND jau."Ass_unit" = p_ass_unit
--  LOOP
--    EXECUTE '
--      WITH all_segments AS (
--        SELECT geom
--        FROM tempo.riversegments_baltic
--        WHERE main_riv = ''' || rec.main_riv || '''
--      ),
--      raw_catchments AS (
--        SELECT tcb.hybas_id, tcb.shape AS geom
--        FROM tempo.catchments_baltic tcb
--        JOIN all_segments seg 
--          ON ST_Intersects(tcb.shape, seg.geom)
--        WHERE tcb.hybas_id NOT IN (
--          SELECT hybas_id FROM tmp_used_hybas
--        )
--      ),
--      merged_geom AS (
--        SELECT ST_Union(geom) AS geom
--        FROM raw_catchments
--      ),
--      insert_result AS (
--        INSERT INTO refbast.tr_area_are (
--          are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom
--        )
--        SELECT 
--          nextval(''refbast.seq'') AS are_id,
--          ' || p_are_are_id || ' AS are_are_id,
--          ''' || rec.main_riv || ''' AS are_code,
--          ''River'' AS are_lev_code,
--          false AS is_marine,
--          geom
--        FROM merged_geom
--        WHERE geom IS NOT NULL
--        RETURNING 1
--      )
--      -- Ajout dans tmp_used_hybas uniquement si on a inséré
--      INSERT INTO tmp_used_hybas (hybas_id)
--	  SELECT DISTINCT hybas_id FROM raw_catchments
--	  ON CONFLICT DO NOTHING;
--
--    ';
--  END LOOP;
--END;
--$$ LANGUAGE plpgsql;
--
--
--
--SELECT insert_river_areas(13,1);
--SELECT insert_river_areas(14,2);
--SELECT insert_river_areas(15,3);
--SELECT insert_river_areas(16,4);
--SELECT insert_river_areas(17,5);
--SELECT insert_river_areas(18,6);
--SELECT * FROM refbast.tr_area_are;




-- ICES Major
--INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
--WITH select_major AS (
--	SELECT geom FROM ref.tr_fishingarea_fia tff
--	WHERE tff.fia_level = 'Major' AND fia_code = '27'
--)
--SELECT nextval('refbast.seq') AS are_id,
--		1 AS are_are_id,
--		'27' AS are_code,
--		'Major' AS are_lev_code,
--		are_wkg_code,
--		true AS is_marine,
--		geom AS geom
--		FROM select_major;
	
-- ICES Subareas
--INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
--WITH select_subarea AS (
--	SELECT geom FROM ref.tr_fishingarea_fia tff
--	WHERE tff.fia_level = 'Subarea' AND tff.fia_code = '27.3'
--)
--SELECT nextval('refbast.seq') AS are_id,
--		3 AS are_are_id,
--		'27.3' AS are_code,
--		'Subarea' AS are_lev_code,
--		--are_wkg_code,
--		true AS is_marine,
--		geom AS geom
--		FROM select_subarea;
	
	
-- ICES Divisions
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
WITH select_division AS (
	SELECT geom FROM ref.tr_fishingarea_fia tff
	WHERE tff.fia_level = 'Division' AND tff.fia_division = '27.3.b, c'
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'27.3.b, c' AS are_code,
		'Division' AS are_lev_code,
		--are_wkg_code,
		true AS is_marine,
		geom AS geom
		FROM select_division;


INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
WITH select_division AS (
	SELECT geom FROM ref.tr_fishingarea_fia tff
	WHERE tff.fia_level = 'Division' AND tff.fia_division = '27.3.d'
)
SELECT nextval('refbast.seq') AS are_id,
		3 AS are_are_id,
		'27.3.d' AS are_code,
		'Division' AS are_lev_code,
		--are_wkg_code,
		true AS is_marine,
		geom AS geom
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
    INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
    WITH select_subdivision AS (
      SELECT geom FROM ref.tr_fishingarea_fia tff 
      WHERE tff.fia_level = ''Subdivision'' AND tff.fia_subdivision = ''' || p_are_code || '''
    )
    SELECT nextval(''refbast.seq'') AS are_id,
           ' || p_are_are_id || ' AS are_are_id,
           ''' || p_are_code || ''' AS are_code,
           ''Subdivision'' AS are_lev_code,
           true AS is_marine,
           geom AS geom
    FROM select_subdivision;
  ';
END;
$$ LANGUAGE plpgsql;

SELECT insert_fishing_subdivision('d.31', 22);
SELECT insert_fishing_subdivision('d.30', 22);
SELECT insert_fishing_subdivision('d.32', 22);
SELECT insert_fishing_subdivision('d.27', 22);
SELECT insert_fishing_subdivision('d.28', 22);
SELECT insert_fishing_subdivision('d.29', 22);
SELECT insert_fishing_subdivision('d.24', 22);
SELECT insert_fishing_subdivision('d.25', 22);
SELECT insert_fishing_subdivision('d.26', 22);
SELECT insert_fishing_subdivision('c.22', 21);
SELECT insert_fishing_subdivision('b.23', 21);

SELECT * FROM refbast.tr_area_are;
	--- NAS 

-- Creating NAS Stock Unit

--CREATE SCHEMA refnas;

DROP TABLE IF EXISTS refnas.tr_area_are;
CREATE TABLE refnas.tr_area_are () INHERITS (ref.tr_area_are);


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

ALTER SEQUENCE refnas.seq RESTART WITH 1;
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
WITH unioned_polygons AS (
	SELECT (ST_ConcaveHull(ST_MakePolygon(ST_ExteriorRing((ST_Dump(ST_Union(geom))).geom)),0.0001,FALSE)) AS geom
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
SELECT 
	nextval('refnas.seq') AS are_id,
	1 AS are_are_id,
	'NEAC' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	NULL AS are_ismarine,
	geom
	FROM filtered_polygon;



INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
	geom AS geom
	FROM selected_level;
	
INSERT INTO refnas.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
SELECT nextval('refnas.seq') AS are_id,
	1 AS are_are_id,
	'NEAC inland' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	false AS are_ismarine,
	ST_Union(shape) AS geom
	FROM ref.catchments_nas
	WHERE rtrim(tableoid::regclass::text, '.catchments') IN ('h_barents', 'h_biscayiberian', 'h_celtic', 'h_iceland',
															'h_norwegian', 'h_nseanorth', 'h_nseasouth', 'h_nseauk',
															'h_svalbard');
	


--SELECT DISTINCT trim(tableoid::regclass::text, '.catchments') AS table_name
--FROM ref.catchments_nas;
--SELECT tableoid::regclass::text AS table_name
--FROM ref.catchments;

														
-- finding a way to add names to baltic rivers
WITH add_names AS (
    SELECT DISTINCT 
        c.shape, 
        c.main_bas, 
        r."Name" AS river_name
    FROM h_baltic30to31.catchments c
    JOIN janis.reared_salmon_rivers_accessible_sections r
        ON ST_Intersects(r.geom, c.shape)
    WHERE c.order_ = 1
    UNION ALL
    SELECT DISTINCT 
        c.shape, 
        c.main_bas, 
        w."Name" AS river_name
    FROM h_baltic30to31.catchments c
    JOIN janis.wild_salmon_rivers_accessible_sections w
        ON ST_Intersects(w.geom, c.shape)
    WHERE c.order_ = 1
),
basin_names AS(
	SELECT c.shape, c.main_bas, a.river_name AS river_name
    FROM h_baltic30to31.catchments c
    INNER JOIN add_names a ON c.main_bas = a.main_bas
    WHERE c.order_ = 1
)
SELECT DISTINCT ON (shape) * FROM basin_names;


WITH add_names AS (
    SELECT DISTINCT 
        c.shape, 
        c.main_bas, 
        r.name AS river_name
    FROM h_baltic30to31.catchments c
    JOIN janis."WGBAST_points" r
        ON ST_DWithin(r.geom, c.shape,0.1)
    WHERE c.order_ = 1
),
basin_names AS(
	SELECT c.shape, c.main_bas, a.river_name AS river_name
    FROM h_baltic30to31.catchments c
    INNER JOIN add_names a ON c.main_bas = a.main_bas
    WHERE c.order_ = 1
)
SELECT DISTINCT ON (shape) * FROM basin_names;



SELECT * FROM h_baltic30to31.catchments c 
WHERE C.order_ = 1;
SELECT * FROM h_baltic30to31.riversegments r 
WHERE r.ord_clas = 1;

