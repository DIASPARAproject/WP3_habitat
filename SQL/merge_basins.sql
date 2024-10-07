
-- select only useful data from hydroatlas
DROP TABLE IF EXISTS tempo.hydro_large_catchments;
CREATE TABLE tempo.hydro_large_catchments AS(
SELECT shape FROM basinatlas.basinatlas_v10_lev02
WHERE hybas_id = ANY(ARRAY[1020027430,1020034170])
UNION ALL 
SELECT shape FROM basinatlas.basinatlas_v10_lev06
WHERE hybas_id = ANY(ARRAY[2060000020,2060000030,2060084750,2060000240,2060000250,2060000350])
UNION ALL
SELECT shape FROM basinatlas.basinatlas_v10_lev07
WHERE hybas_id = ANY(ARRAY[2070000360,2070000430,2070000440,2070000530,2070000540,2070784870,2070794800,2070806260,2070085720,
2070806340,2070812170,2070816130,2070823810,2070829100])
);

DROP TABLE IF EXISTS tempo.hydro_catchments;
CREATE TABLE tempo.hydro_catchments AS (
SELECT * FROM basinatlas.basinatlas_v10_lev12 ba
WHERE EXISTS (
	SELECT 1
	FROM tempo.hydro_large_catchments hlc
	WHERE ST_Intersects(ba.shape,hlc.shape)
	)
);--79871

-- create table of merged basins for 2009
DROP TABLE IF EXISTS tempo.enveloppe_ccm ;
CREATE TABLE tempo.enveloppe_ccm AS (
SELECT st_union(seaoutlets.geom) AS geom FROM ccm21.seaoutlets,
tempo.polygon_east_med
WHERE
"window" in (2017, 2009) 
AND st_intersects(polygon_east_med.geom, seaoutlets.geom)
--AND wso_id != 2294514
);

DROP TABLE IF EXISTS tempo.border_basins;
CREATE TABLE tempo.border_basins AS(
WITH ccm_contour AS (
SELECT * FROM tempo.enveloppe_ccm)
-- we only want an intersection on the edge
SELECT hc.* FROM ccm_contour cc JOIN
hydroa.catchments hc 
ON st_intersects(hc.geom, cc.geom)
AND NOT st_contains(hc.geom, cc.geom),
tempo.polygon_east_med
WHERE st_intersects(polygon_east_med.geom, hc.geom)
); --215




-- This table cuts hydroatlas basins according to the border with ccm,
-- and extracts single geometry polygons


DROP TABLE IF EXISTS tempo.border_basins_cut;
CREATE TABLE tempo.border_basins_cut AS(
WITH ccm_contour AS (
SELECT * FROM tempo.enveloppe_ccm),
ccm_difference AS(
SELECT st_difference(bb.geom,cc.geom) geom, 
bb."HYBAS_ID" AS hybas_id FROM tempo.border_basins bb, ccm_contour cc)
SELECT (sub.p_geom).geom AS geom, (sub.p_geom).path AS PATH, hybas_id
FROM (SELECT (ST_Dump(ccm_difference.geom)) AS p_geom , hybas_id FROM ccm_difference) sub
); --581

-- Sum of surface of border basins compared to the original
DROP TABLE IF EXISTS tempo.proportion_cut;
CREATE TABLE tempo.proportion_cut AS(
WITH sumareasmallpieces AS(
  SELECT sum(st_area(bc.geom)) AS areasmallpieces, bc.hybas_id FROM tempo.border_basins_cut bc
  JOIN 
  tempo.border_basins ON border_basins."HYBAS_ID"=bc.hybas_id
  GROUP BY hybas_id
)
SELECT areasmallpieces/st_area(geom) AS proportion_cut, hybas_id FROM 
sumareasmallpieces JOIN 
tempo.border_basins ON border_basins."HYBAS_ID"=sumareasmallpieces.hybas_id
); --31

-- Putting the limit at 10 %
DROP TABLE IF EXISTS tempo.smallpieces ;
CREATE TABLE tempo.smallpieces AS (
SELECT border_basins_cut.* FROM tempo.border_basins_cut JOIN tempo.proportion_cut
ON proportion_cut.hybas_id = border_basins_cut.hybas_id
WHERE proportion_cut < 0.1
AND border_basins_cut.hybas_id NOT IN (2120000560,2120000570)); --631




---------- Test 1 : isolating gaps between polygones ----------
SELECT
	hydroa.ccm_test.gid AS id_ccm,
	hydroa.hydro_test."HYBAS_ID" AS id_hydro,
    ST_Intersection(hydroa.ccm_test.geom, hydroa.hydro_test.geom) AS geom--,
    --hydroa.ccm_test.*, hydroa.hydro_test.*
FROM
    hydroa.ccm_test
JOIN
    hydroa.hydro_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
WHERE
    ST_IsValid(ST_Intersection(hydroa.ccm_test.geom, hydroa.hydro_test.geom))
UNION ALL
SELECT
    hydroa.ccm_test.gid AS id_ccm,
    NULL AS id_hydro,
    hydroa.ccm_test.geom--,
    --hydroa.ccm_test.*, NULL::hydroa.hydro_test
FROM
    hydroa.ccm_test
LEFT JOIN
    hydroa.hydro_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
WHERE
    hydroa.hydro_test."HYBAS_ID" IS NULL
UNION ALL
SELECT
    NULL AS id_ccm,
    hydroa.hydro_test."HYBAS_ID" AS id_hydro,
    hydroa.hydro_test.geom--,
    --NULL::hydroa.ccm_test.*, hydroa.hydro_test.*
FROM
    hydroa.hydro_test
LEFT JOIN
    hydroa.ccm_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
WHERE
    hydroa.ccm_test.id IS NULL;
-- Problem : Non overlapped parts of overlapping polygons are missing (which is ok????)
   
   
   
   
---------- Test 2 : isolating gaps ----------
   --Step 1 : Merging all polygons
CREATE TABLE hydroa.isolation_test AS
SELECT
    hydroa.ccm_test.gid AS id_ccm,
    hydroa.hydro_test."HYBAS_ID" AS id_hydro,
    ST_Intersection(hydroa.ccm_test.geom, hydroa.hydro_test.geom) AS geom,
    'intersection' AS type_geom
FROM
    hydroa.ccm_test
JOIN
    hydroa.hydro_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
WHERE
    ST_IsValid(ST_Intersection(hydroa.ccm_test.geom, hydroa.hydro_test.geom))
    AND NOT ST_IsEmpty(ST_Intersection(hydroa.ccm_test.geom, hydroa.hydro_test.geom))

UNION ALL
SELECT 
    hydroa.ccm_test.gid AS id_ccm,
    NULL AS id_hydro,
    ST_Difference(hydroa.ccm_test.geom, ST_Union(hydroa.hydro_test.geom)) AS geom,
    'difference_ccm' AS type_geom
FROM
    hydroa.ccm_test
LEFT JOIN
    hydroa.hydro_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
GROUP BY
    hydroa.ccm_test.gid, hydroa.ccm_test.geom
HAVING 
    NOT ST_IsEmpty(ST_Difference(hydroa.ccm_test.geom, ST_Union(hydroa.hydro_test.geom)))

UNION ALL
SELECT
    NULL AS id_ccm,
    hydroa.hydro_test."HYBAS_ID" AS id_hydro,
    ST_Difference(hydroa.hydro_test.geom, ST_Union(hydroa.ccm_test.geom)) AS geom,
    'difference_hydro' AS type_geom
FROM
    hydroa.hydro_test
LEFT JOIN
    hydroa.ccm_test
ON
    ST_Intersects(hydroa.ccm_test.geom, hydroa.hydro_test.geom)
GROUP BY
    hydroa.hydro_test."HYBAS_ID", hydroa.hydro_test.geom
HAVING 
    NOT ST_IsEmpty(ST_Difference(hydroa.hydro_test.geom, ST_Union(hydroa.ccm_test.geom)));

-- Problem : Polygons where there is no overlapping are missing (wait.. which is good ?)

   -- Step 2 : Selecting polygons where gid is null then union by gid
CREATE TABLE hydroa.isolation_test_ccm AS
SELECT
	id_ccm,
	ST_Union(geom) AS geom
FROM
	hydroa.isolation_test
WHERE
	isolation_test.id_ccm IS NOT NULL
GROUP BY
	id_ccm;
   -- Step 3 : Selecting polygons where gid is not null then union by hybas_id
CREATE TABLE hydroa.isolation_test_hydro AS
SELECT
	id_hydro,
	id_ccm,
	ST_Union(geom) AS geom
FROM
	hydroa.isolation_test
WHERE
	isolation_test.id_ccm IS NULL
GROUP BY
	id_hydro, id_ccm; 
   
-- DROP TABLE hydroa.isolation_test_ccm
-- DROP TABLE hydroa.isolation_test_hydro
   

---------- Test 3 : creating a buffer to fill gaps ----------

CREATE TABLE hydroa.merged_catchments AS
	WITH
	-- Select and buffer the polygon where source is NULL (priority polygon)
	ccm_polygon AS (
	    SELECT ST_Buffer(geom, 400) AS geom
	    FROM hydroa.merging
	    WHERE "source" IS NULL
	),
	-- Select the polygon where source is NOT NULL (secondary polygon)
	hydro_polygon AS (
	    SELECT geom
	    FROM hydroa.merging
	    WHERE "source" IS NOT NULL
	)--,
	-- Calculate the area where the buffered polygon and the original polygon overlap
	overlap_area AS (
	    SELECT ST_Intersection(ccm_polygon.geom, hydro_polygon.geom) AS geom
	    FROM ccm_polygon, hydro_polygon
	),
	-- Remove the overlapping area from the original polygon (to keep buffered polygon priority)
	hydro_cropped AS (
	    SELECT ST_Difference(hydro_polygon.geom, overlap_area.geom) AS geom
	    FROM hydro_polygon, overlap_area
	),
	-- Combine the buffered polygon and the cropped polygon
	final_geometries AS (
	    SELECT geom
	    FROM hydroa.merging
	    WHERE "source" IS NULL
	    UNION ALL
	    SELECT geom
	    FROM hydro_cropped
	)
-- Insert combined results into the new table
	SELECT geom
	FROM final_geometries;

-- Problem : All sides of the ccm polygon are buffered where it should only be the overlapping sides




-- DROP TABLE hydroa.merging
-- DROP TABLE hydroa.merged_catchments
-- DROP TABLE hydroa.isolation_test