
-- selecting two adjacent catchments to make some test
-- first i gather all columns
WITH columns_ccm AS (
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'ccm' 
    AND table_name = 'catchments'
),
columns_hydroa AS (
    SELECT column_name
    FROM information_schema.columns
    WHERE table_schema = 'hydroa'
    AND table_name = 'catchments'
),
all_columns AS (
    -- Get all columns from both tables
    SELECT column_name FROM columns_ccm
    UNION
    SELECT column_name FROM columns_hydroa
)
SELECT 
    -- Generate SELECT clause for ccm.catchments: existing columns or NULL for hydroa columns
    string_agg(
        CASE 
            WHEN c.column_name IN (SELECT column_name FROM columns_ccm)
            THEN 'ccm.' || c.column_name
            ELSE 'NULL AS ' || c.column_name
        END, ', '
    ) AS select_clause_ccm,
    
    -- Generate SELECT clause for hydroa.catchments: existing columns or NULL for ccm columns
    string_agg(
        CASE 
            WHEN c.column_name IN (SELECT column_name FROM columns_hydroa)
            THEN 'hydroa.' || c.column_name
            ELSE 'NULL AS ' || c.column_name
        END, ', '
    ) AS select_clause_hydroa
FROM all_columns c;





-- selecting polygones with all columns gathered from previous query
CREATE TABLE hydroa.merging AS
	SELECT 
	NULL AS COAST, NULL AS DIST_MAIN, NULL AS DIST_SINK, NULL AS ENDO, NULL AS HYBAS_ID, NULL AS MAIN_BAS, NULL AS NEXT_DOWN, NULL AS NEXT_SINK, NULL AS ORDER_, NULL AS PFAF_ID, NULL AS SORT, NULL AS SUB_AREA, NULL AS UP_AREA, NULL AS aet_mm_s01, NULL AS aet_mm_s02, NULL AS aet_mm_s03, NULL AS aet_mm_s04, NULL AS aet_mm_s05, NULL AS aet_mm_s06, NULL AS aet_mm_s07, NULL AS aet_mm_s08, NULL AS aet_mm_s09, NULL AS aet_mm_s10, NULL AS aet_mm_s11, NULL AS aet_mm_s12, NULL AS aet_mm_syr, NULL AS aet_mm_uyr, ccm.area, ccm.area_km2, NULL AS ari_ix_sav, NULL AS ari_ix_uav, NULL AS cls_cl_smj, NULL AS cly_pc_sav, NULL AS cly_pc_uav, NULL AS clz_cl_smj, NULL AS cmi_ix_s01, NULL AS cmi_ix_s02, NULL AS cmi_ix_s03, NULL AS cmi_ix_s04, NULL AS cmi_ix_s05, NULL AS cmi_ix_s06, NULL AS cmi_ix_s07, NULL AS cmi_ix_s08, NULL AS cmi_ix_s09, NULL AS cmi_ix_s10, NULL AS cmi_ix_s11, NULL AS cmi_ix_s12, NULL AS cmi_ix_syr, NULL AS cmi_ix_uyr, NULL AS crp_pc_sse, NULL AS crp_pc_use, NULL AS dis_m3_pmn, NULL AS dis_m3_pmx, NULL AS dis_m3_pyr, NULL AS dor_pc_pva, NULL AS ele_mt_sav, NULL AS ele_mt_smn, NULL AS ele_mt_smx, NULL AS ele_mt_uav, ccm.elev_max, ccm.elev_mean, ccm.elev_min, ccm.elev_std, NULL AS ero_kh_sav, NULL AS ero_kh_uav, ccm.feature_co, NULL AS fec_cl_smj, NULL AS fmh_cl_smj, NULL AS for_pc_sse, NULL AS for_pc_use, NULL AS gad_id_smj, NULL AS gdp_ud_sav, NULL AS gdp_ud_ssu, NULL AS gdp_ud_usu, NULL AS geom, ccm.gid, NULL AS gla_pc_sse, NULL AS gla_pc_use, NULL AS glc_cl_smj, NULL AS glc_pc_s01, NULL AS glc_pc_s02, NULL AS glc_pc_s03, NULL AS glc_pc_s04, NULL AS glc_pc_s05, NULL AS glc_pc_s06, NULL AS glc_pc_s07, NULL AS glc_pc_s08, NULL AS glc_pc_s09, NULL AS glc_pc_s10, NULL AS glc_pc_s11, NULL AS glc_pc_s12, NULL AS glc_pc_s13, NULL AS glc_pc_s14, NULL AS glc_pc_s15, NULL AS glc_pc_s16, NULL AS glc_pc_s17, NULL AS glc_pc_s18, NULL AS glc_pc_s19, NULL AS glc_pc_s20, NULL AS glc_pc_s21, NULL AS glc_pc_s22, NULL AS glc_pc_u01, NULL AS glc_pc_u02, NULL AS glc_pc_u03, NULL AS glc_pc_u04, NULL AS glc_pc_u05, NULL AS glc_pc_u06, NULL AS glc_pc_u07, NULL AS glc_pc_u08, NULL AS glc_pc_u09, NULL AS glc_pc_u10, NULL AS glc_pc_u11, NULL AS glc_pc_u12, NULL AS glc_pc_u13, NULL AS glc_pc_u14, NULL AS glc_pc_u15, NULL AS glc_pc_u16, NULL AS glc_pc_u17, NULL AS glc_pc_u18, NULL AS glc_pc_u19, NULL AS glc_pc_u20, NULL AS glc_pc_u21, NULL AS glc_pc_u22, NULL AS gwt_cm_sav, NULL AS hdi_ix_sav, NULL AS hft_ix_s09, NULL AS hft_ix_s93, NULL AS hft_ix_u09, NULL AS hft_ix_u93, ccm.id, NULL AS inu_pc_slt, NULL AS inu_pc_smn, NULL AS inu_pc_smx, NULL AS inu_pc_ult, NULL AS inu_pc_umn, NULL AS inu_pc_umx, NULL AS ire_pc_sse, NULL AS ire_pc_use, NULL AS kar_pc_sse, NULL AS kar_pc_use, NULL AS lit_cl_smj, NULL AS lka_pc_sse, NULL AS lka_pc_use, NULL AS lkv_mc_usu, ccm.nextdownid, NULL AS nli_ix_sav, NULL AS nli_ix_uav, NULL AS pac_pc_sse, NULL AS pac_pc_use, ccm.perimeter, NULL AS pet_mm_s01, NULL AS pet_mm_s02, NULL AS pet_mm_s03, NULL AS pet_mm_s04, NULL AS pet_mm_s05, NULL AS pet_mm_s06, NULL AS pet_mm_s07, NULL AS pet_mm_s08, NULL AS pet_mm_s09, NULL AS pet_mm_s10, NULL AS pet_mm_s11, NULL AS pet_mm_s12, NULL AS pet_mm_syr, NULL AS pet_mm_uyr, NULL AS pnv_cl_smj, NULL AS pnv_pc_s01, NULL AS pnv_pc_s02, NULL AS pnv_pc_s03, NULL AS pnv_pc_s04, NULL AS pnv_pc_s05, NULL AS pnv_pc_s06, NULL AS pnv_pc_s07, NULL AS pnv_pc_s08, NULL AS pnv_pc_s09, NULL AS pnv_pc_s10, NULL AS pnv_pc_s11, NULL AS pnv_pc_s12, NULL AS pnv_pc_s13, NULL AS pnv_pc_s14, NULL AS pnv_pc_s15, NULL AS pnv_pc_u01, NULL AS pnv_pc_u02, NULL AS pnv_pc_u03, NULL AS pnv_pc_u04, NULL AS pnv_pc_u05, NULL AS pnv_pc_u06, NULL AS pnv_pc_u07, NULL AS pnv_pc_u08, NULL AS pnv_pc_u09, NULL AS pnv_pc_u10, NULL AS pnv_pc_u11, NULL AS pnv_pc_u12, NULL AS pnv_pc_u13, NULL AS pnv_pc_u14, NULL AS pnv_pc_u15, NULL AS pop_ct_ssu, NULL AS pop_ct_usu, NULL AS ppd_pk_sav, NULL AS ppd_pk_uav, NULL AS pre_mm_s01, NULL AS pre_mm_s02, NULL AS pre_mm_s03, NULL AS pre_mm_s04, NULL AS pre_mm_s05, NULL AS pre_mm_s06, NULL AS pre_mm_s07, NULL AS pre_mm_s08, NULL AS pre_mm_s09, NULL AS pre_mm_s10, NULL AS pre_mm_s11, NULL AS pre_mm_s12, NULL AS pre_mm_syr, NULL AS pre_mm_uyr, NULL AS prm_pc_sse, NULL AS prm_pc_use, NULL AS pst_pc_sse, NULL AS pst_pc_use, ccm.rain_max, ccm.rain_mean, ccm.rain_min, ccm.rain_std, NULL AS rdd_mk_sav, NULL AS rdd_mk_uav, NULL AS rev_mc_usu, NULL AS ria_ha_ssu, NULL AS ria_ha_usu, NULL AS riv_tc_ssu, NULL AS riv_tc_usu, NULL AS run_mm_syr, NULL AS sgr_dk_sav, ccm.shape_area, ccm.shape_leng, ccm.slope_max, ccm.slope_mean, ccm.slope_min, ccm.slope_std, NULL AS slp_dg_sav, NULL AS slp_dg_uav, NULL AS slt_pc_sav, NULL AS slt_pc_uav, NULL AS snd_pc_sav, NULL AS snd_pc_uav, NULL AS snw_pc_s01, NULL AS snw_pc_s02, NULL AS snw_pc_s03, NULL AS snw_pc_s04, NULL AS snw_pc_s05, NULL AS snw_pc_s06, NULL AS snw_pc_s07, NULL AS snw_pc_s08, NULL AS snw_pc_s09, NULL AS snw_pc_s10, NULL AS snw_pc_s11, NULL AS snw_pc_s12, NULL AS snw_pc_smx, NULL AS snw_pc_syr, NULL AS snw_pc_uyr, NULL AS soc_th_sav, NULL AS soc_th_uav, NULL AS source, ccm.strahler, NULL AS swc_pc_s01, NULL AS swc_pc_s02, NULL AS swc_pc_s03, NULL AS swc_pc_s04, NULL AS swc_pc_s05, NULL AS swc_pc_s06, NULL AS swc_pc_s07, NULL AS swc_pc_s08, NULL AS swc_pc_s09, NULL AS swc_pc_s10, NULL AS swc_pc_s11, NULL AS swc_pc_s12, NULL AS swc_pc_syr, NULL AS swc_pc_uyr, NULL AS tbi_cl_smj, NULL AS tec_cl_smj, ccm.temp_max, ccm.temp_mean, ccm.temp_min, ccm.temp_std, ccm.the_geom, NULL AS tmp_dc_s01, NULL AS tmp_dc_s02, NULL AS tmp_dc_s03, NULL AS tmp_dc_s04, NULL AS tmp_dc_s05, NULL AS tmp_dc_s06, NULL AS tmp_dc_s07, NULL AS tmp_dc_s08, NULL AS tmp_dc_s09, NULL AS tmp_dc_s10, NULL AS tmp_dc_s11, NULL AS tmp_dc_s12, NULL AS tmp_dc_smn, NULL AS tmp_dc_smx, NULL AS tmp_dc_syr, NULL AS tmp_dc_uyr, NULL AS ufid, NULL AS urb_pc_sse, NULL AS urb_pc_use, NULL AS wet_cl_smj, NULL AS wet_pc_s01, NULL AS wet_pc_s02, NULL AS wet_pc_s03, NULL AS wet_pc_s04, NULL AS wet_pc_s05, NULL AS wet_pc_s06, NULL AS wet_pc_s07, NULL AS wet_pc_s08, NULL AS wet_pc_s09, NULL AS wet_pc_sg1, NULL AS wet_pc_sg2, NULL AS wet_pc_u01, NULL AS wet_pc_u02, NULL AS wet_pc_u03, NULL AS wet_pc_u04, NULL AS wet_pc_u05, NULL AS wet_pc_u06, NULL AS wet_pc_u07, NULL AS wet_pc_u08, NULL AS wet_pc_u09, NULL AS wet_pc_ug1, NULL AS wet_pc_ug2, ccm.window, ccm.wso10_id, ccm.wso11_id, ccm.wso1_id, ccm.wso2_id, ccm.wso3_id, ccm.wso4_id, ccm.wso5_id, ccm.wso6_id, ccm.wso7_id, ccm.wso8_id, ccm.wso9_id, ccm.wso_id, ccm.x_centroid, ccm.x_inside_l, ccm.xmax_laea, ccm.xmin_laea, ccm.y_centroid, ccm.y_inside_l, ccm.ymax_laea, ccm.ymin_laea
	FROM ccm.catchments
	WHERE ccm.gid = 918732
UNION ALL
	SELECT 
	hydroa."COAST", hydroa."DIST_MAIN", hydroa."DIST_SINK", hydroa."ENDO", hydroa."HYBAS_ID", hydroa."MAIN_BAS", hydroa."NEXT_DOWN", hydroa."NEXT_SINK", hydroa."ORDER_", hydroa."PFAF_ID", hydroa."SORT", hydroa."SUB_AREA", hydroa."UP_AREA", hydroa.aet_mm_s01, hydroa.aet_mm_s02, hydroa.aet_mm_s03, hydroa.aet_mm_s04, hydroa.aet_mm_s05, hydroa.aet_mm_s06, hydroa.aet_mm_s07, hydroa.aet_mm_s08, hydroa.aet_mm_s09, hydroa.aet_mm_s10, hydroa.aet_mm_s11, hydroa.aet_mm_s12, hydroa.aet_mm_syr, hydroa.aet_mm_uyr, NULL AS area, NULL AS area_km2, hydroa.ari_ix_sav, hydroa.ari_ix_uav, hydroa.cls_cl_smj, hydroa.cly_pc_sav, hydroa.cly_pc_uav, hydroa.clz_cl_smj, hydroa.cmi_ix_s01, hydroa.cmi_ix_s02, hydroa.cmi_ix_s03, hydroa.cmi_ix_s04, hydroa.cmi_ix_s05, hydroa.cmi_ix_s06, hydroa.cmi_ix_s07, hydroa.cmi_ix_s08, hydroa.cmi_ix_s09, hydroa.cmi_ix_s10, hydroa.cmi_ix_s11, hydroa.cmi_ix_s12, hydroa.cmi_ix_syr, hydroa.cmi_ix_uyr, hydroa.crp_pc_sse, hydroa.crp_pc_use, hydroa.dis_m3_pmn, hydroa.dis_m3_pmx, hydroa.dis_m3_pyr, hydroa.dor_pc_pva, hydroa.ele_mt_sav, hydroa.ele_mt_smn, hydroa.ele_mt_smx, hydroa.ele_mt_uav, NULL AS elev_max, NULL AS elev_mean, NULL AS elev_min, NULL AS elev_std, hydroa.ero_kh_sav, hydroa.ero_kh_uav, NULL AS feature_co, hydroa.fec_cl_smj, hydroa.fmh_cl_smj, hydroa.for_pc_sse, hydroa.for_pc_use, hydroa.gad_id_smj, hydroa.gdp_ud_sav, hydroa.gdp_ud_ssu, hydroa.gdp_ud_usu, hydroa.geom, NULL AS gid, hydroa.gla_pc_sse, hydroa.gla_pc_use, hydroa.glc_cl_smj, hydroa.glc_pc_s01, hydroa.glc_pc_s02, hydroa.glc_pc_s03, hydroa.glc_pc_s04, hydroa.glc_pc_s05, hydroa.glc_pc_s06, hydroa.glc_pc_s07, hydroa.glc_pc_s08, hydroa.glc_pc_s09, hydroa.glc_pc_s10, hydroa.glc_pc_s11, hydroa.glc_pc_s12, hydroa.glc_pc_s13, hydroa.glc_pc_s14, hydroa.glc_pc_s15, hydroa.glc_pc_s16, hydroa.glc_pc_s17, hydroa.glc_pc_s18, hydroa.glc_pc_s19, hydroa.glc_pc_s20, hydroa.glc_pc_s21, hydroa.glc_pc_s22, hydroa.glc_pc_u01, hydroa.glc_pc_u02, hydroa.glc_pc_u03, hydroa.glc_pc_u04, hydroa.glc_pc_u05, hydroa.glc_pc_u06, hydroa.glc_pc_u07, hydroa.glc_pc_u08, hydroa.glc_pc_u09, hydroa.glc_pc_u10, hydroa.glc_pc_u11, hydroa.glc_pc_u12, hydroa.glc_pc_u13, hydroa.glc_pc_u14, hydroa.glc_pc_u15, hydroa.glc_pc_u16, hydroa.glc_pc_u17, hydroa.glc_pc_u18, hydroa.glc_pc_u19, hydroa.glc_pc_u20, hydroa.glc_pc_u21, hydroa.glc_pc_u22, hydroa.gwt_cm_sav, hydroa.hdi_ix_sav, hydroa.hft_ix_s09, hydroa.hft_ix_s93, hydroa.hft_ix_u09, hydroa.hft_ix_u93, NULL AS id, hydroa.inu_pc_slt, hydroa.inu_pc_smn, hydroa.inu_pc_smx, hydroa.inu_pc_ult, hydroa.inu_pc_umn, hydroa.inu_pc_umx, hydroa.ire_pc_sse, hydroa.ire_pc_use, hydroa.kar_pc_sse, hydroa.kar_pc_use, hydroa.lit_cl_smj, hydroa.lka_pc_sse, hydroa.lka_pc_use, hydroa.lkv_mc_usu, NULL AS nextdownid, hydroa.nli_ix_sav, hydroa.nli_ix_uav, hydroa.pac_pc_sse, hydroa.pac_pc_use, NULL AS perimeter, hydroa.pet_mm_s01, hydroa.pet_mm_s02, hydroa.pet_mm_s03, hydroa.pet_mm_s04, hydroa.pet_mm_s05, hydroa.pet_mm_s06, hydroa.pet_mm_s07, hydroa.pet_mm_s08, hydroa.pet_mm_s09, hydroa.pet_mm_s10, hydroa.pet_mm_s11, hydroa.pet_mm_s12, hydroa.pet_mm_syr, hydroa.pet_mm_uyr, hydroa.pnv_cl_smj, hydroa.pnv_pc_s01, hydroa.pnv_pc_s02, hydroa.pnv_pc_s03, hydroa.pnv_pc_s04, hydroa.pnv_pc_s05, hydroa.pnv_pc_s06, hydroa.pnv_pc_s07, hydroa.pnv_pc_s08, hydroa.pnv_pc_s09, hydroa.pnv_pc_s10, hydroa.pnv_pc_s11, hydroa.pnv_pc_s12, hydroa.pnv_pc_s13, hydroa.pnv_pc_s14, hydroa.pnv_pc_s15, hydroa.pnv_pc_u01, hydroa.pnv_pc_u02, hydroa.pnv_pc_u03, hydroa.pnv_pc_u04, hydroa.pnv_pc_u05, hydroa.pnv_pc_u06, hydroa.pnv_pc_u07, hydroa.pnv_pc_u08, hydroa.pnv_pc_u09, hydroa.pnv_pc_u10, hydroa.pnv_pc_u11, hydroa.pnv_pc_u12, hydroa.pnv_pc_u13, hydroa.pnv_pc_u14, hydroa.pnv_pc_u15, hydroa.pop_ct_ssu, hydroa.pop_ct_usu, hydroa.ppd_pk_sav, hydroa.ppd_pk_uav, hydroa.pre_mm_s01, hydroa.pre_mm_s02, hydroa.pre_mm_s03, hydroa.pre_mm_s04, hydroa.pre_mm_s05, hydroa.pre_mm_s06, hydroa.pre_mm_s07, hydroa.pre_mm_s08, hydroa.pre_mm_s09, hydroa.pre_mm_s10, hydroa.pre_mm_s11, hydroa.pre_mm_s12, hydroa.pre_mm_syr, hydroa.pre_mm_uyr, hydroa.prm_pc_sse, hydroa.prm_pc_use, hydroa.pst_pc_sse, hydroa.pst_pc_use, NULL AS rain_max, NULL AS rain_mean, NULL AS rain_min, NULL AS rain_std, hydroa.rdd_mk_sav, hydroa.rdd_mk_uav, hydroa.rev_mc_usu, hydroa.ria_ha_ssu, hydroa.ria_ha_usu, hydroa.riv_tc_ssu, hydroa.riv_tc_usu, hydroa.run_mm_syr, hydroa.sgr_dk_sav, NULL AS shape_area, NULL AS shape_leng, NULL AS slope_max, NULL AS slope_mean, NULL AS slope_min, NULL AS slope_std, hydroa.slp_dg_sav, hydroa.slp_dg_uav, hydroa.slt_pc_sav, hydroa.slt_pc_uav, hydroa.snd_pc_sav, hydroa.snd_pc_uav, hydroa.snw_pc_s01, hydroa.snw_pc_s02, hydroa.snw_pc_s03, hydroa.snw_pc_s04, hydroa.snw_pc_s05, hydroa.snw_pc_s06, hydroa.snw_pc_s07, hydroa.snw_pc_s08, hydroa.snw_pc_s09, hydroa.snw_pc_s10, hydroa.snw_pc_s11, hydroa.snw_pc_s12, hydroa.snw_pc_smx, hydroa.snw_pc_syr, hydroa.snw_pc_uyr, hydroa.soc_th_sav, hydroa.soc_th_uav, hydroa.source, NULL AS strahler, hydroa.swc_pc_s01, hydroa.swc_pc_s02, hydroa.swc_pc_s03, hydroa.swc_pc_s04, hydroa.swc_pc_s05, hydroa.swc_pc_s06, hydroa.swc_pc_s07, hydroa.swc_pc_s08, hydroa.swc_pc_s09, hydroa.swc_pc_s10, hydroa.swc_pc_s11, hydroa.swc_pc_s12, hydroa.swc_pc_syr, hydroa.swc_pc_uyr, hydroa.tbi_cl_smj, hydroa.tec_cl_smj, NULL AS temp_max, NULL AS temp_mean, NULL AS temp_min, NULL AS temp_std, NULL AS the_geom, hydroa.tmp_dc_s01, hydroa.tmp_dc_s02, hydroa.tmp_dc_s03, hydroa.tmp_dc_s04, hydroa.tmp_dc_s05, hydroa.tmp_dc_s06, hydroa.tmp_dc_s07, hydroa.tmp_dc_s08, hydroa.tmp_dc_s09, hydroa.tmp_dc_s10, hydroa.tmp_dc_s11, hydroa.tmp_dc_s12, hydroa.tmp_dc_smn, hydroa.tmp_dc_smx, hydroa.tmp_dc_syr, hydroa.tmp_dc_uyr, hydroa.ufid, hydroa.urb_pc_sse, hydroa.urb_pc_use, hydroa.wet_cl_smj, hydroa.wet_pc_s01, hydroa.wet_pc_s02, hydroa.wet_pc_s03, hydroa.wet_pc_s04, hydroa.wet_pc_s05, hydroa.wet_pc_s06, hydroa.wet_pc_s07, hydroa.wet_pc_s08, hydroa.wet_pc_s09, hydroa.wet_pc_sg1, hydroa.wet_pc_sg2, hydroa.wet_pc_u01, hydroa.wet_pc_u02, hydroa.wet_pc_u03, hydroa.wet_pc_u04, hydroa.wet_pc_u05, hydroa.wet_pc_u06, hydroa.wet_pc_u07, hydroa.wet_pc_u08, hydroa.wet_pc_u09, hydroa.wet_pc_ug1, hydroa.wet_pc_ug2, NULL AS window, NULL AS wso10_id, NULL AS wso11_id, NULL AS wso1_id, NULL AS wso2_id, NULL AS wso3_id, NULL AS wso4_id, NULL AS wso5_id, NULL AS wso6_id, NULL AS wso7_id, NULL AS wso8_id, NULL AS wso9_id, NULL AS wso_id, NULL AS x_centroid, NULL AS x_inside_l, NULL AS xmax_laea, NULL AS xmin_laea, NULL AS y_centroid, NULL AS y_inside_l, NULL AS ymax_laea, NULL AS ymin_laea
	FROM hydroa.catchments
	WHERE hydroa."HYBAS_ID" = 2120781430;


-- gathering geometry into one column
UPDATE hydroa.merging 
	SET geom = COALESCE(geom, the_geom);
ALTER TABLE hydroa.merging 
	DROP COLUMN the_geom;
	
CREATE SCHEMA tempo;

CREATE TABLE tempo.border_basins AS(
WITH ccm_contour AS (
SELECT * FROM ccm21.seaoutlets WHERE "window" = 2017 AND sea_cd=4)

-- we only want an intersection on the edge
SELECT hc.* FROM ccm_contour cc JOIN
hydroa.catchments hc 
ON st_intersects(hc.geom, cc.geom)
AND NOT st_contains(hc.geom, cc.geom)
);

-- This table cuts hydroatlas basins according to the border with ccm,
-- and extracts single geometry polygons

DROP TABLE IF EXISTS tempo.border_basins_cut;
CREATE TABLE tempo.border_basins_cut AS(
WITH ccm_contour AS (
SELECT * FROM ccm21.seaoutlets WHERE "window" = 2017 AND sea_cd=4),
ccm_difference AS(
SELECT st_difference(bb.geom,cc.geom) geom, 
bb."HYBAS_ID" AS hybas_id FROM tempo.border_basins bb, ccm_contour cc)
SELECT (sub.p_geom).geom AS geom, (sub.p_geom).path AS PATH, hybas_id
FROM (SELECT (ST_Dump(ccm_difference.geom)) AS p_geom , hybas_id FROM ccm_difference) sub
); --267

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
); --58

-- Putting the limit at 10 %
CREATE TABLE tempo.smallpieces AS (
SELECT border_basins_cut.* FROM tempo.border_basins_cut JOIN tempo.proportion_cut
ON proportion_cut.hybas_id = border_basins_cut.hybas_id
WHERE proportion_cut < 0.1);




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