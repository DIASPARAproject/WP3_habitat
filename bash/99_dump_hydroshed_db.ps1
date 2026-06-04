# run in powershell
pg_dump -U postgres -F custom -d diaspara -n h_adriatic > h_adriatic.pgc
pg_dump -U postgres -F custom -d diaspara -n h_baltic22to26 > h_baltic22to26.pgc
pg_dump -U postgres -F custom -d diaspara -n h_baltic27to29_32 > h_baltic27to29_32.pgc
pg_dump -U postgres -F custom -d diaspara -n h_baltic30to31 > h_baltic30to31.pgc
pg_dump -U postgres -F custom -d diaspara -n h_barents > h_barents.pgc
pg_dump -U postgres -F custom -d diaspara -n h_biscayiberian > h_biscayiberian.pgc
pg_dump -U postgres -F custom -d diaspara -n h_blacksea > h_blacksea.pgc
pg_dump -U postgres -F custom -d diaspara -n h_celtic > h_celtic.pgc
pg_dump -U postgres -F custom -d diaspara -n h_iceland > h_iceland.pgc
pg_dump -U postgres -F custom -d diaspara -n h_medcentral > h_medcentral.pgc

pg_dump -U postgres -F custom -d diaspara -n h_medwest > h_medwest.pgc
pg_dump -U postgres -F custom -d diaspara -n h_norwegian > h_norwegian.pgc
pg_dump -U postgres -F custom -d diaspara -n h_nseanorth > h_nseanorth.pgc
pg_dump -U postgres -F custom -d diaspara -n h_nseasouth > h_nseasouth.pgc
pg_dump -U postgres -F custom -d diaspara -n h_nseauk > h_nseauk.pgc
pg_dump -U postgres -F custom -d diaspara -n h_southatlantic > h_southatlantic.pgc
pg_dump -U postgres -F custom -d diaspara -n h_southmedcentral > h_southmedcentral.pgc
pg_dump -U postgres -F custom -d diaspara -n h_southmedeast > h_southmedeast.pgc
pg_dump -U postgres -F custom -d diaspara -n h_southmedwest > h_southmedwest.pgc
pg_dump -U postgres -F custom -d diaspara -n h_svalbard > h_svalbard.pgc

# pg_dump -U postgres -F custom -d diaspara -t ref.tr_area_are > ref_area.pgc
# pg_dump -U postgres -F custom -d diaspara -t refnas.tr_area_are > refnas_area.pgc
# pg_dump -U postgres -F custom -d diaspara -t refbast.tr_area_are > 

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t ref.tr_habitatlevel_lev -t ref.tr_icworkinggroup_wkg > ref.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t refnas.tr_area_are -t refnas.tr_rivernames_riv > refnas.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t refbast.tr_area_are -t refbast.landings_wbast_river_names -t refbast.tr_rivernames_riv > refbast.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercureinternal}/diaspara -F custom -t refeel.tr_area_are > refeel.pgc


cd C:\workspace\DIASPARA_WP3_habitat\download_zenodo

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercureinternal}/diaspara -Fc -f all_ref.pgc 
-t ref.tr_rivernames_riv 
-t ref.tr_habitatlevel_lev 
-t ref.tr_icworkinggroup_wkg 
-t ref.tr_area_are  
-t refnas.tr_area_are 
-t refnas.tr_rivernames_riv 
-t refbast.tr_area_are 
-t refbast.landings_wbast_river_names 
-t refbast.tr_rivernames_riv 
-t refeel.tr_area_are  

# List of schemas to dump
$schemas = @(
    "h_adriatic"
    "h_baltic22to26",
    "h_baltic27to29_32",
    "h_baltic30to31",
    "h_barents",
    "h_biscayiberian",
    "h_blacksea",
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
    "h_svalbard"
)

# Loop over schemas
foreach ($schema in $schemas) {
    $outfile = "$schema.pgc"
    
    pg_dump `
        --dbname="postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercureinternal}/diaspara" `
        -Fc `
        -n $schema `
        -f $outfile

    Write-Host "Dumped $schema → $outfile"
}

-- test pg_restore
pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@127.0.0.1/test -v h_adriatic.pgc

pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@127.0.0.1/test -v h_southmedwest.pgc

# Copy and paste as one line
pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercureinternal}/diaspara -Fc 
-t ref.tr_rivernames_riv 
-t ref.tr_habitatlevel_lev 
-t ref.tr_icworkinggroup_wkg 
-t ref.tr_area_are  
-t refnas.tr_area_are 
-t refnas.tr_rivernames_riv 
-t refbast.tr_area_are 
-t refbast.landings_wbast_river_names 
-t refbast.tr_rivernames_riv 
-t refeel.tr_area_are  
-n habitat 
-n h_adriatic  
-n h_baltic22to26 
-n h_baltic27to29_32 
-n h_baltic30to31 
-n h_barents 
-n h_biscayiberian 
-n h_blacksea 
-n h_celtic 
-n h_iceland 
-n h_medcentral 
-n h_medeast 
-n h_medwest 
-n h_norwegian 
-n h_nseanorth 
-n h_nseasouth 
-n h_nseauk 
-n h_southatlantic 
-n h_southmedcentral 
-n h_southmedeast 
-n h_southmedwest 
-n h_svalbard 
-f all_habitat.pgc

psql -U postgres -c "DROP database test;"
CREATEDB -U postgres test
psql -U postgres -c "CREATE EXTENSION POSTGIS; CREATE SCHEMA ref; CREATE SCHEMA refeel; CREATE SCHEMA refnas; CREATE SCHEMA refbast;" test


# test
pg_restore --dbname=postgresql://${env:userlocal}:${env:passlocal}@127.0.0.1/test -v all_habitat.pgc

# save shapefile
 pgsql2shp -u ${env:usermercure} -h ${env:hostmercureinternal} -P ${env:passmercure} -f "ref_tr_area_are_geom_polygon.shp" -g "geom_polygon" "diaspara" "select are_id,are_are_id,are_code,are_lev_code,are_wkg_code,are_ismarine,are_name,geom_polygon from ref.tr_area_are"

 pgsql2shp -u ${env:usermercure} -h ${env:hostmercureinternal} -P ${env:passmercure} -f "ref_tr_area_are_geom_line.shp" -g "geom_line" "diaspara" "select are_id,are_are_id,are_code,are_lev_code,are_wkg_code,are_ismarine,are_name,geom_line from ref.tr_area_are"
