-- Creating Baltic Stock tr

DROP TABLE IF EXISTS refbast.tr_area_are;
CREATE TABLE refbast.tr_area_are () INHERITS (ref.tr_area_are);


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

--DELETE FROM refbast.tr_area_are;

ALTER SEQUENCE refbast.seq RESTART WITH 1;
INSERT INTO refbast.tr_area_are (are_id, are_are_id, are_code, are_lev_code, are_ismarine, geom)
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
SELECT 
	nextval('refbast.seq') AS are_id,
	1 AS are_are_id,
	'Baltic' AS are_code,
	'Stock' AS are_lev_code,
	--are_wkg_code,  by default
	NULL AS are_ismarine,
	geom
	FROM filtered_polygon;


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
	FROM ref.catchments_baltic
	WHERE rtrim(tableoid::regclass::text, '.catchments') IN ('h_baltic30to31', 'h_baltic22to26', 'h_baltic27to29_32');


--SELECT * FROM tempo.




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

ALTER SEQUENCE refbast.seq RESTART WITH 1;
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




SELECT * FROM h_baltic30to31.catchments c 
WHERE C.order_ = 1;
SELECT * FROM h_baltic30to31.riversegments r 
WHERE r.ord_clas = 1;

