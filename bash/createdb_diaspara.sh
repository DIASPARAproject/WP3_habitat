# create database localhost

CREATEDB -U postgres diaspara

# import CCM

psql -U postgres -c "create schema ccm" diaspara
psql -U postgres -c "GRANT USAGE ON SCHEMA public TO diaspara_admin ;" diaspara
psql -U postgres -c "GRANT ALL PRIVILEGES ON SCHEMA ccm TO diaspara_admin ;" diaspara

# currently I've set hostdiaspara to 127.0.0.1 in path


# test
env:usercedric
# env:test = 'test' -- to set variables before the script without admin access to path
psql --dbname=postgresql://${env:usercedric}:${env:passcedric}@$env:hostdiaspara/diaspara


pg_dump --table ccm21.catchments --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname=postgresql://${env:usercedric}:${env:passcedric}@${env:hostdiaspara}/diaspara  
coast
islands
lakes
mainrivers
namedrivers
rivernodes
riversegments
seaoutlets