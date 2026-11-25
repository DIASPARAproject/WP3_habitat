


-- create a materialised view of all the riversegment tables.



SELECT table_schema
FROM information_schema.tables
WHERE table_name = 'riversegments';

DROP FUNCTION ref.create_riversegments_mv;
CREATE OR REPLACE FUNCTION ref.create_riversegments_mv(
    p_schemas text[],
    p_mv_schema text DEFAULT 'ref',
    p_mv_name text DEFAULT 'riversegments'
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql text;
BEGIN
    -- Build the UNION ALL query
    SELECT string_agg(
        format(
            'SELECT %L AS schema_name, rs.* FROM %I.riversegments rs',
            s, s
        ),
        E'\nUNION \n'
    )
    INTO v_sql
    FROM unnest(p_schemas) AS s;

    IF v_sql IS NULL THEN
        RAISE EXCEPTION 'No schemas provided';
    END IF;

    -- Drop existing MV if present
    EXECUTE format(
        'DROP MATERIALIZED VIEW IF EXISTS %I.%I',
        p_mv_schema,
        p_mv_name
    );

    -- Create the MV
    EXECUTE format(
        'CREATE MATERIALIZED VIEW %I.%I AS %s',
        p_mv_schema,
        p_mv_name,
        v_sql
    );
END;
$$;
/*
WITH z as(
SELECT array_agg(table_schema) schemas
FROM information_schema.tables
WHERE table_name = 'riversegments'
)
SELECT z.schemas FROM z
*/
SELECT ref.create_riversegments_mv(ARRAY['h_barents','h_adriatic','h_biscayiberian','h_medwest','h_celtic','h_baltic22to26',
'h_southatlantic','h_southmedcentral','h_southmedeast','h_southmedwest','h_svalbard','h_baltic30to31',
'h_baltic27to29_32','h_blacksea','h_iceland','h_medcentral','h_medeast','h_norwegian','h_nseanorth',
'h_nseasouth','h_nseauk'])

ALTER MATERIALIZED VIEW "ref".riversegments RENAME TO riversegments_raw;

ALTER MATERIALIZED VIEW "ref".riversegments_raw OWNER TO diaspara_admin;

CREATE MATERIALIZED VIEW "ref".riversegments AS SELECT DISTINCT ON (hyriv_id) *
    FROM "ref".riversegments_raw; --690088

    



CREATE INDEX ref_riversegments_geom_idx
    ON ref.riversegments USING gist(geom);

CREATE UNIQUE INDEX idx_hyriv_id_pkey 
      ON "ref".riversegments(hyriv_id);


-- find duplicated entries


SELECT * FROM h_baltic22to26.riversegments r1
     JOIN h_nseasouth.riversegments r2  ON
     r1.hyriv_id = r2.hyriv_id;

-- remove from north
DELETE FROM h_nseasouth.riversegments WHERE hyriv_id = 20233702; --1

DELETE FROM h_baltic22to26.riversegments WHERE hyriv_id IN 
(SELECT r1.hyriv_id FROM h_baltic22to26.riversegments r1
     JOIN h_nseasouth.riversegments r2  ON
     r1.hyriv_id = r2.hyriv_id); --7
     
-- other duplicated entries
--     THERE ARE A LOT I CAN'T FIX IT !!!
-- see ticket 1 diadpath
WITH duplicates AS (
  SELECT hyriv_id,
         COUNT(*) AS n
  FROM "ref".riversegments
  GROUP BY hyriv_id
  HAVING COUNT(*) > 1
  ORDER BY n DESC
)
  SELECT count(*), schema_name FROM 
  "ref".riversegments r
  JOIN duplicates du ON du.hyriv_id = r.hyriv_id 
  GROUP BY schema_name;
;     
     

-- REFRESH MATERIALIZED VIEW ref.riversegments;
CREATE INDEX riversegments_baltic_geom_idx ON tempo.riversegments_baltic USING gist(geom);

-- Update the area table (the sources table in each schema) to fix rivernames
-- this first unions the many small riversegments
-- the union still creates duplicates so I just select one grouped segment per rivername

SET work_mem='1GB';
DROP TABLE IF EXISTS janis.temp_joined_basins;
CREATE TABLE janis.temp_joined_basins AS(
  SELECT "name" AS riv_rivername,
  ST_Union(geom) AS geom
  FROM janis.wgbast_combined
  GROUP BY "name"
); --121

CREATE INDEX temp_joined_basins_geom_index ON tempo.riversegments_baltic USING gist(geom);

DROP TABLE IF EXISTS janis.temp_name_wgbast;
CREATE TABLE janis.temp_name_wgbast AS(
WITH lu2 AS(
   SELECT 
   lu.riv_rivername,
   sub.hyriv_id,
   sub.dist_dn_km,
   lu.geom
   FROM janis.temp_joined_basins lu 
   CROSS JOIN LATERAL (
   SELECT 
   r.hyriv_id,
   r.dist_dn_km,
   geom
   FROM   tempo.riversegments_baltic r
   WHERE st_dwithin(r.geom, lu.geom, 500) 
   AND r.geom && lu.geom
   ) sub
   ORDER BY dist_dn_km  
),
 lu3 AS(
  SELECT DISTINCT ON (riv_rivername)
  * FROM lu2)  , 
select_basin AS (
  SELECT are_code, 
  geom_polygon
  FROM refbast.tr_area_are
  WHERE are_lev_code = 'River'
),
join_b AS (
  SELECT lu.riv_rivername,
         sb.are_code AS riv_are_code,
         lu.dist_dn_km,
         lu.geom
  FROM lu3 lu
  JOIN select_basin sb  
    ON ST_Intersects(lu.geom, sb.geom_polygon)
    ORDER BY are_code,dist_dn_km
)
SELECT * FROM join_b); --2026

-- get the names from EU_hydro

DROP MATERIALIZED VIEW refbast.tr_area_are_3035;
CREATE MATERIALIZED VIEW refbast.tr_area_are_3035 AS
SELECT
    are_id,
    are_name,
    ST_makevalid(ST_Transform(geom_polygon, 3035)) AS geom
FROM refbast.tr_area_are
WHERE are_lev_code = 'River'; --532
CREATE INDEX tmp_are_gix
    ON refbast.tr_area_are_3035 USING GIST (geom);--835


CREATE MATERIALIZED VIEW habitat_amber.catchment AS
SELECT
    river_group AS river_group,
    initcap(split_part(river_name, '_',1)) AS river_name,
     st_makevalid(geom) AS geom
FROM habitat_amber.amber_h1_catchments_ccm2_euhydro_hydrography90; --1200


CREATE INDEX idx_catchment_gix
    ON habitat_amber.catchment USING GIST (geom);




CREATE TABLE tempo.join_rivername_amber AS(
    SELECT
        are_id,
        are_name,
        river_group,
        river_name
    FROM habitat_amber.catchment b
    CROSS JOIN LATERAL (
    SELECT are_id,
        are_name,
        ST_Area(ST_Intersection(a.geom, b.geom)) AS overlap_area
        FROM  refbast.tr_area_are_3035  a
        WHERE
        ST_Intersects(a.geom, b.geom)
        AND a.geom && b.geom
        ORDER BY are_id, overlap_area DESC
        LIMIT 1
) c); --169






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


-- 

SELECT * FROM  "ref".tr_rivernames_riv


WITH riv AS (
SELECT are_id, riv_rivername FROM refnas.tr_area_are are 
INNER JOIN "ref".tr_rivernames_riv ON 
riv_are_code = are_code)
UPDATE refnas.tr_area_are SET are_name = riv_rivername FROM riv WHERE riv.are_id = tr_area_are.are_id; --1220

/*
 * First join the hydroshed river common table to get the distance to the sea
 * order by dist to get the closest point
 * then join again with area
 */


WITH subg AS (  
  SELECT * FROM janis.rivers_db_graeme g
  WHERE id = 62)
SELECT 
hyriv_id,
id,
st_distance(g.geom::geography, ri.geom::geography) AS dist,
ri.geom::geography && g.geom::geography AS match
FROM subg g
JOIN ref.riversegments as ri
ON ST_Dwithin(ri.geom::geography, g.geom::geography, 5000)
ORDER BY dist


DROP TABLE IF EXISTS refnas.temp_buffer_graeme_3035;
CREATE TABLE refnas.temp_buffer_graeme_3035 AS (
  SELECT 
  id,
  ices_stock,
  ices_sto_1,
  rivername,
  ices_index,
  nasco_rive,
  st_transform(geom, 3035) geom,
  st_buffer(st_transform(geom, 3035), 1000) AS geom_buffer
 FROM janis.rivers_db_graeme); --2372
 
 CREATE INDEX idx_temp_buffer_graeme_3035_geom 
 ON  refnas.temp_buffer_graeme_3035 
 USING GIST(geom);
 

 
-- this will use the buffer for intersection 
 -- && can be used and be efficient there because of the buffer.
 -- I'm getting the area code from the spatial intersect, as the id of the 
 -- is an autoincrement  e.g. so I don't really have a link. nextval('refnas.seq') AS riv_id
 -- I can't use the river name some values are duplicated
DROP TABLE IF EXISTS refnas.temp_refnas_nasco_rivers;
CREATE TABLE refnas.temp_refnas_nasco_rivers AS(
WITH
proj AS(
  SELECT 
  id,
  ices_stock,
  ices_sto_1,
  rivername,
  ices_index,
  nasco_rive,
  hyriv_id,
  dist_dn_km,
  st_distance(g.geom, st_transform(ri.geom, 3035)) AS dist,
  g.geom
  FROM refnas.temp_buffer_graeme_3035 g
  INNER JOIN  ref.riversegments as ri
  ON  st_transform(ri.geom, 3035) && g.geom_buffer 
  -- this allows for a quick lowering of the number of rows
  -- using && without the buffer left many rivers out as && requires a bbox intersection
  WHERE ST_Dwithin(st_transform(ri.geom, 3035), g.geom, 2000)
  ORDER BY id, dist
),
-- here we only keep the closest segment
ukproj AS (
  SELECT DISTINCT ON (id) *  FROM proj
),
area_river AS(
  SELECT are_id,
  are_code,
  st_transform(geom_polygon, 3035) AS geom
  FROM refnas.tr_area_are ar 
  WHERE are_lev_code = 'River'
),
join_area_river AS(
  SELECT 
  id,
  ices_stock,
  ices_sto_1,
  rivername,
  ices_index,
  nasco_rive,
  hyriv_id,
  dist_dn_km,  
  u.geom
  are_id,
  are_code FROM area_river a
  JOIN ukproj u ON
  st_intersects(u.geom, a.geom)
)

SELECT * FROM join_area_river); -- 1342


-- this will update, it will work because are_code is unique

WITH ord AS (
SELECT * FROM refnas.temp_refnas_nasco_rivers
ORDER BY are_code, dist_dn_km),
     uk AS (
SELECT DISTINCT ON (are_code) are_code, rivername
FROM ord)
UPDATE refnas.tr_area_are SET are_name = rivername 
FROM uk WHERE uk.are_code = tr_area_are.are_code; --645



WITH ord AS (
SELECT * FROM refnas.temp_refnas_nasco_rivers
ORDER BY are_code, dist_dn_km),
     uk AS (
SELECT DISTINCT ON (are_code) are_code, rivername
FROM ord)
SELECT are_name, are_lev_code, rivername FROM  refnas.tr_area_are 
Join uk on uk.are_code = tr_area_are.are_code
WHERE are_name = 'Adour';


-- this is wrong




-- Get the EU hydro name

WITH jj AS(
SELECT are_code, are_name, euhr.nametext_eu_hydro AS eu_hydro_name, riv_rivername  FROM refbast.tr_area_are as are 
JOIN habitat_amber.amber_drn_eu_hydro_rivers euhr 
ON st_intersects(st_transform(are.geom_polygon , 3035),euhr.geom)
LEFT JOIN "ref".tr_rivernames_riv ON 
riv_are_code = are_code
WHERE are_lev_code = 'River'
AND nametext_eu_hydro IS NOT NULL),
cc AS(
SELECT count(*) AS N, 
are_code, are_name, eu_hydro_name, riv_rivername
FROM jj
GROUP BY are_code, are_name, eu_hydro_name, riv_rivername)
SELECT * FROM cc ORDER BY are_code, n desc




SELECT * FROM ref.tr_area_are are 
JOIN "ref".riversegments
ON are.are_code::integer = riv.hybas_l12
WHERE NOT  are_ismarine
AND are_lev_code = 'River_section'



