# create database localhost
# set env variables 
# for this type path in the command and set the following variables
# hostdiaspara
# passdiaspara
# userdiaspara
# userlocal
# passlocal
# usermercure
# passmercure
# hostmercure

# Where userdiaspara and passdiaspara are the names of the user in the group
# diaspara, and where userlocal and passlocal are admin local users


CREATEDB -U ${env:userlocal} - diaspara
$pathsql = "C:\workspace\WP3_habitat\SQL\create_role_diaspara.sql"
# grant appropriate rights in localhost
psql  --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -f ${pathsql} 
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "create schema ccm21" diaspara
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "create schema ccm" diaspara
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "GRANT USAGE ON SCHEMA public TO diaspara_admin ;" 
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "GRANT ALL PRIVILEGES ON SCHEMA ccm TO diaspara_admin ;" 

# currently I've set hostdiaspara to 127.0.0.1 in path



# dump ccm tables to local
# catchments (mémoire insuffisante) need to use two steps
pg_dump --table ccm21.catchments -Fc -f "D:/dump/catchments.backup" --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 
pg_restore --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara "D:/dump/catchments.backup"
# coast OK
pg_dump --table ccm21.coast --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
# Islands
pg_dump --table ccm21.islands  --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
# lakes
pg_dump --table ccm21.lakes --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
# mainrivers
pg_dump --table ccm21.mainrivers --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
#namderivers
pg_dump --table ccm21.namedrivers -Fc -f namedrivers.dump --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
#rivernodes
pg_dump --table ccm21.rivernodes --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
# riversegments
pg_dump --table ccm21.riversegments --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara
# seaoutlets
pg_dump --table ccm21.seaoutlets --dbname postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/eda2.0 |psql --dbname postgresql://${env:userlocal}:${env:passlocal}@${env:hostdiaspara}/diaspara



psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "alter schema ccm rename to ccm21" 



# import HydroATLAS

psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "create schema hydroa" 
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "GRANT USAGE ON SCHEMA public TO diaspara_admin ;" 
psql --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/diaspara -c "GRANT ALL PRIVILEGES ON SCHEMA hydroa TO diaspara_admin ;" 

