create schema habitat;
ALTER SCHEMA Habitat  OWNER TO diaspara_admin;

ALTER TABLE habitat.catchments_baltic set schema tempo;
ALTER TABLE tempo.catchments_eel set schema habitat;
ALTER TABLE tempo.catchments_nac set schema habitat;
ALTER TABLE tempo.catchments_nas set schema habitat;
ALTER TABLE habitat.riversegments_baltic set schema tempo;
ALTER TABLE tempo.riversegments_eel set schema habitat;
ALTER TABLE tempo.riversegments_nac set schema habitat;
ALTER TABLE tempo.riversegments_nas set schema habitat;


SELECT * FROM ONLY habitat.catchments_eel; --0
SELECT count(*) FROM ONLY habitat.catchments_nac; --30504
SELECT count(*) FROM ONLY habitat.catchments_nas; --0
SELECT * FROM ONLY habitat.riversegments_eel; --0
ALTER TABLE habitat.catchments_nac SET SCHEMA tempo;
ALTER TABLE habitat.riversegments_nac SET SCHEMA tempo;






SELECT * FROM "ref".tr_area_are 
JOIN "ref".tr_rivernames_riv ON riv_are_code = are_code
WHERE are_name != riv_rivername

