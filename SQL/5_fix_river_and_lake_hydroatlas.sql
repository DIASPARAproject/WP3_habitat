
ALTER TABLE riveratlas.riveratlas_v10 RENAME COLUMN shape TO geom;
-- select only rivers corresponding to catchments
DROP TABLE IF EXISTS w2020.riversegments;
CREATE TABLE w2020.riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM w2020.catchments c 
		WHERE ST_Intersects(r.geom,c.geom)
	)
); --144831

DROP TABLE IF EXISTS w2021.riversegments;
CREATE TABLE w2021.riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM w2021.catchments c 
		WHERE ST_Intersects(r.geom,c.geom)
	)
); --255503

DROP TABLE IF EXISTS w2022.riversegments;
CREATE TABLE w2022.riversegments AS(
	SELECT * FROM riveratlas.riveratlas_v10 r
	WHERE EXISTS (
		SELECT 1
		FROM w2022.catchments c 
		WHERE ST_Intersects(r.geom,c.geom)
	)
); --37488

ALTER TABLE lakeatlas.lakeatlas_v10_pol RENAME COLUMN shape TO geom;
-- select only lakes corresponding to catchments
DROP TABLE IF EXISTS w2020.lakes;
CREATE TABLE w2020.lakes AS(
	SELECT * FROM lakeatlas.lakeatlas_v10_pol l
	WHERE EXISTS (
		SELECT 1
		FROM w2020.catchments c 
		WHERE ST_Intersects(l.geom,c.geom)
	)
); --1903

DROP TABLE IF EXISTS w2021.lakes;
CREATE TABLE w2021.lakes AS(
	SELECT * FROM lakeatlas.lakeatlas_v10_pol l
	WHERE EXISTS (
		SELECT 1
		FROM w2021.catchments c 
		WHERE ST_Intersects(l.geom,c.geom)
	)
); --386

DROP TABLE IF EXISTS w2022.lakes;
CREATE TABLE w2022.lakes AS(
	SELECT * FROM lakeatlas.lakeatlas_v10_pol l
	WHERE EXISTS (
		SELECT 1
		FROM w2022.catchments c 
		WHERE ST_Intersects(l.geom,c.geom)
	)
); --113