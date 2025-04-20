# test
#env:userjules
# env:test = 'test' -- to set variables before the script without admin access to path
# env:userjules
#psql --dbname=postgresql://${env:userjules}:${env:passjules}@$env:hostdiaspara/diaspara


# dump state from JULES

# Jules
pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -Fc --create -f diaspara_03102024.backup

# Cedric
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/postgres -c "DROP DATABASE diaspara"
cd "C:\Users\cedric.briand\OneDrive - EPTB Vilaine\partage\diaspara"
C:\"Program Files"\PostgreSQL\16\bin\pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara diaspara_03102024.backup
CREATEDB -U ${env:userlocal} diaspara 
C:\"Program Files"\PostgreSQL\16\bin\pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara diaspara_03102024.backup

pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/hydroatlas.backup

# Cédric 09/01/2025
D:
cd sauv_base
pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -Fc --create --schema dat --schema datang --schema datnas --schema datbast --schema ref --schema refang --schema refnas --schema refbast -f diaspara_03012025_cedric.backup

# Dump to server
pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara --schema h_barent -v | psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara


# cedric 20/04/2024. Dumping work from localhost to server
# ref
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_lifestage_lfs CASCADE;"
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_species_spe CASCADE;"
# will drop ref.tr_metadata_met
# will drop ref.tr_version_ver
# will drop refnas.tr_version_ver
# will drop refnas. tr_metadata_met
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_maturity_mat CASCADE;"
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_quality_qal CASCADE;"

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_metadata_met CASCADE;"
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_version_ver CASCADE;"

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_lifestage_lfs CASCADE;"

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_species_spe CASCADE;"

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_category_cat CASCADE;"
psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists ref.tr_destination_des CASCADE;"


# Dump to server
pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara --table ref.tr_lifestage_lfs --table ref.tr_maturity_mat --table ref.tr_quality_qal --table ref.tr_version_ver --table  ref.tr_species_spe --table ref.tr_destination_des --table ref.tr_category_cat -v | psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara

pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara --table ref.tr_metadata_met -v | psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists refnas.tr_metadata_met CASCADE;"

psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -c "DROP TABLE if exists refnas.tr_version_ver CASCADE;"

pg_dump --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara --table refnas.tr_version_ver --table refnas.tr_metadata_met -v | psql --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara


# For Jani and Jules to dump to localhost (normally you don't have these tables
# or the version needs replacement.)

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_maturity_mat CASCADE;"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_quality_qal CASCADE;"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_metadata_met CASCADE;"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_version_ver CASCADE;"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_lifestage_lfs CASCADE;"

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_species_spe CASCADE;"
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_category_cat CASCADE;"

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists ref.tr_destination_des CASCADE;"

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists refnas.tr_metadata_met CASCADE;"

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara -c "DROP TABLE if exists refnas.tr_version_ver CASCADE;"


pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara  --table ref.tr_lifestage_lfs --table ref.tr_maturity_mat --table ref.tr_quality_qal --table ref.tr_version_ver --table  ref.tr_species_spe --table ref.tr_destination_des --table ref.tr_category_cat --table ref.tr_metadata_met -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara --table refnas.tr_version_ver --table refnas.tr_metadata_met -v | psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara