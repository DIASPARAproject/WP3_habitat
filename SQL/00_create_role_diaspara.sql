
-- each role groups will appear and all databases
CREATE ROLE diaspara_admin;
CREATE ROLE diaspara_read;


-- Should be done only once
--- group management
-- TODO ne donner
-- GRANT { role_name | ALL [ PRIVILEGES ] }     TO { [ GROUP ] role_specification | username | CURRENT_USER | SESSION_USER } [, ...]    [ WITH ADMIN OPTION ]

GRANT ALL PRIVILEGES ON SCHEMA public TO diaspara_admin ;

CREATE ROLE jules WITH 
  NOSUPERUSER
  CREATEDB
  CREATEROLE
  INHERIT
  LOGIN
  CONNECTION LIMIT -1;

--- ALTER ROLE jules IN DATABASE "diaspara" SET search_path="$user", public;

CREATE ROLE cedric WITH 
  NOSUPERUSER
  CREATEDB
  CREATEROLE
  INHERIT
  LOGIN
  CONNECTION LIMIT -1;
ALTER ROLE cedric WITH password '****'; --c
--- ALTER ROLE jules IN DATABASE "diaspara" SET search_path="$user", public;

CREATE ROLE jani WITH 
  NOSUPERUSER
  CREATEDB
  CREATEROLE
  INHERIT
  LOGIN
  CONNECTION LIMIT -1;
ALTER ROLE jani WITH password '*****************'; --c
--- ALTER ROLE jules IN DATABASE "diaspara" SET search_path="$user", public;



--- GRANT DBEel_DBManager TO lbeaulaton WITH ADMIN OPTION;
GRANT diaspara_admin TO jules ;
GRANT diaspara_admin TO cedric ;
GRANT diaspara_admin TO jani ;



-- Should be done each time the database is created
--- role management
GRANT CONNECT ON DATABASE "diaspara" TO diaspara_read;
ALTER DATABASE "diaspara" OWNER TO diaspara_admin;

--- extension management
CREATE EXTENSION "uuid-ossp" SCHEMA "public";
CREATE EXTENSION postgis SCHEMA "public";
CREATE EXTENSION postgis_topology;


 --SELECT spcname FROM pg_tablespace;
 --ALTER DATABASE diaspara SET TABLESPACE data1;


-- just to get the schema names currently saved by Jules
select schema_name
from information_schema.schemata;


DROP FUNCTION IF EXISTS change_owner(schema_ TEXT, owner_ TEXT);
CREATE OR REPLACE FUNCTION change_owner(schema_ TEXT, owner_ TEXT)
RETURNS INTEGER AS
$$
DECLARE 
    schema_name_ident TEXT := quote_ident(schema_);
    schema_name_text TEXT := quote_literal(schema_);
    tbl TEXT;
    count_ INTEGER := 0;
    query TEXT ;
    query1 TEXT ;
BEGIN
  
    -- Loop through each table in the specified schema
    FOR tbl IN EXECUTE 
        'SELECT tablename
        FROM pg_catalog.pg_tables
        WHERE schemaname = ' ||  schema_name_text  
    LOOP
        --RAISE NOTICE 'schema %', schema_name_ident;
        -- RAISE NOTICE 'count %', count_;
        -- Alter the owner of each table
        query := 'ALTER TABLE ' || schema_name_ident || '.' || tbl || ' OWNER TO ' || owner_  ;
       EXECUTE query;
        RAISE NOTICE 'query %', query;
        count_ = count_ + 1;
   END LOOP;
      query1 := 'GRANT ALL ON SCHEMA ' || schema_name_ident || '  TO ' || owner_ ;
      EXECUTE query1;
RETURN count_;
END;
$$ LANGUAGE plpgsql;
GRANT ALL  ON SCHEMA h_baltic22to26 TO diaspara_admin;
SELECT change_owner('h_baltic30to31', 'diaspara_admin');
SELECT change_owner('h_baltic27to29_32', 'diaspara_admin');
SELECT change_owner('h_baltic22to26', 'diaspara_admin');
SELECT change_owner('h_adriatic', 'diaspara_admin');
SELECT change_owner('h_barents', 'diaspara_admin');
SELECT change_owner('h_blacksea', 'diaspara_admin');
SELECT change_owner('h_celtic', 'diaspara_admin');
SELECT change_owner('h_iceland', 'diaspara_admin');
SELECT change_owner('h_medcentral', 'diaspara_admin');
SELECT change_owner('h_medeast', 'diaspara_admin');
SELECT change_owner('h_medwest', 'diaspara_admin');
SELECT change_owner('h_norwegian', 'diaspara_admin');
SELECT change_owner('h_nseanorth', 'diaspara_admin');
SELECT change_owner('h_nseasouth', 'diaspara_admin');
SELECT change_owner('h_nseauk', 'diaspara_admin');
SELECT change_owner('h_biscayiberian', 'diaspara_admin');
SELECT change_owner('ref', 'diaspara_admin');
SELECT change_owner('janis', 'diaspara_admin');
