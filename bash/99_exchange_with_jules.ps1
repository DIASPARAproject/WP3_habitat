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

C:\"Program Files"\PostgreSQL\16\bin\pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@$env:hostdiaspara/hydroatlas.backup