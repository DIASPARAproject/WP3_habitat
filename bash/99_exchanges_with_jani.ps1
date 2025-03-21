# to set variables before the script without admin access to path
# run first the script jani_variable_do_not_commit.ps1
# you can paste the content to powershell it will set up the variables



# This part you will only ever need to run once.
#first create the database
CREATEDB -U ${env:userlocal} diaspara 
# second step set the users in the server (set the right path for you)
$pathsql = "C:\Users\03224501\OneDrive - Valtion\GitHub\WP3_habitat\SQL\create_role_diaspara.sql"

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -f $pathsql

# delete the schema first before transferring the same named schema. NOTE: cascade if there is a vue or anything else inside
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_baltic22to26 cascade"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_baltic27to29_32 cascade"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_baltic30to31 cascade"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_adriatic cascade"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_barents cascade"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara -c "drop schema h_biscayiberian cascade"


# testing the dump of just one schema
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_barents -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara

#OR OTHER OPTION save the distantschema locally and transfer to local db. as compressed file
cd "C:\Users\03224501\Downloads"
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_barents -v -Fc -f "h_barents.backup"
#because it was compressed, we need to restore, instead of psql
pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara "h_barents.backup"


#Get all Schemas
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema ref -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_adriatic -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_baltic22to26 -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_baltic27to29_32 -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_baltic30to31 -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_biscayiberian -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara --schema h_blacksea -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${127.0.0.1}/diaspara

#OR as a list

$schemas = @(
    "h_celtic",
    "h_iceland",
    "h_medcentral",
    "h_medeast",
    "h_medwest",
    "h_norwegian",
    "h_nseanorth",
    "h_nseasouth",
    "h_nseauk",
    "h_southatlantic",
    "h_southmedcentral",
    "h_southmedeast",
    "h_southmedwest",
    "h_svalbard",
    "janis",
    "refbast",
    "tempo"
)
foreach ($schema in $schemas) {
    pg_dump --dbname="postgresql://${env:usermercure}:${env:passmercure}@${env:hostdiaspara}/diaspara" --schema $schema -v | psql --dbname="postgresql://${env:userlocal}:${env:passlocal}@127.0.0.1/diaspara"
}






psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/postgres -c "DROP DATABASE diaspara"
cd "C:\Users\cedric.briand\OneDrive - EPTB Vilaine\partage\diaspara"
C:\"Program Files"\PostgreSQL\16\bin\pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara diaspara_03102024.backup
CREATEDB -U ${env:userlocal} diaspara 
C:\"Program Files"\PostgreSQL\16\bin\pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara diaspara_03102024.backup

pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/hydroatlas.backup

# CÃ©dric 09/01/2025
D:
cd sauv_base
pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -Fc --create --schema dat --schema datang --schema datnas --schema datbast --schema ref --schema refang --schema refnas --schema refbast -f diaspara_03012025_cedric.backup

# Dump to server





