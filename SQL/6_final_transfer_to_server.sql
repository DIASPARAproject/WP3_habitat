create schema habitat;
ALTER SCHEMA Habitat  OWNER TO diaspara_admin;

ALTER TABLE habitat.catchments_baltic set schema tempo;
ALTER TABLE tempo.catchments_eel set schema habitat;
ALTER TABLE tempo.catchments_nac set schema habitat;
ALTER TABLE tempo.catchments_nas set schema habitat;
ALTER TABLE tempo.riversegments_baltic set schema habitat;
ALTER TABLE tempo.riversegments_eel set schema habitat;
ALTER TABLE tempo.riversegments_nac set schema habitat;
ALTER TABLE tempo.riversegments_nas set schema habitat;


Run this query from PostgreSQL:

SELECT version();