
-- each role groups will appear and all databases
CREATE ROLE diaspara_admin;
CREATE ROLE diaspara_read;
CREATE ROLE diaspara_france_admin; -- administrateur pour un schema

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
ALTER ROLE cedric WITH password '***************'; --c
--- ALTER ROLE jules IN DATABASE "diaspara" SET search_path="$user", public;



--- GRANT DBEel_DBManager TO lbeaulaton WITH ADMIN OPTION;
GRANT diaspara_admin TO jules ;
GRANT diaspara_france_admin TO jules ;
GRANT diaspara_admin TO cedric ;
GRANT diaspara_france_admin TO cedric ;

-- Should be done each time the database is created
--- role management
GRANT CONNECT ON DATABASE "diaspara" TO diaspara_read;
ALTER DATABASE "diaspara" OWNER TO diaspara_admin;

--- extension management
CREATE EXTENSION "uuid-ossp" SCHEMA "public";
CREATE EXTENSION postgis SCHEMA "public";
CREATE EXTENSION postgis_topology;


 