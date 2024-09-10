# create database localhost

CREATEDB -U postgres diaspara

# import CCM

psql -U postgres -c "create schema ccm" diaspara
psql -U postgres -c "GRANT USAGE ON SCHEMA public TO diaspara_admin ;" diaspara
psql -U postgres -c "GRANT ALL PRIVILEGES ON SCHEMA ccm TO diaspara_admin ;" diaspara

# currently I've set hostdiaspara to 127.0.0.1 in path


# test
env:userjules
# env:test = 'test' -- to set variables before the script without admin access to path
# env:userjules
psql --dbname=postgresql://${env:userjules}:${env:passjules}@$env:hostdiaspara/diaspara

# dump ccm tables to local
pg_dump --table ccm21.catchments -Fc -f catchments.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.coast -Fc -f coast.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.islands -Fc -f islands.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.lakes -Fc -f lakes.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.mainrivers -Fc -f mainrivers.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.namedrivers -Fc -f namedrivers.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.rivernodes -Fc -f rivernodes.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.riversegments -Fc -f riversegments.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara
pg_dump --table ccm21.seaoutlets -Fc -f seaoutlets.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userjules}:${env:passjules}@${env:hostdiaspara}/diaspara