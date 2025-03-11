
CREATE SCHEMA e_angerman;
CREATE SCHEMA e_danube;
CREATE SCHEMA e_duero;
CREATE SCHEMA e_erbo;
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



ALTER TABLE e_neva."euhydro_neva_v013 — River_Net_l"
	ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_angerman."euhydro_angerman_v013 — River_Net_l"
	ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_kemi."euhydro_kemi_v013 — River_Net_l"
	ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_gota."euhydro_gota_v013 — River_Net_l"
	ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_neva."euhydro_neva_v013 — Nodes"
	ALTER COLUMN geom TYPE geometry(Point, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_angerman."euhydro_angerman_v013 — Nodes"
	ALTER COLUMN geom TYPE geometry(Point, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_kemi."euhydro_kemi_v013 — Nodes"
	ALTER COLUMN geom TYPE geometry(Point, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);

ALTER TABLE e_gota."euhydro_gota_v013 — Nodes"
	ALTER COLUMN geom TYPE geometry(Point, 4326)
	USING ST_Transform(ST_Force2D(geom), 4326);


CREATE INDEX idx_selected_tnodes_geom ON tempo.selected_tnodes USING GIST(geom);
CREATE INDEX idx_t_node ON tempo.selected_tnodes USING btree("TNODE");
CREATE INDEX idx_f_node ON tempo.selected_tnodes USING btree("FNODE");
CREATE INDEX idx_t_node_neva_riv ON e_neva."euhydro_neva_v013 — River_Net_l" USING btree("TNODE");
CREATE INDEX idx_f_node_neva_riv ON e_neva."euhydro_neva_v013 — River_Net_l" USING btree("FNODE");
CREATE INDEX idx_obj_id_neva ON e_neva."euhydro_neva_v013 — River_Net_l" USING btree("OBJECT_ID");
CREATE INDEX idx_t_node_neva_riv ON e_angerman."euhydro_angerman_v013 — River_Net_l" USING btree("TNODE");
CREATE INDEX idx_f_node_neva_riv ON e_angerman."euhydro_angerman_v013 — River_Net_l" USING btree("FNODE");
CREATE INDEX idx_obj_id_neva ON e_angerman."euhydro_angerman_v013 — River_Net_l" USING btree("OBJECT_ID");
CREATE INDEX idx_t_node_neva_riv ON e_kemi."euhydro_kemi_v013 — River_Net_l" USING btree("TNODE");
CREATE INDEX idx_f_node_neva_riv ON e_kemi."euhydro_kemi_v013 — River_Net_l" USING btree("FNODE");
CREATE INDEX idx_obj_id_neva ON e_kemi."euhydro_kemi_v013 — River_Net_l" USING btree("OBJECT_ID");
CREATE INDEX idx_t_node_neva_riv ON e_gota."euhydro_gota_v013 — River_Net_l" USING btree("TNODE");
CREATE INDEX idx_f_node_neva_riv ON e_gota."euhydro_gota_v013 — River_Net_l" USING btree("FNODE");
CREATE INDEX idx_obj_id_neva ON e_gota."euhydro_gota_v013 — River_Net_l" USING btree("OBJECT_ID");
ALTER TABLE e_neva."euhydro_neva_v013 — River_Net_l" ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");
ALTER TABLE e_angerman."euhydro_angerman_v013 — River_Net_l" ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");
ALTER TABLE e_kemi."euhydro_kemi_v013 — River_Net_l" ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");
ALTER TABLE e_gota."euhydro_gota_v013 — River_Net_l" ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");


--------------------- Function creation ---------------------

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


DROP TABLE IF EXISTS tempo.selected_tnodes;
CREATE TABLE tempo.selected_tnodes AS
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


CREATE INDEX idx_selected_tnodes_geom ON tempo.selected_tnodes USING GIST(geom);
CREATE INDEX idx_t_node ON tempo.selected_tnodes USING btree("TNODE");
CREATE INDEX idx_f_node ON tempo.selected_tnodes USING btree("FNODE");


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
CREATE INDEX idx_f_node_riv ON tempo.e_balt_3031 USING btree("FNODE");
CREATE INDEX idx_obj_id ON tempo.e_balt_3031 USING btree("OBJECT_ID");
ALTER TABLE tempo.e_balt_3031 ADD CONSTRAINT c_uk_object_id UNIQUE("OBJECT_ID");



DROP TABLE IF EXISTS e_baltic30to31.riversegments;
CREATE TABLE e_baltic30to31.riversegments AS(
SELECT * FROM makesegments('tempo','selected_tnodes','e_balt_3031')
);--131093 4min


