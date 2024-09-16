-- adding a column with data source and deleting fid
ALTER TABLE hydroa.riversegments
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.riversegments
DROP COLUMN fid;
ALTER TABLE hydroa.riversegments_s
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.riversegments_s
DROP COLUMN fid;
ALTER TABLE hydroa.catchments
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.catchments
DROP COLUMN fid;
ALTER TABLE hydroa.catchments_s
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.catchments_s
DROP COLUMN fid;
ALTER TABLE hydroa.lakes
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.lakes
DROP COLUMN fid;
ALTER TABLE hydroa.lakes_s
ADD COLUMN source VARCHAR(10) DEFAULT 'HydroATLAS';
ALTER TABLE hydroa.lakes_s 
DROP COLUMN fid;



-- join between north african and sinai db
INSERT INTO hydroa.riversegments
SELECT *
FROM hydroa.riversegments_s;
INSERT INTO hydroa.catchments
SELECT *
FROM hydroa.catchments_s;
INSERT INTO hydroa.lakes
SELECT *
FROM hydroa.lakes_s;

-- creating uuid
ALTER TABLE hydroa.riversegments
ADD COLUMN ufid UUID DEFAULT gen_random_uuid();
ALTER TABLE hydroa.catchments
ADD COLUMN ufid UUID DEFAULT gen_random_uuid();
ALTER TABLE hydroa.lakes
ADD COLUMN ufid UUID DEFAULT gen_random_uuid();



-- renaming columns to match CCM's
ALTER TABLE hydroa.riversegments 
RENAME "HYRIV_ID" TO rvr_id;
ALTER TABLE hydroa.riversegments 
RENAME "NEXT_DOWN" TO nextdownid;
ALTER TABLE hydroa.riversegments 
RENAME "HYBAS_L12" TO catchment_;
ALTER TABLE hydroa.riversegments 
RENAME "ORD_STRA" TO strahler;
UPDATE hydroa.riversegments
SET "LENGTH_KM" = "LENGTH_KM" * 1000
ALTER TABLE hydroa.riversegments
RENAME "LENGTH_KM" TO length;
ALTER TABLE hydroa.riversegments 
RENAME "HYRIV_ID" TO rvr_id;
ALTER TABLE hydroa.riversegments 
RENAME "HYRIV_ID" TO rvr_id;
ALTER TABLE hydroa.riversegments 
RENAME "HYRIV_ID" TO rvr_id;