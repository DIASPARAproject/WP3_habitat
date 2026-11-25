
-- commenting tables
--SELECT * FROM riveratlas.riveratlas_v10
COMMENT ON TABLE riveratlas.riveratlas_v10 IS 'Table of river network data from HydroSHEDS';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hyriv_id IS 'Identifier of the segment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.next_down IS 'Identifier of the next downstream river segment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.main_riv IS 'Identifier of the most downstream river segment of the river basin';
COMMENT ON COLUMN riveratlas.riveratlas_v10.length_km IS 'Length of the river segment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dist_dn_km IS 'Distance from the most downstream part of the segment to the most downstream part of the river network';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dist_up_km IS 'Distance from the most downstream part of the segment to the most upstream part of the river network';
COMMENT ON COLUMN riveratlas.riveratlas_v10.catch_skm IS '';
COMMENT ON COLUMN riveratlas.riveratlas_v10.upland_skm IS '';
COMMENT ON COLUMN riveratlas.riveratlas_v10.endorheic IS 'Indicator for presence (1) or abscence (0) of a endorheic basin downstream of the segment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dis_av_cms IS 'Average long-term discharge estimate for river reach, in m3 s-1';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ord_stra IS 'Strahler rank';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ord_clas IS 'Classic stream rank';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ord_flow IS 'River order using average river discharge';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hybas_l12 IS 'Identifier of the HydroBASINS river basin level 12';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dis_m3_pyr IS 'Annual average of the natural discharge in m3';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dis_m3_pmn IS 'Annual minimum of the natural discharge in m3';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dis_m3_pmx IS 'Annual maximum of the natural discharge in m3';
COMMENT ON COLUMN riveratlas.riveratlas_v10.run_mm_cyr IS 'Annual average land surface runoff in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_cmn IS 'Annual minimum Inundation Extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_umn IS 'Annual minimum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_cmx IS 'Annual maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_umx IS 'Annual maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_clt IS 'Long-term maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.inu_pc_ult IS 'Long-term maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.lka_pc_cse IS 'Limnicity (Percent Lake Area) spatial extent (%) in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.lka_pc_use IS 'Limnicity (Percent Lake Area) spatial extent (%) in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.lkv_mc_usu IS 'Sum of lake volume in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.rev_mc_usu IS 'Sum of reservoir volume in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.dor_pc_pva IS 'Degree of regulation at pour point of river reach';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ria_ha_csu IS 'Sum of river area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ria_ha_usu IS 'Sum of river area in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.riv_tc_csu IS 'Sum of river volume in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.riv_tc_usu IS 'Sum of river volume in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gwt_cm_cav IS 'Average Groundwater Table Depth in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ele_mt_cav IS 'Average elevation in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ele_mt_uav IS 'Average elevation in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ele_mt_cmn IS 'Minimum elevation in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ele_mt_cmx IS 'Maximum elevation in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.slp_dg_cav IS 'Terrain slope in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.slp_dg_uav IS 'Terrain slope in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.sgr_dk_rav IS 'Average stream gradient along reach segment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.clz_cl_cmj IS 'Spatial majority of climate zone in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cls_cl_cmj IS 'Spatial majority of climate strata in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_cyr IS 'Annual average of air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_uyr IS 'Annual average of air temperature in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_cmn IS 'Annual minimum of air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_cmx IS 'Annual maximum of air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c01 IS 'Average January air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c02 IS 'Average February air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c03 IS 'Average March air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c04 IS 'Average April air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c05 IS 'Average May air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c06 IS 'Average June air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c07 IS 'Average July air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c08 IS 'Average August air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c09 IS 'Average September air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c10 IS 'Average October air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c11 IS 'Average November air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tmp_dc_c12 IS 'Average December air temperature in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_cyr IS 'Annual average of precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_uyr IS 'Annual average of precipitation in total watershed upstream in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c01 IS 'Average January precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c02 IS 'Average February precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c03 IS 'Average March precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c04 IS 'Average April precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c05 IS 'Average May precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c06 IS 'Average June precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c07 IS 'Average July precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c08 IS 'Average August precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c09 IS 'Average September precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c10 IS 'Average October precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c11 IS 'Average November precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pre_mm_c12 IS 'Average December precipitation in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_cyr IS 'Annual average of potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_uyr IS 'Annual average of potential evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c01 IS 'January potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c02 IS 'February potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c03 IS 'March potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c04 IS 'April potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c05 IS 'May potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c06 IS 'June potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c07 IS 'July potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c08 IS 'August potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c09 IS 'September potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c10 IS 'October potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c11 IS 'November potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pet_mm_c12 IS 'December potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_cyr IS 'Annual average of actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_uyr IS 'Annual average of actual evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c01 IS 'January actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c02 IS 'February actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c03 IS 'March actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c04 IS 'April actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c05 IS 'May actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c06 IS 'June actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c07 IS 'July actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c08 IS 'August actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c09 IS 'September actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c10 IS 'October actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c11 IS 'November actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.aet_mm_c12 IS 'December actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ari_ix_cav IS 'Average global aridity index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ari_ix_uav IS 'Average global aridity index in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_cyr IS 'Annual average climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_uyr IS 'Annual average climate moisture index in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c01 IS 'January climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c02 IS 'February climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c03 IS 'March climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c04 IS 'April climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c05 IS 'May climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c06 IS 'June climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c07 IS 'July climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c08 IS 'August climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c09 IS 'September climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c10 IS 'October climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c11 IS 'November climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cmi_ix_c12 IS 'December climate moisture index in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_cyr IS 'Annual average snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_uyr IS 'Annual average snow cover extent in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_cmx IS 'Annual maximum snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c01 IS 'January snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c02 IS 'Fevruary snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c03 IS 'March snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c04 IS 'April snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c05 IS 'May snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c06 IS 'June snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c07 IS 'July snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c08 IS 'August snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c09 IS 'September snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c10 IS 'October snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c11 IS 'November snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snw_pc_c12 IS 'December snow cover extent in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_cl_cmj IS 'Spatial majority of land cover class in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c01 IS 'Land Cover Extent class 1 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c02 IS 'Land Cover Extent class 2 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c03 IS 'Land Cover Extent class 3 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c04 IS 'Land Cover Extent class 4 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c05 IS 'Land Cover Extent class 5 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c06 IS 'Land Cover Extent class 6 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c07 IS 'Land Cover Extent class 7 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c08 IS 'Land Cover Extent class 8 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c09 IS 'Land Cover Extent class 9 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c10 IS 'Land Cover Extent class 10 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c11 IS 'Land Cover Extent class 11 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c12 IS 'Land Cover Extent class 12 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c13 IS 'Land Cover Extent class 13 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c14 IS 'Land Cover Extent class 14 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c15 IS 'Land Cover Extent class 15 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c16 IS 'Land Cover Extent class 16 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c17 IS 'Land Cover Extent class 17 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c18 IS 'Land Cover Extent class 18 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c19 IS 'Land Cover Extent class 19 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c20 IS 'Land Cover Extent class 20 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c21 IS 'Land Cover Extent class 21 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_c22 IS 'Land Cover Extent class 22 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u01 IS 'Land Cover Extent class 1 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u02 IS 'Land Cover Extent class 2 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u03 IS 'Land Cover Extent class 3 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u04 IS 'Land Cover Extent class 4 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u05 IS 'Land Cover Extent class 5 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u06 IS 'Land Cover Extent class 6 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u07 IS 'Land Cover Extent class 7 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u08 IS 'Land Cover Extent class 8 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u09 IS 'Land Cover Extent class 9 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u10 IS 'Land Cover Extent class 10 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u11 IS 'Land Cover Extent class 11 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u12 IS 'Land Cover Extent class 12 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u13 IS 'Land Cover Extent class 13 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u14 IS 'Land Cover Extent class 14 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u15 IS 'Land Cover Extent class 15 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u16 IS 'Land Cover Extent class 16 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u17 IS 'Land Cover Extent class 17 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u18 IS 'Land Cover Extent class 18 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u19 IS 'Land Cover Extent class 19 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u20 IS 'Land Cover Extent class 20 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u21 IS 'Land Cover Extent class 21 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.glc_pc_u22 IS 'Land Cover Extent class 22 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_cl_cmj IS 'Spatial majority of potential natural vegetation classes in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c01 IS 'Potential natural vegetation extent class 1 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c02 IS 'Potential natural vegetation extent class 2 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c03 IS 'Potential natural vegetation extent class 3 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c04 IS 'Potential natural vegetation extent class 4 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c05 IS 'Potential natural vegetation extent class 5 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c06 IS 'Potential natural vegetation extent class 6 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c07 IS 'Potential natural vegetation extent class 7 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c08 IS 'Potential natural vegetation extent class 8 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c09 IS 'Potential natural vegetation extent class 9 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c10 IS 'Potential natural vegetation extent class 10 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c11 IS 'Potential natural vegetation extent class 11 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c12 IS 'Potential natural vegetation extent class 12 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c13 IS 'Potential natural vegetation extent class 13 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c14 IS 'Potential natural vegetation extent class 14 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_c15 IS 'Potential natural vegetation extent class 15 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u01 IS 'Potential natural vegetation extent class 1 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u02 IS 'Potential natural vegetation extent class 2 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u03 IS 'Potential natural vegetation extent class 3 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u04 IS 'Potential natural vegetation extent class 4 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u05 IS 'Potential natural vegetation extent class 5 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u06 IS 'Potential natural vegetation extent class 6 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u07 IS 'Potential natural vegetation extent class 7 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u08 IS 'Potential natural vegetation extent class 8 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u09 IS 'Potential natural vegetation extent class 9 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u10 IS 'Potential natural vegetation extent class 10 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u11 IS 'Potential natural vegetation extent class 11 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u12 IS 'Potential natural vegetation extent class 12 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u13 IS 'Potential natural vegetation extent class 13 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u14 IS 'Potential natural vegetation extent class 14 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pnv_pc_u15 IS 'Potential natural vegetation extent class 15 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_cl_cmj IS 'Spatial majority wetland class in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_cg1 IS 'Wetland extent class group 1 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_ug1 IS 'Wetland extent class group 1 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_cg2 IS 'Wetland extent class group 2 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_ug2 IS 'Wetland extent class group 2 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c01 IS 'Wetland extent class 1 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c02 IS 'Wetland extent class 2 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c03 IS 'Wetland extent class 3 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c04 IS 'Wetland extent class 4 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c05 IS 'Wetland extent class 5 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c06 IS 'Wetland extent class 6 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c07 IS 'Wetland extent class 7 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c08 IS 'Wetland extent class 8 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_c09 IS 'Wetland extent class 9 in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u01 IS 'Wetland extent class 1 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u02 IS 'Wetland extent class 2 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u03 IS 'Wetland extent class 3 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u04 IS 'Wetland extent class 4 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u05 IS 'Wetland extent class 5 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u06 IS 'Wetland extent class 6 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u07 IS 'Wetland extent class 7 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u08 IS 'Wetland extent class 8 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.wet_pc_u09 IS 'Wetland extent class 9 in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.for_pc_cse IS 'Spatial extent (%) of forest cover in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.for_pc_use IS 'Spatial extent (%) of forest cover in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.crp_pc_cse IS 'Spatial extent (%) of cropland in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.crp_pc_use IS 'Spatial extent (%) of cropland in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pst_pc_cse IS 'Spatial extent (%) of pasture in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pst_pc_use IS 'Spatial extent (%) of pasture in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ire_pc_cse IS 'Spatial extent (%) of irrigated area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ire_pc_use IS 'Spatial extent (%) of irrigated area in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gla_pc_cse IS 'Spatial extent (%) of glacier in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gla_pc_use IS 'Spatial extent (%) of glacier in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.prm_pc_cse IS 'Spatial extent (%) of permafrost in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.prm_pc_use IS 'Spatial extent (%) of permafrost in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pac_pc_cse IS 'Spatial extent (%) of protected area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pac_pc_use IS 'Spatial extent (%) of protected area in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tbi_cl_cmj IS 'Spatial majority of terrestrial biomes in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.tec_cl_cmj IS 'Spatial majority of terrestrial ecoregions in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.fmh_cl_cmj IS 'Spatial majority of freshwater major habitat types in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.fec_cl_cmj IS 'Spatial majority of freshwater ecoregions in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cly_pc_cav IS 'Average clay fraction in soil in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.cly_pc_uav IS 'Average clay fraction in soil in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.slt_pc_cav IS 'Average silt fraction in soil in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.slt_pc_uav IS 'Average silt fraction in soil in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snd_pc_cav IS 'Average sand fraction in soil in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.snd_pc_uav IS 'Average sand fraction in soil in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.soc_th_cav IS 'Average organic carbon content in soil in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.soc_th_uav IS 'Average organic carbon content fraction in soil in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_cyr IS 'Annual average soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_uyr IS 'Annual average soil water content in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c01 IS 'January soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c02 IS 'February soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c03 IS 'March soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c04 IS 'April soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c05 IS 'May soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c06 IS 'June soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c07 IS 'July soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c08 IS 'August soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c09 IS 'September soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c10 IS 'October soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c11 IS 'November soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.swc_pc_c12 IS 'December soil water content in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.lit_cl_cmj IS 'Spatial majority of lithological classes in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.kar_pc_cse IS 'Spatial extent (%) of Karst area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.kar_pc_use IS 'Spatial extent (%) of Karst area in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ero_kh_cav IS 'Average soil erosion in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ero_kh_uav IS 'Average soil erosion in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pop_ct_csu IS 'Population count in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.pop_ct_usu IS 'Population count in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ppd_pk_cav IS 'Average population density in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.ppd_pk_uav IS 'Average population density in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.urb_pc_cse IS 'Spatial extent (%) of urban area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.urb_pc_use IS 'Spatial extent (%) of urban area in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.nli_ix_cav IS 'Average nighttime lights in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.nli_ix_uav IS 'Average nighttime lights in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.rdd_mk_cav IS 'Average road density in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.rdd_mk_uav IS 'Average road density in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hft_ix_c93 IS 'Human foorprint in reach catchment in 1993';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hft_ix_u93 IS 'Human footprint in total watershed upstream in 1993';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hft_ix_c09 IS 'Human foorprint in reach catchment in 2009';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hft_ix_u09 IS 'Human footprint in total watershed upstream in 2009';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gad_id_cmj IS 'Spatial majority of global administrative area in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gdp_ud_cav IS 'Average gross domestic product in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gdp_ud_csu IS 'Sum of gross domestic product in reach catchment';
COMMENT ON COLUMN riveratlas.riveratlas_v10.gdp_ud_usu IS 'Sum of gross domestic product in total watershed upstream';
COMMENT ON COLUMN riveratlas.riveratlas_v10.hdi_ix_cav IS 'Average human development index in reach catchment';
--COMMENT ON COLUMN riveratlas.riveratlas_v10."source" IS '';
--COMMENT ON COLUMN riveratlas.riveratlas_v10.ufid IS '';


--SELECT * FROM hydroa.catchments;
COMMENT ON TABLE hydroa.catchments IS 'Table of HydroATLAS basins level 12';
COMMENT ON COLUMN hydroa.catchments."HYBAS_ID" IS 'Identifier of the basin';
COMMENT ON COLUMN hydroa.catchments.next_down IS 'Identifier of the next downstream basin';
COMMENT ON COLUMN hydroa.catchments."NEXT_SINK" IS 'Identifier of the next downstream sink, either endorheic sink or most downstream basin';
COMMENT ON COLUMN hydroa.catchments."MAIN_BAS" IS 'Identifier of the most downstream basin';
COMMENT ON COLUMN hydroa.catchments."DIST_SINK" IS 'Distance from basin outlet to the next downstream sink';
COMMENT ON COLUMN hydroa.catchments."DIST_MAIN" IS 'Distance from basin outlet to the most downstream sink';
COMMENT ON COLUMN hydroa.catchments."SUB_AREA" IS 'Area of the basin in km2';
COMMENT ON COLUMN hydroa.catchments."UP_AREA" IS 'Total upstream area in km2';
COMMENT ON COLUMN hydroa.catchments."PFAF_ID" IS 'Pfafstetter code';
COMMENT ON COLUMN hydroa.catchments."ENDO" IS 'Indicator for presence (1) or abscence (0) of a endorheic basin downstream of the basin. 2 if sink of endorheic basin';
--COMMENT ON COLUMN hydroa.catchments."COAST" IS ''; TODO
COMMENT ON COLUMN hydroa.catchments."ORDER_" IS 'Classic stream order';
COMMENT ON COLUMN hydroa.catchments."SORT" IS 'Shapefile storage order';
COMMENT ON COLUMN hydroa.catchments.dis_m3_pyr IS 'Annual average of the natural discharge in m3';
COMMENT ON COLUMN hydroa.catchments.dis_m3_pmn IS 'Annual minimum of the natural discharge in m3';
COMMENT ON COLUMN hydroa.catchments.dis_m3_pmx IS 'Annual maximum of the natural discharge in m3';
COMMENT ON COLUMN hydroa.catchments.run_mm_cyr IS 'Annual average land surface runoff in reach catchment';
COMMENT ON COLUMN hydroa.catchments.inu_pc_cmn IS 'Annual minimum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.inu_pc_umn IS 'Annual minimum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.inu_pc_cmx IS 'Annual maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.inu_pc_umx IS 'Annual maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.inu_pc_clt IS 'Long-term maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.inu_pc_ult IS 'Long-term maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.lka_pc_cse IS 'Limnicity (Percent Lake Area) spatial extent (%) in reach catchment';
COMMENT ON COLUMN hydroa.catchments.lka_pc_use IS 'Limnicity (Percent Lake Area) spatial extent (%) in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.lkv_mc_usu IS 'Sum of lake volume in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.rev_mc_usu IS 'Sum of reservoir volume in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.dor_pc_pva IS 'Degree of regulation at pour point of river reach';
COMMENT ON COLUMN hydroa.catchments.ria_ha_csu IS 'Sum of river area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ria_ha_usu IS 'Sum of river area in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.riv_tc_csu IS 'Sum of river volume in reach catchment';
COMMENT ON COLUMN hydroa.catchments.riv_tc_usu IS 'Sum of river volume in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.gwt_cm_cav IS 'Average Groundwater Table Depth in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ele_mt_cav IS 'Average elevation in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ele_mt_uav IS 'Average elevation in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.ele_mt_cmn IS 'Minimum elevation in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ele_mt_cmx IS 'Maximum elevation in reach catchment';
COMMENT ON COLUMN hydroa.catchments.slp_dg_cav IS 'Terrain slope in reach catchment';
COMMENT ON COLUMN hydroa.catchments.slp_dg_uav IS 'Terrain slope in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.sgr_dk_rav IS 'Average stream gradient along reach segment';
COMMENT ON COLUMN hydroa.catchments.clz_cl_cmj IS 'Spatial majority of climate zone in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cls_cl_cmj IS 'Spatial majority of climate strata in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_cyr IS 'Annual average of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_uyr IS 'Annual average of air temperature in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_cmn IS 'Annual minimum of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_cmx IS 'Annual maximum of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c01 IS 'Average January air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c02 IS 'Average February air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c03 IS 'Average March air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c04 IS 'Average April air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c05 IS 'Average May air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c06 IS 'Average June air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c07 IS 'Average July air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c08 IS 'Average August air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c09 IS 'Average September air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c10 IS 'Average October air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c11 IS 'Average November air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tmp_dc_c12 IS 'Average December air temperature in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pre_mm_cyr IS 'Annual average of precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_uyr IS 'Annual average of precipitation in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c01 IS 'Average January precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c02 IS 'Average February precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c03 IS 'Average March precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c04 IS 'Average April precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c05 IS 'Average May precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c06 IS 'Average June precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c07 IS 'Average July precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c08 IS 'Average August precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c09 IS 'Average September precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c10 IS 'Average October precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c11 IS 'Average November precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pre_mm_c12 IS 'Average December precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_cyr IS 'Annual average of potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_uyr IS 'Annual average of potential evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c01 IS 'January potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c02 IS 'February potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c03 IS 'March potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c04 IS 'April potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c05 IS 'May potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c06 IS 'June potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c07 IS 'July potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c08 IS 'August potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c09 IS 'September potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c10 IS 'October potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c11 IS 'November potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.pet_mm_c12 IS 'December potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_cyr IS 'Annual average of actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_uyr IS 'Annual average of actual evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c01 IS 'January actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c02 IS 'February actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c03 IS 'March actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c04 IS 'April actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c05 IS 'May actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c06 IS 'June actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c07 IS 'July actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c08 IS 'August actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c09 IS 'September actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c10 IS 'October actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c11 IS 'November actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.aet_mm_c12 IS 'December actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.catchments.ari_ix_cav IS 'Average global aridity index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ari_ix_uav IS 'Average global aridity index in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_cyr IS 'Annual average climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_uyr IS 'Annual average climate moisture index in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c01 IS 'January climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c02 IS 'February climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c03 IS 'March climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c04 IS 'April climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c05 IS 'May climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c06 IS 'June climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c07 IS 'July climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c08 IS 'August climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c09 IS 'September climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c10 IS 'October climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c11 IS 'November climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cmi_ix_c12 IS 'December climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_cyr IS 'Annual average snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_uyr IS 'Annual average snow cover extent in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.snw_pc_cmx IS 'Annual maximum snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c01 IS 'January snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c02 IS 'Fevruary snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c03 IS 'March snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c04 IS 'April snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c05 IS 'May snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c06 IS 'June snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c07 IS 'July snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c08 IS 'August snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c09 IS 'September snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c10 IS 'October snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c11 IS 'November snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snw_pc_c12 IS 'December snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_cl_cmj IS 'Spatial majority of land cover class in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c01 IS 'Land Cover Extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c02 IS 'Land Cover Extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c03 IS 'Land Cover Extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c04 IS 'Land Cover Extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c05 IS 'Land Cover Extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c06 IS 'Land Cover Extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c07 IS 'Land Cover Extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c08 IS 'Land Cover Extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c09 IS 'Land Cover Extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c10 IS 'Land Cover Extent class 10 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c11 IS 'Land Cover Extent class 11 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c12 IS 'Land Cover Extent class 12 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c13 IS 'Land Cover Extent class 13 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c14 IS 'Land Cover Extent class 14 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c15 IS 'Land Cover Extent class 15 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c16 IS 'Land Cover Extent class 16 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c17 IS 'Land Cover Extent class 17 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c18 IS 'Land Cover Extent class 18 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c19 IS 'Land Cover Extent class 19 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c20 IS 'Land Cover Extent class 20 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c21 IS 'Land Cover Extent class 21 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_c22 IS 'Land Cover Extent class 22 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u01 IS 'Land Cover Extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u02 IS 'Land Cover Extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u03 IS 'Land Cover Extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u04 IS 'Land Cover Extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u05 IS 'Land Cover Extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u06 IS 'Land Cover Extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u07 IS 'Land Cover Extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u08 IS 'Land Cover Extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u09 IS 'Land Cover Extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u10 IS 'Land Cover Extent class 10 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u11 IS 'Land Cover Extent class 11 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u12 IS 'Land Cover Extent class 12 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u13 IS 'Land Cover Extent class 13 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u14 IS 'Land Cover Extent class 14 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u15 IS 'Land Cover Extent class 15 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u16 IS 'Land Cover Extent class 16 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u17 IS 'Land Cover Extent class 17 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u18 IS 'Land Cover Extent class 18 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u19 IS 'Land Cover Extent class 19 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u20 IS 'Land Cover Extent class 20 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u21 IS 'Land Cover Extent class 21 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.glc_pc_u22 IS 'Land Cover Extent class 22 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_cl_cmj IS 'Spatial majority of potential natural vegetation classes in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c01 IS 'Potential natural vegetation extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c02 IS 'Potential natural vegetation extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c03 IS 'Potential natural vegetation extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c04 IS 'Potential natural vegetation extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c05 IS 'Potential natural vegetation extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c06 IS 'Potential natural vegetation extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c07 IS 'Potential natural vegetation extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c08 IS 'Potential natural vegetation extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c09 IS 'Potential natural vegetation extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c10 IS 'Potential natural vegetation extent class 10 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c11 IS 'Potential natural vegetation extent class 11 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c12 IS 'Potential natural vegetation extent class 12 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c13 IS 'Potential natural vegetation extent class 13 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c14 IS 'Potential natural vegetation extent class 14 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_c15 IS 'Potential natural vegetation extent class 15 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u01 IS 'Potential natural vegetation extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u02 IS 'Potential natural vegetation extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u03 IS 'Potential natural vegetation extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u04 IS 'Potential natural vegetation extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u05 IS 'Potential natural vegetation extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u06 IS 'Potential natural vegetation extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u07 IS 'Potential natural vegetation extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u08 IS 'Potential natural vegetation extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u09 IS 'Potential natural vegetation extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u10 IS 'Potential natural vegetation extent class 10 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u11 IS 'Potential natural vegetation extent class 11 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u12 IS 'Potential natural vegetation extent class 12 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u13 IS 'Potential natural vegetation extent class 13 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u14 IS 'Potential natural vegetation extent class 14 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pnv_pc_u15 IS 'Potential natural vegetation extent class 15 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_cl_cmj IS 'Spatial majority wetland class in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_cg1 IS 'Wetland extent class group 1 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_ug1 IS 'Wetland extent class group 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_cg2 IS 'Wetland extent class group 2 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_ug2 IS 'Wetland extent class group 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c01 IS 'Wetland extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c02 IS 'Wetland extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c03 IS 'Wetland extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c04 IS 'Wetland extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c05 IS 'Wetland extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c06 IS 'Wetland extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c07 IS 'Wetland extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c08 IS 'Wetland extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_c09 IS 'Wetland extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u01 IS 'Wetland extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u02 IS 'Wetland extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u03 IS 'Wetland extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u04 IS 'Wetland extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u05 IS 'Wetland extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u06 IS 'Wetland extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u07 IS 'Wetland extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u08 IS 'Wetland extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.wet_pc_u09 IS 'Wetland extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.for_pc_cse IS 'Spatial extent (%) of forest cover in reach catchment';
COMMENT ON COLUMN hydroa.catchments.for_pc_use IS 'Spatial extent (%) of forest cover in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.crp_pc_cse IS 'Spatial extent (%) of cropland in reach catchment';
COMMENT ON COLUMN hydroa.catchments.crp_pc_use IS 'Spatial extent (%) of cropland in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pst_pc_cse IS 'Spatial extent (%) of pasture in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pst_pc_use IS 'Spatial extent (%) of pasture in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.ire_pc_cse IS 'Spatial extent (%) of irrigated area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ire_pc_use IS 'Spatial extent (%) of irrigated area in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.gla_pc_cse IS 'Spatial extent (%) of glacier in reach catchment';
COMMENT ON COLUMN hydroa.catchments.gla_pc_use IS 'Spatial extent (%) of glacier in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.prm_pc_cse IS 'Spatial extent (%) of permafrost in reach catchment';
COMMENT ON COLUMN hydroa.catchments.prm_pc_use IS 'Spatial extent (%) of permafrost in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pac_pc_cse IS 'Spatial extent (%) of protected area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pac_pc_use IS 'Spatial extent (%) of protected area in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.tbi_cl_cmj IS 'Spatial majority of terrestrial biomes in reach catchment';
COMMENT ON COLUMN hydroa.catchments.tec_cl_cmj IS 'Spatial majority of terrestrial ecoregions in reach catchment';
COMMENT ON COLUMN hydroa.catchments.fmh_cl_cmj IS 'Spatial majority of freshwater major habitat types in reach catchment';
COMMENT ON COLUMN hydroa.catchments.fec_cl_cmj IS 'Spatial majority of freshwater ecoregions in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cly_pc_cav IS 'Average clay fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.catchments.cly_pc_uav IS 'Average clay fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.slt_pc_cav IS 'Average silt fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.catchments.slt_pc_uav IS 'Average silt fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.snd_pc_cav IS 'Average sand fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.catchments.snd_pc_uav IS 'Average sand fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.soc_th_cav IS 'Average organic carbon content in soil in reach catchment';
COMMENT ON COLUMN hydroa.catchments.soc_th_uav IS 'Average organic carbon content fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.swc_pc_cyr IS 'Annual average soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_uyr IS 'Annual average soil water content in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c01 IS 'January soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c02 IS 'February soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c03 IS 'March soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c04 IS 'April soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c05 IS 'May soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c06 IS 'June soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c07 IS 'July soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c08 IS 'August soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c09 IS 'September soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c10 IS 'October soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c11 IS 'November soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.swc_pc_c12 IS 'December soil water content in reach catchment';
COMMENT ON COLUMN hydroa.catchments.lit_cl_cmj IS 'Spatial majority of lithological classes in reach catchment';
COMMENT ON COLUMN hydroa.catchments.kar_pc_cse IS 'Spatial extent (%) of Karst area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.kar_pc_use IS 'Spatial extent (%) of Karst area in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.ero_kh_cav IS 'Average soil erosion in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ero_kh_uav IS 'Average soil erosion in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.pop_ct_csu IS 'Population count in reach catchment';
COMMENT ON COLUMN hydroa.catchments.pop_ct_usu IS 'Population count in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.ppd_pk_cav IS 'Average population density in reach catchment';
COMMENT ON COLUMN hydroa.catchments.ppd_pk_uav IS 'Average population density in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.urb_pc_cse IS 'Spatial extent (%) of urban area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.urb_pc_use IS 'Spatial extent (%) of urban area in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.nli_ix_cav IS 'Average nighttime lights in reach catchment';
COMMENT ON COLUMN hydroa.catchments.nli_ix_uav IS 'Average nighttime lights in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.rdd_mk_cav IS 'Average road density in reach catchment';
COMMENT ON COLUMN hydroa.catchments.rdd_mk_uav IS 'Average road density in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.hft_ix_c93 IS 'Human foorprint in reach catchment in 1993';
COMMENT ON COLUMN hydroa.catchments.hft_ix_u93 IS 'Human footprint in total watershed upstream in 1993';
COMMENT ON COLUMN hydroa.catchments.hft_ix_c09 IS 'Human foorprint in reach catchment in 2009';
COMMENT ON COLUMN hydroa.catchments.hft_ix_u09 IS 'Human footprint in total watershed upstream in 2009';
COMMENT ON COLUMN hydroa.catchments.gad_id_cmj IS 'Spatial majority of global administrative area in reach catchment';
COMMENT ON COLUMN hydroa.catchments.gdp_ud_cav IS 'Average gross domestic product in reach catchment';
COMMENT ON COLUMN hydroa.catchments.gdp_ud_csu IS 'Sum of gross domestic product in reach catchment';
COMMENT ON COLUMN hydroa.catchments.gdp_ud_usu IS 'Sum of gross domestic product in total watershed upstream';
COMMENT ON COLUMN hydroa.catchments.hdi_ix_cav IS 'Average human development index in reach catchment';


SELECT * FROM hydroa.lakes
COMMENT ON TABLE hydroa.lakes IS 'Table of HydroATLAS lake data';
COMMENT ON COLUMN hydroa.lakes."Hylak_id" IS 'Identifier of the lake';
COMMENT ON COLUMN hydroa.lakes."Lake_name" IS 'Name of lake or reservoir';
--COMMENT ON COLUMN hydroa.lakes."Country" IS '';
--COMMENT ON COLUMN hydroa.lakes."Continent" IS '';
COMMENT ON COLUMN hydroa.lakes."Poly_src" IS 'Source of original lake polygon';
COMMENT ON COLUMN hydroa.lakes."Lake_type" IS 'Indicator for lake type : 1 for Lake, 2 for Reservoir 3, for Lake control';
COMMENT ON COLUMN hydroa.lakes."Grand_id" IS 'Identifier of the corresponding reservoir in the GRanD database';
COMMENT ON COLUMN hydroa.lakes."Lake_area" IS 'Lake surface area in km2';
COMMENT ON COLUMN hydroa.lakes."Shore_len" IS 'Length of shoreline in km';
COMMENT ON COLUMN hydroa.lakes."Shore_dev" IS 'Ratio between shoreline length and the circumference of a circle with the same area';
COMMENT ON COLUMN hydroa.lakes."Vol_total" IS 'Total volume in million m3';
COMMENT ON COLUMN hydroa.lakes."Vol_res" IS 'Reported reservoir volume in million m3';
COMMENT ON COLUMN hydroa.lakes."Vol_src" IS 'Source for Vol_total 1 and 2 are GRanD or literature, 3 is estimated';
COMMENT ON COLUMN hydroa.lakes."Depth_avg" IS 'Average depth in m';
COMMENT ON COLUMN hydroa.lakes."Dis_avg" IS 'Average discharge in m3 s-1';
COMMENT ON COLUMN hydroa.lakes."Res_time" IS 'Average residence time of the lake water in days';
COMMENT ON COLUMN hydroa.lakes."Elevation" IS 'Elevation of lake surface, in m above sea level';
COMMENT ON COLUMN hydroa.lakes."Slope_100" IS 'Average slope within a 100 meter buffer around the lake polygon in degrees';
COMMENT ON COLUMN hydroa.lakes."Wshd_area" IS 'Area of the watershed associated with the lake in km2';
COMMENT ON COLUMN hydroa.lakes."Pour_long" IS 'Longitude of the lake pour point, in decimal degrees';
COMMENT ON COLUMN hydroa.lakes."Pour_lat" IS 'Latitude of the lake pour point, in decimal degrees';
COMMENT ON COLUMN hydroa.lakes.hybas_l12 IS 'Identifier of the HydroBASINS river basin level 12';
COMMENT ON COLUMN hydroa.lakes."HYRIV_RCH" IS 'Identifier of the corresponding HydroRIVERS stream reach into which the lake drains at its pour point location';
COMMENT ON COLUMN hydroa.lakes."HYRIV_CAT" IS 'Identifier of the corresponding HydroRIVERS reach catchment in which the lake’s pour point resides';
COMMENT ON COLUMN hydroa.lakes.dis_m3_pyr IS 'Annual average of the natural discharge in m3';
COMMENT ON COLUMN hydroa.lakes.dis_m3_pmn IS 'Annual minimum of the natural discharge in m3';
COMMENT ON COLUMN hydroa.lakes.dis_m3_pmx IS 'Annual maximum of the natural discharge in m3';
COMMENT ON COLUMN hydroa.lakes.run_mm_cyr IS 'Annual average land surface runoff in reach catchment';
COMMENT ON COLUMN hydroa.lakes.inu_pc_cmn IS 'Annual minimum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.inu_pc_umn IS 'Annual minimum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.inu_pc_cmx IS 'Annual maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.inu_pc_umx IS 'Annual maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.inu_pc_clt IS 'Long-term maximum Inundation Extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.inu_pc_ult IS 'Long-term maximum Inundation Extent in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.lka_pc_cse IS 'Limnicity (Percent Lake Area) spatial extent (%) in reach catchment';
COMMENT ON COLUMN hydroa.lakes.lka_pc_use IS 'Limnicity (Percent Lake Area) spatial extent (%) in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.lkv_mc_usu IS 'Sum of lake volume in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.rev_mc_usu IS 'Sum of reservoir volume in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.dor_pc_pva IS 'Degree of regulation at pour point of river reach';
COMMENT ON COLUMN hydroa.lakes.ria_ha_csu IS 'Sum of river area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ria_ha_usu IS 'Sum of river area in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.riv_tc_csu IS 'Sum of river volume in reach catchment';
COMMENT ON COLUMN hydroa.lakes.riv_tc_usu IS 'Sum of river volume in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.gwt_cm_cav IS 'Average Groundwater Table Depth in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ele_mt_cav IS 'Average elevation in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ele_mt_uav IS 'Average elevation in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.ele_mt_cmn IS 'Minimum elevation in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ele_mt_cmx IS 'Maximum elevation in reach catchment';
COMMENT ON COLUMN hydroa.lakes.slp_dg_cav IS 'Terrain slope in reach catchment';
COMMENT ON COLUMN hydroa.lakes.slp_dg_uav IS 'Terrain slope in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.sgr_dk_rav IS 'Average stream gradient along reach segment';
COMMENT ON COLUMN hydroa.lakes.clz_cl_cmj IS 'Spatial majority of climate zone in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cls_cl_cmj IS 'Spatial majority of climate strata in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_cyr IS 'Annual average of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_uyr IS 'Annual average of air temperature in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_cmn IS 'Annual minimum of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_cmx IS 'Annual maximum of air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c01 IS 'Average January air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c02 IS 'Average February air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c03 IS 'Average March air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c04 IS 'Average April air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c05 IS 'Average May air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c06 IS 'Average June air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c07 IS 'Average July air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c08 IS 'Average August air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c09 IS 'Average September air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c10 IS 'Average October air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c11 IS 'Average November air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tmp_dc_c12 IS 'Average December air temperature in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pre_mm_cyr IS 'Annual average of precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_uyr IS 'Annual average of precipitation in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c01 IS 'Average January precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c02 IS 'Average February precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c03 IS 'Average March precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c04 IS 'Average April precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c05 IS 'Average May precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c06 IS 'Average June precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c07 IS 'Average July precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c08 IS 'Average August precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c09 IS 'Average September precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c10 IS 'Average October precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c11 IS 'Average November precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pre_mm_c12 IS 'Average December precipitation in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_cyr IS 'Annual average of potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_uyr IS 'Annual average of potential evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c01 IS 'January potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c02 IS 'February potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c03 IS 'March potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c04 IS 'April potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c05 IS 'May potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c06 IS 'June potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c07 IS 'July potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c08 IS 'August potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c09 IS 'September potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c10 IS 'October potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c11 IS 'November potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.pet_mm_c12 IS 'December potential evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_cyr IS 'Annual average of actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_uyr IS 'Annual average of actual evapotranspiration in total watershed upstream in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c01 IS 'January actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c02 IS 'February actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c03 IS 'March actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c04 IS 'April actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c05 IS 'May actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c06 IS 'June actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c07 IS 'July actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c08 IS 'August actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c09 IS 'September actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c10 IS 'October actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c11 IS 'November actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.aet_mm_c12 IS 'December actual evapotranspiration in reach catchment in mm';
COMMENT ON COLUMN hydroa.lakes.ari_ix_cav IS 'Average global aridity index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ari_ix_uav IS 'Average global aridity index in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_cyr IS 'Annual average climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_uyr IS 'Annual average climate moisture index in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c01 IS 'January climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c02 IS 'February climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c03 IS 'March climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c04 IS 'April climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c05 IS 'May climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c06 IS 'June climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c07 IS 'July climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c08 IS 'August climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c09 IS 'September climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c10 IS 'October climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c11 IS 'November climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cmi_ix_c12 IS 'December climate moisture index in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_cyr IS 'Annual average snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_uyr IS 'Annual average snow cover extent in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.snw_pc_cmx IS 'Annual maximum snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c01 IS 'January snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c02 IS 'Fevruary snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c03 IS 'March snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c04 IS 'April snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c05 IS 'May snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c06 IS 'June snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c07 IS 'July snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c08 IS 'August snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c09 IS 'September snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c10 IS 'October snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c11 IS 'November snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snw_pc_c12 IS 'December snow cover extent in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_cl_cmj IS 'Spatial majority of land cover class in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c01 IS 'Land Cover Extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c02 IS 'Land Cover Extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c03 IS 'Land Cover Extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c04 IS 'Land Cover Extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c05 IS 'Land Cover Extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c06 IS 'Land Cover Extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c07 IS 'Land Cover Extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c08 IS 'Land Cover Extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c09 IS 'Land Cover Extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c10 IS 'Land Cover Extent class 10 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c11 IS 'Land Cover Extent class 11 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c12 IS 'Land Cover Extent class 12 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c13 IS 'Land Cover Extent class 13 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c14 IS 'Land Cover Extent class 14 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c15 IS 'Land Cover Extent class 15 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c16 IS 'Land Cover Extent class 16 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c17 IS 'Land Cover Extent class 17 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c18 IS 'Land Cover Extent class 18 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c19 IS 'Land Cover Extent class 19 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c20 IS 'Land Cover Extent class 20 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c21 IS 'Land Cover Extent class 21 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_c22 IS 'Land Cover Extent class 22 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u01 IS 'Land Cover Extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u02 IS 'Land Cover Extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u03 IS 'Land Cover Extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u04 IS 'Land Cover Extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u05 IS 'Land Cover Extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u06 IS 'Land Cover Extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u07 IS 'Land Cover Extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u08 IS 'Land Cover Extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u09 IS 'Land Cover Extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u10 IS 'Land Cover Extent class 10 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u11 IS 'Land Cover Extent class 11 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u12 IS 'Land Cover Extent class 12 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u13 IS 'Land Cover Extent class 13 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u14 IS 'Land Cover Extent class 14 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u15 IS 'Land Cover Extent class 15 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u16 IS 'Land Cover Extent class 16 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u17 IS 'Land Cover Extent class 17 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u18 IS 'Land Cover Extent class 18 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u19 IS 'Land Cover Extent class 19 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u20 IS 'Land Cover Extent class 20 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u21 IS 'Land Cover Extent class 21 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.glc_pc_u22 IS 'Land Cover Extent class 22 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_cl_cmj IS 'Spatial majority of potential natural vegetation classes in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c01 IS 'Potential natural vegetation extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c02 IS 'Potential natural vegetation extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c03 IS 'Potential natural vegetation extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c04 IS 'Potential natural vegetation extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c05 IS 'Potential natural vegetation extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c06 IS 'Potential natural vegetation extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c07 IS 'Potential natural vegetation extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c08 IS 'Potential natural vegetation extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c09 IS 'Potential natural vegetation extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c10 IS 'Potential natural vegetation extent class 10 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c11 IS 'Potential natural vegetation extent class 11 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c12 IS 'Potential natural vegetation extent class 12 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c13 IS 'Potential natural vegetation extent class 13 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c14 IS 'Potential natural vegetation extent class 14 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_c15 IS 'Potential natural vegetation extent class 15 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u01 IS 'Potential natural vegetation extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u02 IS 'Potential natural vegetation extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u03 IS 'Potential natural vegetation extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u04 IS 'Potential natural vegetation extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u05 IS 'Potential natural vegetation extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u06 IS 'Potential natural vegetation extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u07 IS 'Potential natural vegetation extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u08 IS 'Potential natural vegetation extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u09 IS 'Potential natural vegetation extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u10 IS 'Potential natural vegetation extent class 10 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u11 IS 'Potential natural vegetation extent class 11 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u12 IS 'Potential natural vegetation extent class 12 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u13 IS 'Potential natural vegetation extent class 13 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u14 IS 'Potential natural vegetation extent class 14 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pnv_pc_u15 IS 'Potential natural vegetation extent class 15 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_cl_cmj IS 'Spatial majority wetland class in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_cg1 IS 'Wetland extent class group 1 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_ug1 IS 'Wetland extent class group 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_cg2 IS 'Wetland extent class group 2 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_ug2 IS 'Wetland extent class group 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c01 IS 'Wetland extent class 1 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c02 IS 'Wetland extent class 2 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c03 IS 'Wetland extent class 3 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c04 IS 'Wetland extent class 4 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c05 IS 'Wetland extent class 5 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c06 IS 'Wetland extent class 6 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c07 IS 'Wetland extent class 7 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c08 IS 'Wetland extent class 8 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_c09 IS 'Wetland extent class 9 in reach catchment';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u01 IS 'Wetland extent class 1 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u02 IS 'Wetland extent class 2 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u03 IS 'Wetland extent class 3 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u04 IS 'Wetland extent class 4 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u05 IS 'Wetland extent class 5 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u06 IS 'Wetland extent class 6 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u07 IS 'Wetland extent class 7 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u08 IS 'Wetland extent class 8 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.wet_pc_u09 IS 'Wetland extent class 9 in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.for_pc_cse IS 'Spatial extent (%) of forest cover in reach catchment';
COMMENT ON COLUMN hydroa.lakes.for_pc_use IS 'Spatial extent (%) of forest cover in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.crp_pc_cse IS 'Spatial extent (%) of cropland in reach catchment';
COMMENT ON COLUMN hydroa.lakes.crp_pc_use IS 'Spatial extent (%) of cropland in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pst_pc_cse IS 'Spatial extent (%) of pasture in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pst_pc_use IS 'Spatial extent (%) of pasture in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.ire_pc_cse IS 'Spatial extent (%) of irrigated area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ire_pc_use IS 'Spatial extent (%) of irrigated area in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.gla_pc_cse IS 'Spatial extent (%) of glacier in reach catchment';
COMMENT ON COLUMN hydroa.lakes.gla_pc_use IS 'Spatial extent (%) of glacier in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.prm_pc_cse IS 'Spatial extent (%) of permafrost in reach catchment';
COMMENT ON COLUMN hydroa.lakes.prm_pc_use IS 'Spatial extent (%) of permafrost in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pac_pc_cse IS 'Spatial extent (%) of protected area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pac_pc_use IS 'Spatial extent (%) of protected area in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.tbi_cl_cmj IS 'Spatial majority of terrestrial biomes in reach catchment';
COMMENT ON COLUMN hydroa.lakes.tec_cl_cmj IS 'Spatial majority of terrestrial ecoregions in reach catchment';
COMMENT ON COLUMN hydroa.lakes.fmh_cl_cmj IS 'Spatial majority of freshwater major habitat types in reach catchment';
COMMENT ON COLUMN hydroa.lakes.fec_cl_cmj IS 'Spatial majority of freshwater ecoregions in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cly_pc_cav IS 'Average clay fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.lakes.cly_pc_uav IS 'Average clay fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.slt_pc_cav IS 'Average silt fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.lakes.slt_pc_uav IS 'Average silt fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.snd_pc_cav IS 'Average sand fraction in soil in reach catchment';
COMMENT ON COLUMN hydroa.lakes.snd_pc_uav IS 'Average sand fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.soc_th_cav IS 'Average organic carbon content in soil in reach catchment';
COMMENT ON COLUMN hydroa.lakes.soc_th_uav IS 'Average organic carbon content fraction in soil in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.swc_pc_cyr IS 'Annual average soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_uyr IS 'Annual average soil water content in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c01 IS 'January soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c02 IS 'February soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c03 IS 'March soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c04 IS 'April soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c05 IS 'May soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c06 IS 'June soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c07 IS 'July soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c08 IS 'August soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c09 IS 'September soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c10 IS 'October soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c11 IS 'November soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.swc_pc_c12 IS 'December soil water content in reach catchment';
COMMENT ON COLUMN hydroa.lakes.lit_cl_cmj IS 'Spatial majority of lithological classes in reach catchment';
COMMENT ON COLUMN hydroa.lakes.kar_pc_cse IS 'Spatial extent (%) of Karst area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.kar_pc_use IS 'Spatial extent (%) of Karst area in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.ero_kh_cav IS 'Average soil erosion in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ero_kh_uav IS 'Average soil erosion in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.pop_ct_csu IS 'Population count in reach catchment';
COMMENT ON COLUMN hydroa.lakes.pop_ct_usu IS 'Population count in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.ppd_pk_cav IS 'Average population density in reach catchment';
COMMENT ON COLUMN hydroa.lakes.ppd_pk_uav IS 'Average population density in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.urb_pc_cse IS 'Spatial extent (%) of urban area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.urb_pc_use IS 'Spatial extent (%) of urban area in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.nli_ix_cav IS 'Average nighttime lights in reach catchment';
COMMENT ON COLUMN hydroa.lakes.nli_ix_uav IS 'Average nighttime lights in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.rdd_mk_cav IS 'Average road density in reach catchment';
COMMENT ON COLUMN hydroa.lakes.rdd_mk_uav IS 'Average road density in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.hft_ix_c93 IS 'Human foorprint in reach catchment in 1993';
COMMENT ON COLUMN hydroa.lakes.hft_ix_u93 IS 'Human footprint in total watershed upstream in 1993';
COMMENT ON COLUMN hydroa.lakes.hft_ix_c09 IS 'Human foorprint in reach catchment in 2009';
COMMENT ON COLUMN hydroa.lakes.hft_ix_u09 IS 'Human footprint in total watershed upstream in 2009';
COMMENT ON COLUMN hydroa.lakes.gad_id_cmj IS 'Spatial majority of global administrative area in reach catchment';
COMMENT ON COLUMN hydroa.lakes.gdp_ud_cav IS 'Average gross domestic product in reach catchment';
COMMENT ON COLUMN hydroa.lakes.gdp_ud_csu IS 'Sum of gross domestic product in reach catchment';
COMMENT ON COLUMN hydroa.lakes.gdp_ud_usu IS 'Sum of gross domestic product in total watershed upstream';
COMMENT ON COLUMN hydroa.lakes.hdi_ix_cav IS 'Average human development index in reach catchment';
--COMMENT ON COLUMN hydroa.lakes."source" IS '';
--COMMENT ON COLUMN hydroa.lakes.ufid IS '';


COMMENT ON TABLE e_gota."euhydro_gota_v013 — River_Net_l" IS 'Table for river network data from EU-Hydro';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."OBJECTID" IS 'Non-unique identifier for the segment';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l".geom IS 'Geometry';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."DFDD" IS 'DGIWG Feature Data Dictionary';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."RN_I_ID" IS 'Connector between line and area data if any overlapping polygon feature exists';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."REX" IS 'Defines the country a hydrological feature is located in';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."HYP" IS 'Degree of persistence of water 1 (perennial) to 4 (dry)';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."LOC" IS 'Vertical position of a hydrological feature relative to the ground surface. Below (40), on (44) or above (45) surface';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."FUN" IS 'The state of planning, construction, repair, and or maintenance of the structures 
and / or equipment comprising a facility and/or located at a site, as a whole.';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."NVS" IS 'Navigability information';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."LENGTH" IS 'Length of the corresponding line segment in km';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."TR" IS 'Segment ID transferred from the attribute TR in ECRINS if possible, NA otherwise';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."LONGPATH" IS 'Longest path from a mouth, which is not capturing all rivers from the same mouth';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."CUM_LEN" IS 'Cumulated length of all segments upstream in m';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."PENTE" IS 'Slope computed from the EU DEM according to the formula “highest z-value minus lowest
z-value divided by the length of the line”';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."CGNELIN" IS 'Warning: Incomplete, not updated';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."BEGLIFEVER" IS 'Specifies the date and time at which this version of the
spatial object was inserted into the data set';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."ENDLIFEVER" IS 'Specifies the date and time at which this version of the
spatial object was superseded';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."UPDAT_BY" IS 'ID of the updater';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."UPDAT_WHEN" IS 'Date of update';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."ERM_ID" IS 'National Hydrological Identification Code (NHI), transferred from ERM';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."MC" IS 'Watercourse Channel Type. Braided (0) or normal (1)';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."MONOT_Z" IS '0: z-values of the feature do not decrease monotonically along the flow direction
1: z-values of the feature decrease monotonically along the flow direction';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."LENGTH_GEO" IS 'Feature length (geodetic) in meters. In contrast to the internally managed
SHAPE_LENGTH attribute, the value of thisattribute is not influenced by the projection settings';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."INSPIRE_ID" IS 'External identifier of the spatial object';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."thematicId" IS 'European WFD code. Transferred from the WISE geospatial dataset';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."OBJECT_ID" IS 'Unique identifier for the segment';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."TNODE" IS 'Downstream node OBJECT_ID';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."STRAHLER" IS 'Strahler level of the segment';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."nameTxtInt" IS 'English version of the name of the geographical feature or spatial object,
extracted from WISE geospatial dataset';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."nameText" IS 'Name in a national language, extracted from WISE geospatial dataset';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."NEXTUPID" IS 'OBJECT_ID of the previous line object (Canals, River or Ditches) 
in the upstream direction';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."NEXTDOWNID" IS 'OBJECT_ID of the previous line object (Canals, River or Ditches) 
in the downstream direction';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."FNODE" IS 'Upstream node OBJECT_ID';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."CatchID" IS 'Number indicating a Catchment ID';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."Shape_Length" IS 'Feature length in meters in case of line geometries';
COMMENT ON COLUMN e_gota."euhydro_gota_v013 — River_Net_l"."PFAFSTETTER" IS 'Pfafstetter indicator';


CREATE OR REPLACE FUNCTION public.comment_hydro_schemas(
    p_schemas text[] DEFAULT ARRAY[
        'h_adriatic','h_baltic22to26','h_baltic27to29_32','h_baltic30to31','h_barents',
        'h_biscayiberian','h_blacksea','h_celtic','h_iceland','h_medcentral','h_medeast',
        'h_medwest','h_norwegian','h_nseanorth','h_nseasouth','h_nseauk','h_southatlantic',
        'h_southmedcentral','h_southmedeast','h_southmedwest','h_svalbard'
    ]
)
RETURNS void
LANGUAGE plpgsql
AS $fn$
DECLARE
    m       text[] := ARRAY['January','February','March','April','May','June','July',
                            'August','September','October','November','December'];
    s       text;
    t       text;
    t_comm  text;
    r       record;
    n_ok    int := 0;
BEGIN
    -- Dictionary of comments: tab = 'common' applies to all three tables
    DROP TABLE IF EXISTS tmp_def;
    CREATE TEMP TABLE tmp_def (tab text, col text, comm text) ON COMMIT DROP;

    -- ---------- riversegments only ----------
    INSERT INTO tmp_def VALUES
    ('riversegments','hyriv_id','Identifier of the segment'),
    ('riversegments','next_down','Identifier of the next downstream river segment'),
    ('riversegments','main_riv','Identifier of the most downstream river segment of the river basin'),
    ('riversegments','length_km','Length of the river segment'),
    ('riversegments','dist_dn_km','Distance from the most downstream part of the segment to the most downstream part of the river network'),
    ('riversegments','dist_up_km','Distance from the most downstream part of the segment to the most upstream part of the river network'),
    ('riversegments','endorheic','Indicator for presence (1) or absence (0) of an endorheic basin downstream of the segment'),
    ('riversegments','dis_av_cms','Average long-term discharge estimate for river reach, in m3 s-1'),
    ('riversegments','ord_stra','Strahler rank'),
    ('riversegments','ord_clas','Classic stream rank'),
    ('riversegments','ord_flow','River order using average river discharge');

    -- ---------- catchments only ----------
    INSERT INTO tmp_def VALUES
    ('catchments','HYBAS_ID','Identifier of the basin'),
    ('catchments','next_down','Identifier of the next downstream basin'),
    ('catchments','NEXT_SINK','Identifier of the next downstream sink, either endorheic sink or most downstream basin'),
    ('catchments','MAIN_BAS','Identifier of the most downstream basin'),
    ('catchments','DIST_SINK','Distance from basin outlet to the next downstream sink'),
    ('catchments','DIST_MAIN','Distance from basin outlet to the most downstream sink'),
    ('catchments','SUB_AREA','Area of the basin in km2'),
    ('catchments','UP_AREA','Total upstream area in km2'),
    ('catchments','PFAF_ID','Pfafstetter code'),
    ('catchments','ENDO','Indicator for presence (1) or absence (0) of an endorheic basin downstream of the basin. 2 if sink of endorheic basin'),
    ('catchments','ORDER_','Classic stream order'),
    ('catchments','SORT','Shapefile storage order');

    -- ---------- lakes only ----------
    INSERT INTO tmp_def VALUES
    ('lakes','Hylak_id','Identifier of the lake'),
    ('lakes','Lake_name','Name of lake or reservoir'),
    ('lakes','Poly_src','Source of original lake polygon'),
    ('lakes','Lake_type','Indicator for lake type : 1 for Lake, 2 for Reservoir 3, for Lake control'),
    ('lakes','Grand_id','Identifier of the corresponding reservoir in the GRanD database'),
    ('lakes','Lake_area','Lake surface area in km2'),
    ('lakes','Shore_len','Length of shoreline in km'),
    ('lakes','Shore_dev','Ratio between shoreline length and the circumference of a circle with the same area'),
    ('lakes','Vol_total','Total volume in million m3'),
    ('lakes','Vol_res','Reported reservoir volume in million m3'),
    ('lakes','Vol_src','Source for Vol_total 1 and 2 are GRanD or literature, 3 is estimated'),
    ('lakes','Depth_avg','Average depth in m'),
    ('lakes','Dis_avg','Average discharge in m3 s-1'),
    ('lakes','Res_time','Average residence time of the lake water in days'),
    ('lakes','Elevation','Elevation of lake surface, in m above sea level'),
    ('lakes','Slope_100','Average slope within a 100 meter buffer around the lake polygon in degrees'),
    ('lakes','Wshd_area','Area of the watershed associated with the lake in km2'),
    ('lakes','Pour_long','Longitude of the lake pour point, in decimal degrees'),
    ('lakes','Pour_lat','Latitude of the lake pour point, in decimal degrees'),
    ('lakes','HYRIV_RCH','Identifier of the corresponding HydroRIVERS stream reach into which the lake drains at its pour point location'),
    ('lakes','HYRIV_CAT','Identifier of the corresponding HydroRIVERS reach catchment in which the lake''s pour point resides');

    -- ---------- common HydroATLAS attributes (same on all 3 tables) ----------
    INSERT INTO tmp_def VALUES
    ('common','hybas_l12','Identifier of the HydroBASINS river basin level 12'),
    ('common','dis_m3_pyr','Annual average of the natural discharge in m3'),
    ('common','dis_m3_pmn','Annual minimum of the natural discharge in m3'),
    ('common','dis_m3_pmx','Annual maximum of the natural discharge in m3'),
    ('common','run_mm_cyr','Annual average land surface runoff in reach catchment'),
    ('common','inu_pc_cmn','Annual minimum Inundation Extent in reach catchment'),
    ('common','inu_pc_umn','Annual minimum Inundation Extent in total watershed upstream'),
    ('common','inu_pc_cmx','Annual maximum Inundation Extent in reach catchment'),
    ('common','inu_pc_umx','Annual maximum Inundation Extent in total watershed upstream'),
    ('common','inu_pc_clt','Long-term maximum Inundation Extent in reach catchment'),
    ('common','inu_pc_ult','Long-term maximum Inundation Extent in total watershed upstream'),
    ('common','lka_pc_cse','Limnicity (Percent Lake Area) spatial extent (%) in reach catchment'),
    ('common','lka_pc_use','Limnicity (Percent Lake Area) spatial extent (%) in total watershed upstream'),
    ('common','lkv_mc_usu','Sum of lake volume in total watershed upstream'),
    ('common','rev_mc_usu','Sum of reservoir volume in total watershed upstream'),
    ('common','dor_pc_pva','Degree of regulation at pour point of river reach'),
    ('common','ria_ha_csu','Sum of river area in reach catchment'),
    ('common','ria_ha_usu','Sum of river area in total watershed upstream'),
    ('common','riv_tc_csu','Sum of river volume in reach catchment'),
    ('common','riv_tc_usu','Sum of river volume in total watershed upstream'),
    ('common','gwt_cm_cav','Average Groundwater Table Depth in reach catchment'),
    ('common','ele_mt_cav','Average elevation in reach catchment'),
    ('common','ele_mt_uav','Average elevation in total watershed upstream'),
    ('common','ele_mt_cmn','Minimum elevation in reach catchment'),
    ('common','ele_mt_cmx','Maximum elevation in reach catchment'),
    ('common','slp_dg_cav','Terrain slope in reach catchment'),
    ('common','slp_dg_uav','Terrain slope in total watershed upstream'),
    ('common','sgr_dk_rav','Average stream gradient along reach segment'),
    ('common','clz_cl_cmj','Spatial majority of climate zone in reach catchment'),
    ('common','cls_cl_cmj','Spatial majority of climate strata in reach catchment'),
    ('common','tmp_dc_cyr','Annual average of air temperature in reach catchment'),
    ('common','tmp_dc_uyr','Annual average of air temperature in total watershed upstream'),
    ('common','tmp_dc_cmn','Annual minimum of air temperature in reach catchment'),
    ('common','tmp_dc_cmx','Annual maximum of air temperature in reach catchment'),
    ('common','pre_mm_cyr','Annual average of precipitation in reach catchment in mm'),
    ('common','pre_mm_uyr','Annual average of precipitation in total watershed upstream in mm'),
    ('common','pet_mm_cyr','Annual average of potential evapotranspiration in reach catchment in mm'),
    ('common','pet_mm_uyr','Annual average of potential evapotranspiration in total watershed upstream in mm'),
    ('common','aet_mm_cyr','Annual average of actual evapotranspiration in reach catchment in mm'),
    ('common','aet_mm_uyr','Annual average of actual evapotranspiration in total watershed upstream in mm'),
    ('common','ari_ix_cav','Average global aridity index in reach catchment'),
    ('common','ari_ix_uav','Average global aridity index in total watershed upstream'),
    ('common','cmi_ix_cyr','Annual average climate moisture index in reach catchment'),
    ('common','cmi_ix_uyr','Annual average climate moisture index in total watershed upstream'),
    ('common','snw_pc_cyr','Annual average snow cover extent in reach catchment'),
    ('common','snw_pc_uyr','Annual average snow cover extent in total watershed upstream'),
    ('common','snw_pc_cmx','Annual maximum snow cover extent in reach catchment'),
    ('common','glc_cl_cmj','Spatial majority of land cover class in reach catchment'),
    ('common','pnv_cl_cmj','Spatial majority of potential natural vegetation classes in reach catchment'),
    ('common','wet_cl_cmj','Spatial majority wetland class in reach catchment'),
    ('common','wet_pc_cg1','Wetland extent class group 1 in reach catchment'),
    ('common','wet_pc_ug1','Wetland extent class group 1 in total watershed upstream'),
    ('common','wet_pc_cg2','Wetland extent class group 2 in reach catchment'),
    ('common','wet_pc_ug2','Wetland extent class group 2 in total watershed upstream'),
    ('common','for_pc_cse','Spatial extent (%) of forest cover in reach catchment'),
    ('common','for_pc_use','Spatial extent (%) of forest cover in total watershed upstream'),
    ('common','crp_pc_cse','Spatial extent (%) of cropland in reach catchment'),
    ('common','crp_pc_use','Spatial extent (%) of cropland in total watershed upstream'),
    ('common','pst_pc_cse','Spatial extent (%) of pasture in reach catchment'),
    ('common','pst_pc_use','Spatial extent (%) of pasture in total watershed upstream'),
    ('common','ire_pc_cse','Spatial extent (%) of irrigated area in reach catchment'),
    ('common','ire_pc_use','Spatial extent (%) of irrigated area in total watershed upstream'),
    ('common','gla_pc_cse','Spatial extent (%) of glacier in reach catchment'),
    ('common','gla_pc_use','Spatial extent (%) of glacier in total watershed upstream'),
    ('common','prm_pc_cse','Spatial extent (%) of permafrost in reach catchment'),
    ('common','prm_pc_use','Spatial extent (%) of permafrost in total watershed upstream'),
    ('common','pac_pc_cse','Spatial extent (%) of protected area in reach catchment'),
    ('common','pac_pc_use','Spatial extent (%) of protected area in total watershed upstream'),
    ('common','tbi_cl_cmj','Spatial majority of terrestrial biomes in reach catchment'),
    ('common','tec_cl_cmj','Spatial majority of terrestrial ecoregions in reach catchment'),
    ('common','fmh_cl_cmj','Spatial majority of freshwater major habitat types in reach catchment'),
    ('common','fec_cl_cmj','Spatial majority of freshwater ecoregions in reach catchment'),
    ('common','cly_pc_cav','Average clay fraction in soil in reach catchment'),
    ('common','cly_pc_uav','Average clay fraction in soil in total watershed upstream'),
    ('common','slt_pc_cav','Average silt fraction in soil in reach catchment'),
    ('common','slt_pc_uav','Average silt fraction in soil in total watershed upstream'),
    ('common','snd_pc_cav','Average sand fraction in soil in reach catchment'),
    ('common','snd_pc_uav','Average sand fraction in soil in total watershed upstream'),
    ('common','soc_th_cav','Average organic carbon content in soil in reach catchment'),
    ('common','soc_th_uav','Average organic carbon content fraction in soil in total watershed upstream'),
    ('common','swc_pc_cyr','Annual average soil water content in reach catchment'),
    ('common','swc_pc_uyr','Annual average soil water content in total watershed upstream'),
    ('common','lit_cl_cmj','Spatial majority of lithological classes in reach catchment'),
    ('common','kar_pc_cse','Spatial extent (%) of Karst area in reach catchment'),
    ('common','kar_pc_use','Spatial extent (%) of Karst area in total watershed upstream'),
    ('common','ero_kh_cav','Average soil erosion in reach catchment'),
    ('common','ero_kh_uav','Average soil erosion in total watershed upstream'),
    ('common','pop_ct_csu','Population count in reach catchment'),
    ('common','pop_ct_usu','Population count in total watershed upstream'),
    ('common','ppd_pk_cav','Average population density in reach catchment'),
    ('common','ppd_pk_uav','Average population density in total watershed upstream'),
    ('common','urb_pc_cse','Spatial extent (%) of urban area in reach catchment'),
    ('common','urb_pc_use','Spatial extent (%) of urban area in total watershed upstream'),
    ('common','nli_ix_cav','Average nighttime lights in reach catchment'),
    ('common','nli_ix_uav','Average nighttime lights in total watershed upstream'),
    ('common','rdd_mk_cav','Average road density in reach catchment'),
    ('common','rdd_mk_uav','Average road density in total watershed upstream'),
    ('common','hft_ix_c93','Human footprint in reach catchment in 1993'),
    ('common','hft_ix_u93','Human footprint in total watershed upstream in 1993'),
    ('common','hft_ix_c09','Human footprint in reach catchment in 2009'),
    ('common','hft_ix_u09','Human footprint in total watershed upstream in 2009'),
    ('common','gad_id_cmj','Spatial majority of global administrative area in reach catchment'),
    ('common','gdp_ud_cav','Average gross domestic product in reach catchment'),
    ('common','gdp_ud_csu','Sum of gross domestic product in reach catchment'),
    ('common','gdp_ud_usu','Sum of gross domestic product in total watershed upstream'),
    ('common','hdi_ix_cav','Average human development index in reach catchment');

    -- Monthly series (c01..c12)
    INSERT INTO tmp_def
    SELECT 'common', 'tmp_dc_c'||lpad(i::text,2,'0'), 'Average '||m[i]||' air temperature in reach catchment' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'pre_mm_c'||lpad(i::text,2,'0'), 'Average '||m[i]||' precipitation in reach catchment in mm' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'pet_mm_c'||lpad(i::text,2,'0'), m[i]||' potential evapotranspiration in reach catchment in mm' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'aet_mm_c'||lpad(i::text,2,'0'), m[i]||' actual evapotranspiration in reach catchment in mm' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'cmi_ix_c'||lpad(i::text,2,'0'), m[i]||' climate moisture index in reach catchment' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'snw_pc_c'||lpad(i::text,2,'0'), m[i]||' snow cover extent in reach catchment' FROM generate_series(1,12) i
    UNION ALL
    SELECT 'common', 'swc_pc_c'||lpad(i::text,2,'0'), m[i]||' soil water content in reach catchment' FROM generate_series(1,12) i;

    -- Class series (reach catchment "c" / upstream watershed "u")
    INSERT INTO tmp_def
    SELECT 'common', 'glc_pc_c'||lpad(i::text,2,'0'), 'Land Cover Extent class '||i||' in reach catchment' FROM generate_series(1,22) i
    UNION ALL
    SELECT 'common', 'glc_pc_u'||lpad(i::text,2,'0'), 'Land Cover Extent class '||i||' in total watershed upstream' FROM generate_series(1,22) i
    UNION ALL
    SELECT 'common', 'pnv_pc_c'||lpad(i::text,2,'0'), 'Potential natural vegetation extent class '||i||' in reach catchment' FROM generate_series(1,15) i
    UNION ALL
    SELECT 'common', 'pnv_pc_u'||lpad(i::text,2,'0'), 'Potential natural vegetation extent class '||i||' in total watershed upstream' FROM generate_series(1,15) i
    UNION ALL
    SELECT 'common', 'wet_pc_c'||lpad(i::text,2,'0'), 'Wetland extent class '||i||' in reach catchment' FROM generate_series(1,9) i
    UNION ALL
    SELECT 'common', 'wet_pc_u'||lpad(i::text,2,'0'), 'Wetland extent class '||i||' in total watershed upstream' FROM generate_series(1,9) i;

    -- ---------- Loop on schemas and tables ----------
    FOREACH s IN ARRAY p_schemas LOOP
        FOREACH t IN ARRAY ARRAY['riversegments','catchments','lakes'] LOOP

            IF to_regclass(format('%I.%I', s, t)) IS NULL THEN
                RAISE NOTICE 'Table %.% not found, skipped', s, t;
                CONTINUE;
            END IF;

            t_comm := CASE t
                WHEN 'riversegments' THEN 'Table of river network data from HydroSHEDS (source = riveratlas_v10)'
                WHEN 'catchments'    THEN 'Table of HydroATLAS basins level 12'
                WHEN 'lakes'         THEN 'Table of HydroATLAS lake data'
            END;
            EXECUTE format('COMMENT ON TABLE %I.%I IS %L', s, t, t_comm);

            FOR r IN
                SELECT d.col, d.comm
                FROM tmp_def d
                JOIN information_schema.columns c
                  ON c.table_schema = s
                 AND c.table_name   = t
                 AND c.column_name  = d.col
                WHERE d.tab IN ('common', t)
            LOOP
                EXECUTE format('COMMENT ON COLUMN %I.%I.%I IS %L', s, t, r.col, r.comm);
                n_ok := n_ok + 1;
            END LOOP;

        END LOOP;
    END LOOP;

    RAISE NOTICE '% column comments written', n_ok;
END;
$fn$;


-- all 21 schemas
SELECT public.comment_hydro_schemas(); -- 10017 column comments



SELECT cols.column_name AS var_name, 
        pgd.description AS description
  FROM information_schema.columns cols
  LEFT JOIN pg_catalog.pg_statio_all_tables st 
      ON st.schemaname = cols.table_schema AND st.relname = cols.table_name
  LEFT JOIN pg_catalog.pg_description pgd 
      ON pgd.objoid = st.relid AND pgd.objsubid = cols.ordinal_position
  WHERE cols.table_schema = 'h_adriatic'
  AND cols.table_name = 'riversegments';


SELECT cols.column_name AS var_name, 
        pgd.description AS description
  FROM information_schema.columns cols
  LEFT JOIN pg_catalog.pg_statio_all_tables st 
      ON st.schemaname = cols.table_schema AND st.relname = cols.table_name
  LEFT JOIN pg_catalog.pg_description pgd 
      ON pgd.objoid = st.relid AND pgd.objsubid = cols.ordinal_position
  WHERE cols.table_schema = 'h_adriatic'
  AND cols.table_name = 'catchments';


SELECT cols.column_name AS var_name, 
        pgd.description AS description
  FROM information_schema.columns cols
  INNER JOIN pg_catalog.pg_statio_all_tables st 
      ON st.schemaname = cols.table_schema AND st.relname = cols.table_name
  INNER JOIN pg_catalog.pg_description pgd 
      ON pgd.objoid = st.relid AND pgd.objsubid = cols.ordinal_position
  WHERE cols.table_schema = 'h_adriatic'
  AND cols.table_name = 'lakes';