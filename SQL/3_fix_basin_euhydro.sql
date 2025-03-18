
CREATE SCHEMA e_angerman;
CREATE SCHEMA e_danube;
CREATE SCHEMA e_duero;
CREATE SCHEMA e_ebro;
CREATE SCHEMA e_elbe;
CREATE SCHEMA e_garonne;
CREATE SCHEMA e_gota;
CREATE SCHEMA e_guadalquivir;
CREATE SCHEMA e_hondo;
CREATE SCHEMA e_iceland;
CREATE SCHEMA e_jucar;
CREATE SCHEMA e_kemi;
CREATE SCHEMA e_loire;
CREATE SCHEMA e_mesima;
CREATE SCHEMA e_nemunas;
CREATE SCHEMA e_neva;
CREATE SCHEMA e_oder;
CREATE SCHEMA e_pinios;
CREATE SCHEMA e_po;
CREATE SCHEMA e_rhine;
CREATE SCHEMA e_rhone;
CREATE SCHEMA e_seine;
CREATE SCHEMA e_shannon;
CREATE SCHEMA e_skjern;
CREATE SCHEMA e_tajo;
CREATE SCHEMA e_tana;
CREATE SCHEMA e_tevere;
CREATE SCHEMA e_thames;
CREATE SCHEMA e_tirso;
CREATE SCHEMA e_turkey;
CREATE SCHEMA e_tweed;
CREATE SCHEMA e_vistula;
CREATE SCHEMA e_vorma;



--------------------- Functions creation ---------------------
-- Function to modify srid from 3035 to 4326
DROP FUNCTION IF EXISTS altergeometry(basin TEXT);
CREATE OR REPLACE FUNCTION altergeometry(basin TEXT)
RETURNS TABLE (table_name TEXT, srid INTEGER) AS
$$
DECLARE 
    schema_name TEXT := quote_ident('e_' || basin);
    river_table TEXT := quote_ident('euhydro_' || basin || '_v013 — River_Net_l');
    nodes_table TEXT := quote_ident('euhydro_' || basin || '_v013 — Nodes');
    sql_query TEXT;
BEGIN 
    sql_query := 
        'ALTER TABLE ' || schema_name || '.' || river_table || 
        ' ALTER COLUMN geom TYPE geometry(MultiLineString, 4326) 
          USING ST_Transform(ST_Force2D(geom), 4326);';
    EXECUTE sql_query;
    sql_query := 
        'ALTER TABLE ' || schema_name || '.' || nodes_table || 
        ' ALTER COLUMN geom TYPE geometry(Point, 4326) 
          USING ST_Transform(ST_Force2D(geom), 4326);';
    EXECUTE sql_query;

	RETURN QUERY EXECUTE 
        'SELECT ' || quote_literal(river_table) || ' AS table_name, srid 
         FROM (SELECT DISTINCT ST_SRID(geom) AS srid FROM ' || schema_name || '.' || river_table || ') sub
         UNION ALL 
         SELECT ' || quote_literal(nodes_table) || ' AS table_name, srid 
         FROM (SELECT DISTINCT ST_SRID(geom) AS srid FROM ' || schema_name || '.' || nodes_table || ') sub;';
END;
$$ LANGUAGE plpgsql;

-- Function to add indexes and unicity constraint
DROP FUNCTION IF EXISTS create_indexes_and_constraint(basin TEXT);
CREATE OR REPLACE FUNCTION create_indexes_and_constraint(basin TEXT)
RETURNS VOID AS
$$
DECLARE 
    schema_name TEXT := quote_ident('e_' || basin);
    river_table TEXT := quote_ident('euhydro_' || basin || '_v013 — River_Net_l');
    sql_query TEXT;
BEGIN 
    sql_query := 
        'CREATE INDEX IF NOT EXISTS idx_t_node_' || basin || '_riv 
         ON ' || schema_name || '.' || river_table || ' USING btree("TNODE");';
    EXECUTE sql_query;
    sql_query := 
        'CREATE INDEX IF NOT EXISTS idx_next_did_' || basin || '_riv 
         ON ' || schema_name || '.' || river_table || ' USING btree("NEXTDOWNID");';
    EXECUTE sql_query;
    sql_query := 
        'CREATE INDEX IF NOT EXISTS idx_obj_id_' || basin || ' 
         ON ' || schema_name || '.' || river_table || ' USING btree("OBJECT_ID");';
    EXECUTE sql_query;
    sql_query := 
        'ALTER TABLE ' || schema_name || '.' || river_table || ' 
         ADD CONSTRAINT c_uk_object_id_' || basin || ' UNIQUE("OBJECT_ID");';
    EXECUTE sql_query;
END;
$$ LANGUAGE plpgsql;

-- Function to restructure columns order
DROP FUNCTION IF EXISTS restructurecolumns(basin TEXT);
CREATE OR REPLACE FUNCTION restructurecolumns(basin TEXT)
RETURNS VOID AS $$
DECLARE 
    schema_name TEXT := quote_ident('e_' || basin);
    source_table TEXT := quote_ident('euhydro_' || basin || '_v013 — River_Net_l');
    target_table TEXT := quote_ident('riverseg');
    sql_query TEXT;
BEGIN
    sql_query := 
        'CREATE TABLE ' || schema_name || '.' || target_table || ' AS SELECT ' ||
        '"OBJECTID",
         geom,
         "DFDD",
         "RN_I_ID",
         "REX",
         "HYP",
         "LOC",
         "FUN",
         "NVS",
         "LENGTH",
         "TR",
         "LONGPATH",
         "CUM_LEN",
         "PENTE",
         "CGNELIN",
         "BEGLIFEVER",
         "ENDLIFEVER",
         "UPDAT_BY",
         "UPDAT_WHEN",
         "ERM_ID",
         "MC",
         "MONOT_Z",
         "LENGTH_GEO",
         "INSPIRE_ID",
         "thematicId",
         "OBJECT_ID",
         "TNODE",
         "STRAHLER",
         "nameTxtInt",
         "nameText",
         "NEXTUPID",
         "NEXTDOWNID",
         "FNODE",
         "CatchID",
         "Shape_Length",
         "PFAFSTETTER" ' ||
        ' FROM ' || schema_name || '.' || source_table;

    EXECUTE sql_query;
END;
$$ LANGUAGE plpgsql;



-- Function to gather all riversegments linked to a preselected outlet
DROP FUNCTION IF EXISTS makesegments(schema text, outlet_table text, segment_table text);
CREATE FUNCTION makesegments(schema text, outlet_table text, segment_table text)
RETURNS TABLE(
    objectid bigint,
    geom public.geometry,
    dfdd character varying(5),
    rn_i_id character varying(256),
    rex character varying(256),
    hyp integer,
    loc integer,
    fun integer,
    nvs integer,
    length double precision,
    tr character varying(10),
    longpath double precision,
    cum_len double precision,
    pente double precision,
    cgnelin integer,
    beglifever timestamp without time zone,
    endlifever timestamp without time zone,
    updat_by character varying(15),
    updat_when timestamp without time zone,
    erm_id character varying(256),
    mc integer,
    monot_z integer,
    length_geo double precision,
    inspire_id character varying(256),
    thematicid character varying(42),
    object_id character varying(255),
    tnode character varying(255),
    strahler double precision,
    nametxtint character varying(254),
    nametext character varying(254),
    nextupid character varying(255),
    nextdownid character varying(255),
    fnode character varying(255),
    catchid integer,
    shape_length double precision,
    pfafstetter character varying(255),
    basin text,
    seaoutlet character varying(255)
) 
AS
$$
DECLARE 
	schema TEXT := quote_ident(schema::text);
    seg_table TEXT := quote_ident(segment_table::text);
    out_table TEXT := quote_ident(outlet_table::text);
    sql_query TEXT;
BEGIN 
    sql_query := 
    'WITH RECURSIVE river_tree ("OBJECTID", "NEXTDOWNID", "OBJECT_ID", seaoutlet, basin, depth, is_cycle, path) AS (
        SELECT enr."OBJECTID", enr."NEXTDOWNID", enr."OBJECT_ID", ttn.seaoutlet, enr.basin, 0, FALSE, 
            ARRAY[enr."OBJECT_ID"]::varchar[]
        FROM ' ||schema||'.'|| seg_table || ' enr
        JOIN ' ||schema||'.'|| out_table || ' ttn ON enr."TNODE" = ttn."TNODE"
        UNION ALL
        SELECT enr."OBJECTID", enr."NEXTDOWNID", enr."OBJECT_ID", rt.seaoutlet, rt.basin, rt.depth+1,
            enr."OBJECT_ID" = ANY(path),
            path || ARRAY[rt."OBJECT_ID"]
        FROM ' ||schema||'.'|| seg_table || ' enr
        JOIN river_tree rt ON enr."NEXTDOWNID" = rt."OBJECT_ID" AND NOT is_cycle
    )
    SELECT en.*, river_tree.seaoutlet
    FROM ' ||schema||'.'|| seg_table || ' en
    JOIN river_tree ON (en."OBJECTID", en.basin) = (river_tree."OBJECTID", river_tree.basin)';

    RETURN QUERY EXECUTE sql_query;
END
$$ LANGUAGE plpgsql;

--------------------------------------------------------

-- Preparing tables to be used later
SELECT * FROM altergeometry('angerman');
SELECT create_indexes_and_constraint('angerman');
SELECT * FROM altergeometry('danube');
SELECT create_indexes_and_constraint('danube');
SELECT * FROM altergeometry('duero');
SELECT create_indexes_and_constraint('duero');
SELECT * FROM altergeometry('elbe');
SELECT create_indexes_and_constraint('elbe');
SELECT * FROM altergeometry('ebro');
SELECT create_indexes_and_constraint('ebro');
SELECT * FROM altergeometry('garonne');
SELECT create_indexes_and_constraint('garonne');
SELECT * FROM altergeometry('gota');
SELECT create_indexes_and_constraint('gota');
SELECT * FROM altergeometry('guadalquivir');
SELECT create_indexes_and_constraint('guadalquivir');
SELECT * FROM altergeometry('hondo');
SELECT create_indexes_and_constraint('hondo');
SELECT * FROM altergeometry('iceland');
SELECT create_indexes_and_constraint('iceland');
SELECT * FROM altergeometry('jucar');
SELECT create_indexes_and_constraint('jucar');
SELECT * FROM altergeometry('kemi');
SELECT create_indexes_and_constraint('kemi');
SELECT * FROM altergeometry('loire');
SELECT create_indexes_and_constraint('loire');
SELECT * FROM altergeometry('mesima');
SELECT create_indexes_and_constraint('mesima');
SELECT * FROM altergeometry('nemunas');
SELECT create_indexes_and_constraint('nemunas');
SELECT * FROM altergeometry('neva');
SELECT create_indexes_and_constraint('neva');
SELECT * FROM altergeometry('oder');
SELECT create_indexes_and_constraint('oder');
SELECT * FROM altergeometry('pinios');
SELECT create_indexes_and_constraint('pinios');
SELECT * FROM altergeometry('po');
SELECT create_indexes_and_constraint('po');
SELECT * FROM altergeometry('rhine');
SELECT create_indexes_and_constraint('rhine');
SELECT * FROM altergeometry('rhone');
SELECT create_indexes_and_constraint('rhone');
SELECT * FROM altergeometry('seine');
SELECT create_indexes_and_constraint('seine');
SELECT * FROM altergeometry('shannon');
SELECT create_indexes_and_constraint('shannon');
SELECT * FROM altergeometry('skjern');
SELECT create_indexes_and_constraint('skjern'); --La clé ("OBJECT_ID")=(RL29000634) est dupliquée.
SELECT * FROM altergeometry('tajo');
SELECT create_indexes_and_constraint('tajo'); -- La clé ("OBJECT_ID")=(RL16037148) est dupliquée.
SELECT * FROM altergeometry('tana');
SELECT create_indexes_and_constraint('tana');
SELECT * FROM altergeometry('tevere');
SELECT create_indexes_and_constraint('tevere');
SELECT * FROM altergeometry('thames');
SELECT create_indexes_and_constraint('thames');
SELECT * FROM altergeometry('tirso');
SELECT create_indexes_and_constraint('tirso');
SELECT * FROM altergeometry('turkey');
SELECT create_indexes_and_constraint('turkey');
SELECT * FROM altergeometry('tweed');
SELECT create_indexes_and_constraint('tweed');
SELECT * FROM altergeometry('vistula');
SELECT create_indexes_and_constraint('vistula');
SELECT * FROM altergeometry('vorma');
SELECT create_indexes_and_constraint('vorma');



DROP TABLE IF EXISTS tempo.selected_tnodes_balt_3031;
CREATE TABLE tempo.selected_tnodes_balt_3031 AS
WITH select_outlet AS (
    SELECT * FROM e_neva."euhydro_neva_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_angerman."euhydro_angerman_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_kemi."euhydro_kemi_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_gota."euhydro_gota_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
    ON ST_DWithin(sr.geom, ia.geom, 0.04)
    WHERE ia.subdivisio = ANY(ARRAY['31','30'])
),
select_riv AS (
    SELECT enr.*
    FROM e_neva."euhydro_neva_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_angerman."euhydro_angerman_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_kemi."euhydro_kemi_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_gota."euhydro_gota_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* FROM select_riv;--715


CREATE INDEX idx_selected_tnodes_geom ON tempo.selected_tnodes_balt_3031 USING GIST(geom);
CREATE INDEX idx_t_node ON tempo.selected_tnodes_balt_3031 USING btree("TNODE");
CREATE INDEX idx_f_node ON tempo.selected_tnodes_balt_3031 USING btree("NEXTDOWNID");


DROP TABLE IF EXISTS tempo.e_balt_3031;
CREATE TABLE tempo.e_balt_3031 AS(
	SELECT *, 'neva' AS basin FROM e_neva."euhydro_neva_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'angerman' AS basin FROM e_angerman."euhydro_angerman_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'kemi' AS basin FROM e_kemi."euhydro_kemi_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'gota' AS basin FROM e_gota."euhydro_gota_v013 — River_Net_l"
);--208767
CREATE INDEX idx_selected_e_balt_3031_geom ON tempo.e_balt_3031 USING GIST(geom);
CREATE INDEX idx_t_node_riv ON tempo.e_balt_3031 USING btree("TNODE");
CREATE INDEX idx_nextid_riv ON tempo.e_balt_3031 USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id ON tempo.e_balt_3031 USING btree("OBJECT_ID");
ALTER TABLE tempo.e_balt_3031 ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");



DROP TABLE IF EXISTS e_baltic30to31.riversegments;
CREATE TABLE e_baltic30to31.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_balt_3031','e_balt_3031')
);--131093


-- Columns are in the wrong order in e_nemunas."euhydro_nemunas_v013 — River_Net_l"
SELECT restructurecolumns('nemunas');

DROP TABLE IF EXISTS tempo.selected_tnodes_balt_2732;
CREATE TABLE tempo.selected_tnodes_balt_2732 AS
WITH select_outlet AS (
    SELECT * FROM e_gota."euhydro_gota_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_neva."euhydro_neva_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_nemunas."euhydro_nemunas_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
    ON ST_DWithin(sr.geom, ia.geom, 0.04)
    WHERE ia.subdivisio = ANY(ARRAY['27','28','29','32'])
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_balt_3031 en
    ON inodes."OBJECT_ID" = en."OBJECT_ID"
    WHERE en."OBJECT_ID" IS NULL
),
select_riv AS (
	SELECT enr.*
    FROM e_gota."euhydro_gota_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_neva."euhydro_neva_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_nemunas.riverseg enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--1027

CREATE INDEX idx_selected_tnodes2732_geom ON tempo.selected_tnodes_balt_2732 USING GIST(geom);
CREATE INDEX idx_t_node_2732 ON tempo.selected_tnodes_balt_2732 USING btree("TNODE");
CREATE INDEX idx_next_did2732 ON tempo.selected_tnodes_balt_2732 USING btree("NEXTDOWNID");


DROP TABLE IF EXISTS tempo.e_balt_2732;
CREATE TABLE tempo.e_balt_2732 AS(
		SELECT *, 'neva' AS basin FROM e_neva."euhydro_neva_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'nemunas' AS basin FROM e_nemunas.riverseg
	    UNION ALL
	    SELECT *, 'gota' AS basin FROM e_gota."euhydro_gota_v013 — River_Net_l"
);--116795

CREATE INDEX idx_selected_e_balt_2732_geom ON tempo.e_balt_2732 USING GIST(geom);
CREATE INDEX idx_t_node_2732_riv ON tempo.e_balt_2732 USING btree("TNODE");
CREATE INDEX idx_nextid_2732_riv ON tempo.e_balt_2732 USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_2732 ON tempo.e_balt_2732 USING btree("OBJECT_ID");
ALTER TABLE tempo.e_balt_2732 ADD CONSTRAINT c_uk_object_id_2732 UNIQUE("OBJECT_ID");

CREATE SCHEMA e_baltic27to29_32;
DROP TABLE IF EXISTS e_baltic27to29_32.riversegments;
CREATE TABLE e_baltic27to29_32.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_balt_2732','e_balt_2732')
);--55190


DROP TABLE IF EXISTS tempo.selected_tnodes_balt_2226;
CREATE TABLE tempo.selected_tnodes_balt_2226 AS
WITH select_outlet AS (
    SELECT * FROM e_gota."euhydro_gota_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_elbe."euhydro_elbe_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_nemunas."euhydro_nemunas_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_oder."euhydro_oder_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_skjern."euhydro_skjern_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_vistula."euhydro_vistula_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_areas.ices_areas_20160601_cut_dense_3857 AS ia
    ON ST_DWithin(sr.geom, ia.geom, 0.04)
    WHERE ia.subdivisio = ANY(ARRAY['22','23','24','25','26'])
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_balt_2732 en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
	SELECT enr.*
    FROM e_gota."euhydro_gota_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_elbe."euhydro_elbe_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_nemunas.riverseg enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_oder."euhydro_oder_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_skjern."euhydro_skjern_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_vistula."euhydro_vistula_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--914

CREATE INDEX idx_selected_tnodes2226_geom ON tempo.selected_tnodes_balt_2226 USING GIST(geom);
CREATE INDEX idx_t_node_2226 ON tempo.selected_tnodes_balt_2226 USING btree("TNODE");
CREATE INDEX idx_next_did2226 ON tempo.selected_tnodes_balt_2226 USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_balt_2226;
CREATE TABLE tempo.e_balt_2226 AS(
		SELECT *, 'elbe' AS basin FROM e_elbe."euhydro_elbe_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'nemunas' AS basin FROM e_nemunas.riverseg
	    UNION ALL
	    SELECT *, 'gota' AS basin FROM e_gota."euhydro_gota_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'oder' AS basin FROM e_oder."euhydro_oder_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'skjern' AS basin FROM e_skjern."euhydro_skjern_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'vistula' AS basin FROM e_vistula."euhydro_vistula_v013 — River_Net_l"
);--170520

CREATE INDEX idx_selected_e_balt_2226_geom ON tempo.e_balt_2226 USING GIST(geom);
CREATE INDEX idx_t_node_2226_riv ON tempo.e_balt_2226 USING btree("TNODE");
CREATE INDEX idx_nextid_2226_riv ON tempo.e_balt_2226 USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_2226 ON tempo.e_balt_2226 USING btree("OBJECT_ID");
ALTER TABLE tempo.e_balt_2226 ADD CONSTRAINT c_uk_object_id_2226 UNIQUE("OBJECT_ID"); --pb with skjern, duplicates

CREATE SCHEMA e_baltic22to26;
DROP TABLE IF EXISTS e_baltic22to26.riversegments;
CREATE TABLE e_baltic22to26.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_balt_2226','e_balt_2226')
);--96760 3min30



DROP TABLE IF EXISTS tempo.selected_tnodes_nsean;
CREATE TABLE tempo.selected_tnodes_nsean AS
WITH select_outlet AS (
    SELECT * FROM e_gota."euhydro_gota_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_vorma."euhydro_vorma_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 11
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_balt_2226 en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
	SELECT enr.*
    FROM e_gota."euhydro_gota_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_vorma."euhydro_vorma_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--986

CREATE INDEX idx_selected_tnodes_nsean_geom ON tempo.selected_tnodes_nsean USING GIST(geom);
CREATE INDEX idx_t_node_nsean ON tempo.selected_tnodes_nsean USING btree("TNODE");
CREATE INDEX idx_next_did_nsean ON tempo.selected_tnodes_nsean USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_nsean;
CREATE TABLE tempo.e_nsean AS(
	    SELECT *, 'gota' AS basin FROM e_gota."euhydro_gota_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'vorma' AS basin FROM e_vorma."euhydro_vorma_v013 — River_Net_l"
);--97375

CREATE INDEX idx_selected_e_nsean_geom ON tempo.e_nsean USING GIST(geom);
CREATE INDEX idx_t_node_nsean_riv ON tempo.e_nsean USING btree("TNODE");
CREATE INDEX idx_nextid_nsean_riv ON tempo.e_nsean USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_nsean ON tempo.e_nsean USING btree("OBJECT_ID");
ALTER TABLE tempo.e_nsean ADD CONSTRAINT c_uk_object_id_nsean UNIQUE("OBJECT_ID");

CREATE SCHEMA e_nseanorth;
DROP TABLE IF EXISTS e_nseanorth.riversegments;
CREATE TABLE e_nseanorth.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_nsean','e_nsean')
);--67164



SELECT restructurecolumns('tweed');

DROP TABLE IF EXISTS tempo.selected_tnodes_nseauk;
CREATE TABLE tempo.selected_tnodes_nseauk AS
WITH select_outlet AS (
    SELECT * FROM e_tweed."euhydro_tweed_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_thames."euhydro_thames_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 11
),
select_riv AS (
	SELECT enr.*
    FROM e_tweed.riverseg enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_thames."euhydro_thames_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--407

CREATE INDEX idx_selected_tnodes_nseauk_geom ON tempo.selected_tnodes_nseauk USING GIST(geom);
CREATE INDEX idx_t_node_nseauk ON tempo.selected_tnodes_nseauk USING btree("TNODE");
CREATE INDEX idx_next_did_nseauk ON tempo.selected_tnodes_nseauk USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_nseauk;
CREATE TABLE tempo.e_nseauk AS(
	    SELECT *, 'tweed' AS basin FROM e_tweed.riverseg
	    UNION ALL
	    SELECT *, 'thames' AS basin FROM e_thames."euhydro_thames_v013 — River_Net_l"
);--57965

CREATE INDEX idx_selected_e_nseauk_geom ON tempo.e_nseauk USING GIST(geom);
CREATE INDEX idx_t_node_nseauk_riv ON tempo.e_nseauk USING btree("TNODE");
CREATE INDEX idx_nextid_nseauk_riv ON tempo.e_nseauk USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_nseauk ON tempo.e_nseauk USING btree("OBJECT_ID");
ALTER TABLE tempo.e_nseauk ADD CONSTRAINT c_uk_object_id_nseauk UNIQUE("OBJECT_ID");

CREATE SCHEMA e_nseauk;
DROP TABLE IF EXISTS e_nseauk.riversegments;
CREATE TABLE e_nseauk.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_nseauk','e_nseauk')
);--31617



DROP TABLE IF EXISTS tempo.selected_tnodes_celtic;
CREATE TABLE tempo.selected_tnodes_celtic AS
WITH select_outlet AS (
    SELECT * FROM e_tweed."euhydro_tweed_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_thames."euhydro_thames_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_shannon."euhydro_shannon_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 9
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_nseauk en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
	SELECT enr.*
    FROM e_tweed.riverseg enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_thames."euhydro_thames_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_shannon."euhydro_shannon_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--2470

CREATE INDEX idx_selected_tnodes_celtic_geom ON tempo.selected_tnodes_celtic USING GIST(geom);
CREATE INDEX idx_t_node_celtic ON tempo.selected_tnodes_celtic USING btree("TNODE");
CREATE INDEX idx_next_did_celtic ON tempo.selected_tnodes_celtic USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_celtic;
CREATE TABLE tempo.e_celtic AS(
	    SELECT *, 'tweed' AS basin FROM e_tweed.riverseg
	    UNION ALL
	    SELECT *, 'thames' AS basin FROM e_thames."euhydro_thames_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'shannon' AS basin FROM e_shannon."euhydro_shannon_v013 — River_Net_l"
);--73286

CREATE INDEX idx_selected_e_celtic_geom ON tempo.e_celtic USING GIST(geom);
CREATE INDEX idx_t_node_celtic_riv ON tempo.e_celtic USING btree("TNODE");
CREATE INDEX idx_nextid_celtic_riv ON tempo.e_celtic USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_celtic ON tempo.e_celtic USING btree("OBJECT_ID");
ALTER TABLE tempo.e_celtic ADD CONSTRAINT c_uk_object_id_celtic UNIQUE("OBJECT_ID");

CREATE SCHEMA e_celtic;
DROP TABLE IF EXISTS e_celtic.riversegments;
CREATE TABLE e_celtic.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_celtic','e_celtic')
);--45135



DROP TABLE IF EXISTS tempo.selected_tnodes_iceland;
CREATE TABLE tempo.selected_tnodes_iceland AS
WITH select_outlet AS (
    SELECT * FROM e_iceland."euhydro_iceland_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 13
),
select_riv AS (
	SELECT enr.*
    FROM e_iceland."euhydro_iceland_v013 — River_Net_l" enr
    JOIN ices_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--746

CREATE INDEX idx_selected_tnodes_iceland_geom ON tempo.selected_tnodes_iceland USING GIST(geom);
CREATE INDEX idx_t_node_iceland ON tempo.selected_tnodes_iceland USING btree("TNODE");
CREATE INDEX idx_next_did_iceland ON tempo.selected_tnodes_iceland USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_iceland;
CREATE TABLE tempo.e_iceland AS(
	    SELECT *, 'iceland' AS basin FROM e_iceland."euhydro_iceland_v013 — River_Net_l"
);--15134

CREATE INDEX idx_selected_e_iceland_geom ON tempo.e_iceland USING GIST(geom);
CREATE INDEX idx_t_node_iceland_riv ON tempo.e_iceland USING btree("TNODE");
CREATE INDEX idx_nextid_iceland_riv ON tempo.e_iceland USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_iceland ON tempo.e_iceland USING btree("OBJECT_ID");
ALTER TABLE tempo.e_iceland ADD CONSTRAINT c_uk_object_id_iceland UNIQUE("OBJECT_ID");

--CREATE SCHEMA e_iceland;
DROP TABLE IF EXISTS e_iceland.riversegments;
CREATE TABLE e_iceland.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_iceland','e_iceland')
);--16169


DROP TABLE IF EXISTS tempo.selected_tnodes_norwegian;
CREATE TABLE tempo.selected_tnodes_norwegian AS
WITH select_outlet AS (
    SELECT * FROM e_tana."euhydro_tana_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_vorma."euhydro_vorma_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 16
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_nsean en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_tana."euhydro_tana_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_vorma."euhydro_vorma_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--1247

CREATE INDEX idx_selected_tnodes_norwegian_geom ON tempo.selected_tnodes_norwegian USING GIST(geom);
CREATE INDEX idx_t_node_norwegian ON tempo.selected_tnodes_norwegian USING btree("TNODE");
CREATE INDEX idx_next_did_norwegian ON tempo.selected_tnodes_norwegian USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_norwegian;
CREATE TABLE tempo.e_norwegian AS(
	    SELECT *, 'tana' AS basin FROM e_tana."euhydro_tana_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'vorma' AS basin FROM e_vorma."euhydro_vorma_v013 — River_Net_l"
);--110026

CREATE INDEX idx_selected_e_norwegian_geom ON tempo.e_norwegian USING GIST(geom);
CREATE INDEX idx_t_node_norwegian_riv ON tempo.e_norwegian USING btree("TNODE");
CREATE INDEX idx_nextid_norwegian_riv ON tempo.e_norwegian USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_norwegian ON tempo.e_norwegian USING btree("OBJECT_ID");
ALTER TABLE tempo.e_norwegian ADD CONSTRAINT c_uk_object_id_norwegian UNIQUE("OBJECT_ID");

CREATE SCHEMA e_norwegian;
DROP TABLE IF EXISTS e_norwegian.riversegments;
CREATE TABLE e_norwegian.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_norwegian','e_norwegian')
);--25774



DROP TABLE IF EXISTS tempo.selected_tnodes_barents;
CREATE TABLE tempo.selected_tnodes_barents AS
WITH select_outlet AS (
    SELECT * FROM e_tana."euhydro_tana_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 14
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_norwegian en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
	SELECT enr.*
    FROM e_tana."euhydro_tana_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--1540

CREATE INDEX idx_selected_tnodes_barents_geom ON tempo.selected_tnodes_barents USING GIST(geom);
CREATE INDEX idx_t_node_barents ON tempo.selected_tnodes_barents USING btree("TNODE");
CREATE INDEX idx_next_did_barents ON tempo.selected_tnodes_barents USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_barents;
CREATE TABLE tempo.e_barents AS(
	    SELECT *, 'tana' AS basin FROM e_tana."euhydro_tana_v013 — River_Net_l"
);--58583

CREATE INDEX idx_selected_e_barents_geom ON tempo.e_barents USING GIST(geom);
CREATE INDEX idx_t_node_barents_riv ON tempo.e_barents USING btree("TNODE");
CREATE INDEX idx_nextid_barents_riv ON tempo.e_barents USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_barents ON tempo.e_barents USING btree("OBJECT_ID");
ALTER TABLE tempo.e_barents ADD CONSTRAINT c_uk_object_id_barents UNIQUE("OBJECT_ID");

CREATE SCHEMA e_barents;
DROP TABLE IF EXISTS e_barents.riversegments;
CREATE TABLE e_barents.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_barents','e_barents')
);--46759



DROP TABLE IF EXISTS tempo.selected_tnodes_nseasouth;
CREATE TABLE tempo.selected_tnodes_nseasouth AS
WITH select_outlet AS (
    SELECT * FROM e_elbe."euhydro_elbe_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_loire."euhydro_loire_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_rhine."euhydro_rhine_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_seine."euhydro_seine_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_skjern."euhydro_skjern_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 11
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_balt_2226 en1
    ON ST_DWithin(inodes.geom, en1.geom, 0.0001)
    LEFT JOIN tempo.selected_tnodes_norwegian en2
    ON ST_DWithin(inodes.geom, en2.geom, 0.0001)
    WHERE en1.geom IS NULL AND en2.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_elbe."euhydro_elbe_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_loire."euhydro_loire_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_rhine."euhydro_rhine_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_skjern."euhydro_skjern_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_seine."euhydro_seine_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--821

CREATE INDEX idx_selected_tnodesnseasouth_geom ON tempo.selected_tnodes_nseasouth USING GIST(geom);
CREATE INDEX idx_t_node_nseasouth ON tempo.selected_tnodes_nseasouth USING btree("TNODE");
CREATE INDEX idx_next_didnseasouth ON tempo.selected_tnodes_nseasouth USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_nseasouth;
CREATE TABLE tempo.e_nseasouth AS(
		SELECT *, 'elbe' AS basin FROM e_elbe."euhydro_elbe_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'loire' AS basin FROM e_loire."euhydro_loire_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'rhine' AS basin FROM e_rhine."euhydro_rhine_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'seine' AS basin FROM e_seine."euhydro_seine_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'skjern' AS basin FROM e_skjern."euhydro_skjern_v013 — River_Net_l"
);--142959

CREATE INDEX idx_selected_e_nseasouth_geom ON tempo.e_nseasouth USING GIST(geom);
CREATE INDEX idx_t_node_nseasouth_riv ON tempo.e_nseasouth USING btree("TNODE");
CREATE INDEX idx_nextid_nseasouth_riv ON tempo.e_nseasouth USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_nseasouth ON tempo.e_nseasouth USING btree("OBJECT_ID");
ALTER TABLE tempo.e_nseasouth ADD CONSTRAINT c_uk_object_id_nseasouth UNIQUE("OBJECT_ID"); --pb with skjern, duplicates

CREATE SCHEMA e_nseasouth;
DROP TABLE IF EXISTS e_nseasouth.riversegments;
CREATE TABLE e_nseasouth.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_nseasouth','e_nseasouth')
);--94661 4min



DROP TABLE IF EXISTS tempo.selected_tnodes_biscayiberian;
CREATE TABLE tempo.selected_tnodes_biscayiberian AS
WITH select_outlet AS (
    SELECT * FROM e_duero."euhydro_duero_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_ebro."euhydro_ebro_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_garonne."euhydro_garonne_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_guadalquivir."euhydro_guadalquivir_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_loire."euhydro_loire_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_tajo."euhydro_tajo_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 2
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_nseasouth en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_duero."euhydro_duero_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_ebro."euhydro_ebro_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_garonne."euhydro_garonne_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_guadalquivir."euhydro_guadalquivir_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_loire."euhydro_loire_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_tajo."euhydro_tajo_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--624

CREATE INDEX idx_selected_tnodesbiscayiberian_geom ON tempo.selected_tnodes_biscayiberian USING GIST(geom);
CREATE INDEX idx_t_node_biscayiberian ON tempo.selected_tnodes_biscayiberian USING btree("TNODE");
CREATE INDEX idx_next_didbiscayiberian ON tempo.selected_tnodes_biscayiberian USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_biscayiberian;
CREATE TABLE tempo.e_biscayiberian AS(
		SELECT *, 'duero' AS basin FROM e_duero."euhydro_duero_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'ebro' AS basin FROM e_ebro."euhydro_ebro_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'garonne' AS basin FROM e_garonne."euhydro_garonne_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'guadalquivir' AS basin FROM e_guadalquivir."euhydro_guadalquivir_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'loire' AS basin FROM e_loire."euhydro_loire_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'tajo' AS basin FROM e_tajo."euhydro_tajo_v013 — River_Net_l"
);--172170

CREATE INDEX idx_selected_e_biscayiberian_geom ON tempo.e_biscayiberian USING GIST(geom);
CREATE INDEX idx_t_node_biscayiberian_riv ON tempo.e_biscayiberian USING btree("TNODE");
CREATE INDEX idx_nextid_biscayiberian_riv ON tempo.e_biscayiberian USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_biscayiberian ON tempo.e_biscayiberian USING btree("OBJECT_ID");
ALTER TABLE tempo.e_biscayiberian ADD CONSTRAINT c_uk_object_id_biscayiberian UNIQUE("OBJECT_ID"); --pb with tajo, duplicates

CREATE SCHEMA e_biscayiberian;
DROP TABLE IF EXISTS e_biscayiberian.riversegments;
CREATE TABLE e_biscayiberian.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_biscayiberian','e_biscayiberian')
);--124560 6min



DROP TABLE IF EXISTS tempo.selected_tnodes_medwest;
CREATE TABLE tempo.selected_tnodes_medwest AS
WITH select_outlet AS (
    SELECT * FROM e_ebro."euhydro_ebro_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_guadalquivir."euhydro_guadalquivir_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_jucar."euhydro_jucar_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_mesima."euhydro_mesima_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_po."euhydro_po_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_rhone."euhydro_rhone_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_tevere."euhydro_tevere_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_tirso."euhydro_tirso_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 4
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_biscayiberian en1
    ON ST_DWithin(inodes.geom, en1.geom, 0.0001)
    LEFT JOIN tempo.selected_tnodes_nsean en2
    ON ST_DWithin(inodes.geom, en2.geom, 0.0001)
    WHERE en1.geom IS NULL AND en2.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_jucar."euhydro_jucar_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_ebro."euhydro_ebro_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_mesima."euhydro_mesima_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_guadalquivir."euhydro_guadalquivir_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_po."euhydro_po_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_rhone."euhydro_rhone_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_tevere."euhydro_tevere_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_tirso."euhydro_tirso_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--1646

CREATE INDEX idx_selected_tnodesmedwest_geom ON tempo.selected_tnodes_medwest USING GIST(geom);
CREATE INDEX idx_t_node_medwest ON tempo.selected_tnodes_medwest USING btree("TNODE");
CREATE INDEX idx_next_didmedwest ON tempo.selected_tnodes_medwest USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_medwest;
CREATE TABLE tempo.e_medwest AS(
		SELECT *, 'jucar' AS basin FROM e_jucar."euhydro_jucar_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'ebro' AS basin FROM e_ebro."euhydro_ebro_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'mesima' AS basin FROM e_mesima."euhydro_mesima_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'guadalquivir' AS basin FROM e_guadalquivir."euhydro_guadalquivir_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'po' AS basin FROM e_po."euhydro_po_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'rhone' AS basin FROM e_rhone."euhydro_rhone_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'tevere' AS basin FROM e_tevere."euhydro_tevere_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'tirso' AS basin FROM e_tirso."euhydro_tirso_v013 — River_Net_l"
);--187189

CREATE INDEX idx_selected_e_medwest_geom ON tempo.e_medwest USING GIST(geom);
CREATE INDEX idx_t_node_medwest_riv ON tempo.e_medwest USING btree("TNODE");
CREATE INDEX idx_nextid_medwest_riv ON tempo.e_medwest USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_medwest ON tempo.e_medwest USING btree("OBJECT_ID");
ALTER TABLE tempo.e_medwest ADD CONSTRAINT c_uk_object_id_medwest UNIQUE("OBJECT_ID");

CREATE SCHEMA e_medwest;
DROP TABLE IF EXISTS e_medwest.riversegments;
CREATE TABLE e_medwest.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_medwest','e_medwest')
);--100870 3min



DROP TABLE IF EXISTS tempo.selected_tnodes_medcentral;
CREATE TABLE tempo.selected_tnodes_medcentral AS
WITH select_outlet AS (
    SELECT * FROM e_danube."euhydro_danube_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_pinios."euhydro_pinios_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_mesima."euhydro_mesima_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 5
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_medwest en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_danube."euhydro_danube_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_pinios."euhydro_pinios_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_mesima."euhydro_mesima_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--922

CREATE INDEX idx_selected_tnodesmedcentral_geom ON tempo.selected_tnodes_medcentral USING GIST(geom);
CREATE INDEX idx_t_node_medcentral ON tempo.selected_tnodes_medcentral USING btree("TNODE");
CREATE INDEX idx_next_didmedcentral ON tempo.selected_tnodes_medcentral USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_medcentral;
CREATE TABLE tempo.e_medcentral AS(
		SELECT *, 'danube' AS basin FROM e_danube."euhydro_danube_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'pinios' AS basin FROM e_pinios."euhydro_pinios_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'mesima' AS basin FROM e_mesima."euhydro_mesima_v013 — River_Net_l"
);--215216

CREATE INDEX idx_selected_e_medcentral_geom ON tempo.e_medcentral USING GIST(geom);
CREATE INDEX idx_t_node_medcentral_riv ON tempo.e_medcentral USING btree("TNODE");
CREATE INDEX idx_nextid_medcentral_riv ON tempo.e_medcentral USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_medcentral ON tempo.e_medcentral USING btree("OBJECT_ID");
ALTER TABLE tempo.e_medcentral ADD CONSTRAINT c_uk_object_id_medcentral UNIQUE("OBJECT_ID");

CREATE SCHEMA e_medcentral;
DROP TABLE IF EXISTS e_medcentral.riversegments;
CREATE TABLE e_medcentral.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_medcentral','e_medcentral')
);--17249



DROP TABLE IF EXISTS tempo.selected_tnodes_medeast;
CREATE TABLE tempo.selected_tnodes_medeast AS
WITH select_outlet AS (
    SELECT * FROM e_pinios."euhydro_pinios_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_turkey."euhydro_turkey_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 8
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_medcentral en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_pinios."euhydro_pinios_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_turkey."euhydro_turkey_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--2068

CREATE INDEX idx_selected_tnodesmedeast_geom ON tempo.selected_tnodes_medeast USING GIST(geom);
CREATE INDEX idx_t_node_medeast ON tempo.selected_tnodes_medeast USING btree("TNODE");
CREATE INDEX idx_next_didmedeast ON tempo.selected_tnodes_medeast USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_medeast;
CREATE TABLE tempo.e_medeast AS(
	    SELECT *, 'pinios' AS basin FROM e_pinios."euhydro_pinios_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'turkey' AS basin FROM e_turkey."euhydro_turkey_v013 — River_Net_l"
);--114493

CREATE INDEX idx_selected_e_medeast_geom ON tempo.e_medeast USING GIST(geom);
CREATE INDEX idx_t_node_medeast_riv ON tempo.e_medeast USING btree("TNODE");
CREATE INDEX idx_nextid_medeast_riv ON tempo.e_medeast USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_medeast ON tempo.e_medeast USING btree("OBJECT_ID");
ALTER TABLE tempo.e_medeast ADD CONSTRAINT c_uk_object_id_medeast UNIQUE("OBJECT_ID");

CREATE SCHEMA e_medeast;
DROP TABLE IF EXISTS e_medeast.riversegments;
CREATE TABLE e_medeast.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_medeast','e_medeast')
);--48331 2min



DROP TABLE IF EXISTS tempo.selected_tnodes_blacksea;
CREATE TABLE tempo.selected_tnodes_blacksea AS
WITH select_outlet AS (
    SELECT * FROM e_pinios."euhydro_pinios_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_turkey."euhydro_turkey_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_danube."euhydro_danube_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 6
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_medeast en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_pinios."euhydro_pinios_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_turkey."euhydro_turkey_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_danube."euhydro_danube_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--597

CREATE INDEX idx_selected_tnodesblacksea_geom ON tempo.selected_tnodes_blacksea USING GIST(geom);
CREATE INDEX idx_t_node_blacksea ON tempo.selected_tnodes_blacksea USING btree("TNODE");
CREATE INDEX idx_next_didblacksea ON tempo.selected_tnodes_blacksea USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_blacksea;
CREATE TABLE tempo.e_blacksea AS(
	    SELECT *, 'pinios' AS basin FROM e_pinios."euhydro_pinios_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'turkey' AS basin FROM e_turkey."euhydro_turkey_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'danube' AS basin FROM e_danube."euhydro_danube_v013 — River_Net_l"
);--266922

CREATE INDEX idx_selected_e_blacksea_geom ON tempo.e_blacksea USING GIST(geom);
CREATE INDEX idx_t_node_blacksea_riv ON tempo.e_blacksea USING btree("TNODE");
CREATE INDEX idx_nextid_blacksea_riv ON tempo.e_blacksea USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_blacksea ON tempo.e_blacksea USING btree("OBJECT_ID");
ALTER TABLE tempo.e_blacksea ADD CONSTRAINT c_uk_object_id_blacksea UNIQUE("OBJECT_ID");

CREATE SCHEMA e_blacksea;
DROP TABLE IF EXISTS e_blacksea.riversegments;
CREATE TABLE e_blacksea.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_blacksea','e_blacksea')
);--154299 22min



DROP TABLE IF EXISTS tempo.selected_tnodes_adriatic;
CREATE TABLE tempo.selected_tnodes_adriatic AS
WITH select_outlet AS (
    SELECT * FROM e_pinios."euhydro_pinios_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_mesima."euhydro_mesima_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_danube."euhydro_danube_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_tevere."euhydro_tevere_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
    UNION ALL
    SELECT * FROM e_po."euhydro_po_v013 — Nodes" WHERE "HYDRONODCT" = 'Outlet'
),
ices_nodes AS (
    SELECT sr.*
    FROM select_outlet sr
    JOIN ices_ecoregions.ices_ecoregions_20171207_erase_esri AS er
    ON ST_DWithin(sr.geom, er.geom, 0.04)
    WHERE er.objectid = 7
),
filtered_nodes AS (
    SELECT inodes.*
    FROM ices_nodes inodes
    LEFT JOIN tempo.selected_tnodes_medcentral en
    ON ST_DWithin(inodes.geom, en.geom, 0.0001)
    WHERE en.geom IS NULL
),
select_riv AS (
    SELECT enr.*
    FROM e_pinios."euhydro_pinios_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_mesima."euhydro_mesima_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_danube."euhydro_danube_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_po."euhydro_po_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
    UNION ALL
    SELECT enr.*
    FROM e_tevere."euhydro_tevere_v013 — River_Net_l" enr
    JOIN filtered_nodes ir ON enr."TNODE" = ir."OBJECT_ID"
)
SELECT DISTINCT ON ("OBJECT_ID") "OBJECT_ID" AS seaoutlet, select_riv.* 
FROM select_riv;--749

CREATE INDEX idx_selected_tnodesadriatic_geom ON tempo.selected_tnodes_adriatic USING GIST(geom);
CREATE INDEX idx_t_node_adriatic ON tempo.selected_tnodes_adriatic USING btree("TNODE");
CREATE INDEX idx_next_didadriatic ON tempo.selected_tnodes_adriatic USING btree("NEXTDOWNID");

DROP TABLE IF EXISTS tempo.e_adriatic;
CREATE TABLE tempo.e_adriatic AS(
	    SELECT *, 'pinios' AS basin FROM e_pinios."euhydro_pinios_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'mesima' AS basin FROM e_mesima."euhydro_mesima_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'danube' AS basin FROM e_danube."euhydro_danube_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'tevere' AS basin FROM e_tevere."euhydro_tevere_v013 — River_Net_l"
	    UNION ALL
	    SELECT *, 'po' AS basin FROM e_po."euhydro_po_v013 — River_Net_l"
);--282579

CREATE INDEX idx_selected_e_adriatic_geom ON tempo.e_adriatic USING GIST(geom);
CREATE INDEX idx_t_node_adriatic_riv ON tempo.e_adriatic USING btree("TNODE");
CREATE INDEX idx_nextid_adriatic_riv ON tempo.e_adriatic USING btree("NEXTDOWNID");
CREATE INDEX idx_obj_id_adriatic ON tempo.e_adriatic USING btree("OBJECT_ID");
ALTER TABLE tempo.e_adriatic ADD CONSTRAINT c_uk_object_id_adriatic UNIQUE("OBJECT_ID");

CREATE SCHEMA e_adriatic;
DROP TABLE IF EXISTS e_adriatic.riversegments;
CREATE TABLE e_adriatic.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes_adriatic','e_adriatic')
);--71543 3min
