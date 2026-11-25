SELECT count (*) FROM refeel.tr_area_are; --82710

SELECT count (*) FROM refeel.tr_area_are where are_lev_code = 'Assessment_unit'; 
SELECT count (*) FROM refeel.tr_area_are where are_lev_code = 'Country'; 

SELECT * FROM refbast.tr_area_are WHERE are_lev_code='River'


select are_id,are_are_id,are_code,are_lev_code,are_wkg_code,are_ismarine,are_name,geom_polygon from ref.tr_area_are


SELECT cols.column_name AS var_name, 
        pgd.description AS description
  FROM information_schema.columns cols
  LEFT JOIN pg_catalog.pg_statio_all_tables st 
      ON st.schemaname = cols.table_schema AND st.relname = cols.table_name
  LEFT JOIN pg_catalog.pg_description pgd 
      ON pgd.objoid = st.relid AND pgd.objsubid = cols.ordinal_position
  WHERE cols.table_schema = 'h_adriatic'
  AND cols.table_name = 'riversegments';

SELECT obj_description('h_adriatic.riversegments'::regclass);



-- there is a constraint that sets are_code unique but this works per_working group. Some of the basisns will the same for WGEEL and the other working groups. 
-- here is a workarround

WITH 
only_rivers AS(
    SELECT * FROM ref.tr_area_are WHERE are_lev_code = 'River'), 
rivers2 AS(
    SELECT area.*, 
    riv.riv_rivername
    FROM only_rivers AS area
    LEFT JOIN ref.tr_rivernames_riv riv ON (riv.riv_are_code, riv.riv_wkg_code) = (area.are_code, area.are_wkg_code)
    ORDER BY CASE are_wkg_code
                    WHEN 'WGBAST' THEN 1
                    WHEN 'WGNAS'  THEN 2
                    WHEN 'WGEEL'  THEN 3
                  END)
  -- this will ensure that river codes are unique.
    SELECT DISTINCT ON (are_code)
    are_code,
    are_name,
    riv_rivername,
    geom_polygon    
    FROM rivers2   


  
       