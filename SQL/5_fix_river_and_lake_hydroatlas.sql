
ALTER TABLE riveratlas.riveratlas_v10 RENAME COLUMN shape TO geom;
-- select only rivers corresponding to catchments
DROP TABLE IF EXISTS hydroatlas.riversegments;
CREATE TABLE hydroatlas.riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM hydroatlas.catchments c 
		WHERE ST_Intersects(r.geom,c.geom)
	)
); --460286

ALTER TABLE lakeatlas.lakeatlas_v10_pol RENAME COLUMN shape TO geom;
-- select only lakes corresponding to catchments
DROP TABLE IF EXISTS hydroatlas.lakes;
CREATE TABLE hydroatlas.lakes AS(
	SELECT * FROM lakeatlas.lakeatlas_v10_pol l
	WHERE EXISTS (
		SELECT 1
		FROM hydroatlas.catchments c 
		WHERE ST_Intersects(l.geom,c.geom)
	)
); --2468