/*
 * Procedure to join the CCM and hydroatlas
 * Removing the overlapping part
 * Adding the small bits where holes remain.....
 */


-- create table of merged basins for 2009
-- polygon_east_med is a single polygon created on GIS software engulfing all polygons within the area where we want the merging to happen

ALTER TABLE tempo.polygon_east_med
  ALTER COLUMN geom
   TYPE geometry(MultiPolygon, 4326)
  USING ST_Transform(geom, 4326);

-- This is the enveloppe of existing ccm for basins included 
-- within the polygon polygon_east_med 

DROP TABLE IF EXISTS tempo.enveloppe_ccm ;
CREATE TABLE tempo.enveloppe_ccm AS (
SELECT st_union(seaoutlets.geom) AS geom FROM ccm21.seaoutlets,
tempo.polygon_east_med
WHERE
"window" in (2017, 2009) 
AND st_intersects(polygon_east_med.geom, seaoutlets.geom)
--AND wso_id != 2294514
);

-- border basins are the basins intersecting enveloppe_ccm
-- but not contained in enveloppe_ccm

DROP TABLE IF EXISTS tempo.border_basins;
CREATE TABLE tempo.border_basins AS(
WITH ccm_contour AS (
SELECT * FROM tempo.enveloppe_ccm)
-- we only want an intersection on the edge
SELECT hc.* FROM ccm_contour cc JOIN
w2020.catchments hc 
ON st_intersects(hc.geom, cc.geom)
AND NOT st_contains(hc.geom, cc.geom),
tempo.polygon_east_med
--WHERE st_intersects(polygon_east_med.geom, hc.geom)
); --271 --206




-- This table cuts border basins according to the border with ccm,
-- and extracts single geometry polygons
-- as depending on where we lie, we will later paste the bits and buts
-- to different places


DROP TABLE IF EXISTS tempo.border_basins_cut;
CREATE TABLE tempo.border_basins_cut AS(
WITH ccm_contour AS (
SELECT * FROM tempo.enveloppe_ccm),
ccm_difference AS(
SELECT st_difference(bb.geom,cc.geom) geom, 
bb.hybas_id AS hybas_id FROM tempo.border_basins bb, ccm_contour cc)
SELECT (sub.p_geom).geom AS geom, (sub.p_geom).path AS PATH, hybas_id
FROM (SELECT (ST_Dump(ccm_difference.geom)) AS p_geom , hybas_id FROM ccm_difference) sub
); --441 --392

-- Now depending on whether the border basin cut correspond to small polygons
-- or not (we fix the limit at 10 %) we extract them
DROP TABLE IF EXISTS tempo.proportion_cut;
CREATE TABLE tempo.proportion_cut AS(
WITH sumareasmallpieces AS(
  SELECT sum(st_area(bc.geom)) AS areasmallpieces, bc.hybas_id FROM tempo.border_basins_cut bc
  JOIN 
  tempo.border_basins ON border_basins.hybas_id=bc.hybas_id
  GROUP BY bc.hybas_id
)
SELECT areasmallpieces/st_area(geom) AS proportion_cut, border_basins.hybas_id FROM 
sumareasmallpieces JOIN 
tempo.border_basins ON border_basins.hybas_id=sumareasmallpieces.hybas_id
); --110 --97

-- so smallpieces correspond to these small parts selected earlier, the
-- small basins corresponding to bits of ccm catchment at the edge of
-- border basins
DROP TABLE IF EXISTS tempo.smallpieces ;
CREATE TABLE tempo.smallpieces AS (
SELECT 
	ROW_NUMBER() OVER() AS sp_id,
	border_basins_cut.* 
	FROM tempo.border_basins_cut 
	JOIN tempo.proportion_cut
	ON proportion_cut.hybas_id = border_basins_cut.hybas_id
	WHERE proportion_cut < 0.1
	AND border_basins_cut.hybas_id NOT IN (2120000560,2120000570)
); --370 --324

-- these geometries are valid ....
-- we had some troubles later, which seem to have fixed themselves 
-- by changing the scripts

--SELECT  DISTINCT  st_isvalid(geom) , count(*) OVER (PARTITION BY st_isvalid(geom) )
--FROM tempo.smallpieces  



-- below there is a problem both with st_touches between our polygons,
-- or st_intersection which returns zero when it should not looking at the map
-- there must be a point isolated somewhere along the geometry
-- we fixed it by only all geometries in the intersection below, including the ones
-- reporting zero. 
-- There might have been problems at this stage of polygons attached to the wrong polygons, 
-- but it's not apparent from our maps.

--SELECT ST_Intersection(a.geom, b.geom), 
--st_intersects(a.geom,b.geom),
--st_touches (a.geom, b.geom) ,
--a.geom,
--b.geom
--FROM  
--(SELECT * FROM tempo.smallpieces  WHERE sp_id = 148) a,
--(SELECT * FROM tempo.border_basins  WHERE hybas_id= 2121283180) b


-- Now we need to select the border catchements, but also some catchement
-- which are touching the smallpieces and were not selected earlier.
-- To do so we UNION with the border_basin_cut, but instead of choosing
-- proportion cut <.1 we choose the reverse.

DROP TABLE IF EXISTS tempo.catchments_touching_the_right_side;
CREATE TABLE tempo.catchments_touching_the_right_side		 AS(
SELECT  catchments.hybas_id, 
catchments.geom 
FROM w2020.catchments ,
tempo.smallpieces,
tempo.enveloppe_ccm
WHERE st_intersects (smallpieces.geom, catchments.geom)
AND NOT st_intersects(enveloppe_ccm.geom, catchments.geom)
UNION 
SELECT border_basins_cut.hybas_id, geom FROM tempo.border_basins_cut
JOIN tempo.proportion_cut ON 
proportion_cut.hybas_id = border_basins_cut.hybas_id
WHERE proportion_cut >= 0.1); --71 --68

-- smallpieces was dumped to single entities. We join in with
-- catchments_touching_the_right_side using the largest touching
-- length and then only select in the table the line wich represents
-- this larger touching surface and drop other smaller touching pairs.
DROP TABLE IF EXISTS tempo.selected_smallpieces;
CREATE TABLE tempo.selected_smallpieces AS (
    WITH border_length AS (
        SELECT
            sp_id,
            s.hybas_id AS s_hybas_id,
            w.hybas_id AS w_hybas_id,
            ST_Length(ST_Intersection(s.geom, w.geom)) AS shared_border_length 
        FROM
            tempo.smallpieces s
        JOIN
            tempo.catchments_touching_the_right_side w
        ON
            ST_intersects(s.geom, w.geom)
    ),
    longest_border_length AS (
        SELECT 
            * 
        FROM 
            border_length
        ORDER BY 
            sp_id, shared_border_length DESC
    )
    SELECT DISTINCT ON (sp_id) 
        sp_id, 
        s_hybas_id, 
        w_hybas_id, 
        shared_border_length
    FROM 
        longest_border_length
); --314 --284


-- here we "merge" the small pieces with atchments_touching_the_right_side
-- using only the pairs in selected_smallpieces as joining instructions. 
-- the first step is to create just a single line with multipolygon in 
-- one_row_per_smallpiece_within_catchment and then joining this multipolygons
-- made of small bits with the catchments_touching_the_right_side polygon
DROP TABLE IF EXISTS tempo.modified_catchments;
CREATE TABLE tempo.modified_catchments AS (
WITH one_row_per_smallpiece_within_catchment AS (
    SELECT
        catchments_touching_the_right_side.hybas_id,
        ST_Collect(smallpieces.geom) AS geom_smallpieces,
        catchments_touching_the_right_side.geom
    FROM tempo.catchments_touching_the_right_side
    -- LEFT JOIN to ensure that all catchments are included, even those without corresponding small pieces
    LEFT JOIN tempo.selected_smallpieces
        ON selected_smallpieces.w_hybas_id = catchments_touching_the_right_side.hybas_id
    LEFT JOIN tempo.smallpieces
        ON smallpieces.sp_id = selected_smallpieces.sp_id
    GROUP BY catchments_touching_the_right_side.hybas_id, catchments_touching_the_right_side.geom
)
SELECT
    hybas_id,
    ST_Multi(ST_Union(geom,COALESCE(geom_smallpieces, geom))) AS geom
    --ST_Multi(ST_Union(geom,geom_smallpieces)) AS geom
FROM one_row_per_smallpiece_within_catchment
); --68


-- Oh no some small bits remain lonely and crying
-- they are beyond the polygons selected
-- we are going to fetch them again

DROP TABLE IF EXISTS tempo.modified_catchments2;
CREATE TABLE tempo.modified_catchments2 AS(
WITH missing_smallpieces AS (
SELECT s.sp_id , s.geom FROM tempo.smallpieces s,
tempo.modified_catchments m
WHERE st_intersects(s.geom,m.geom)
AND NOT st_contains(m.geom,s.geom)
),
 border_length AS (
        SELECT
            sp_id,
            w.hybas_id AS w_hybas_id,
            ST_Length(ST_Intersection(s.geom, w.geom)) AS shared_border_length 
        FROM
            missing_smallpieces s
        JOIN
            tempo.modified_catchments w
        ON
            ST_intersects(s.geom, w.geom)
    ),
    longest_border_length AS (
        SELECT 
            * 
        FROM 
            border_length
        ORDER BY 
            sp_id, shared_border_length DESC
    ),
selected_smallpieces AS(    
    SELECT DISTINCT ON (sp_id) 
        sp_id, 
        w_hybas_id, 
        shared_border_length
    FROM 
        longest_border_length),        
 one_row_per_smallpiece_within_catchment AS (
  SELECT
    modified_catchments.hybas_id,
    ST_Collect(missing_smallpieces.geom) AS geom_smallpieces,
    --ST_Union(missing_smallpieces.geom) AS geom_smallpieces,
    modified_catchments.geom
  FROM missing_smallpieces
  INNER JOIN tempo.selected_smallpieces
  ON missing_smallpieces.sp_id = selected_smallpieces.sp_id
  INNER JOIN tempo.modified_catchments
  ON tempo.selected_smallpieces.w_hybas_id = modified_catchments.hybas_id

  GROUP BY modified_catchments.hybas_id,modified_catchments.geom)
  SELECT
    hybas_id,
    ST_Multi(ST_Union(geom,geom_smallpieces)) AS geom
  FROM  one_row_per_smallpiece_within_catchment); --21 --23

DROP TABLE IF EXISTS tempo.modified_catchments3;
CREATE TABLE tempo.modified_catchments3 AS 
SELECT
    hybas_id,
    ST_Multi(ST_Union(geom)) AS geom
FROM 
    tempo.modified_catchments
GROUP BY 
    hybas_id; --48


UPDATE tempo.modified_catchments3 SET geom=modified_catchments2.geom FROM 
tempo.modified_catchments2 WHERE modified_catchments2.hybas_id=modified_catchments3.hybas_id;--21 --22

-- modify riveratlas.catchments remove basins fully below 
DELETE FROM w2020.catchments c
WHERE EXISTS (
SELECT 1
FROM tempo.enveloppe_ccm e
WHERE (ST_Area(ST_Intersection(c.geom,e.geom))/ST_Area(c.geom)) >= 0.9
); --224 --162


-- update geometry of basins according to tempo.modified_catchments3
UPDATE w2020.catchments SET geom=modified_catchments3.geom
FROM tempo.modified_catchments3 WHERE catchments.hybas_id=modified_catchments3.hybas_id; --48

