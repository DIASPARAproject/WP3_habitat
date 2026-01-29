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
# pg_dump -U postgres -F custom -d diaspara -t refbast.tr_area_are > refbast_area.pgc


pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t ref.tr_habitatlevel_lev -t ref.tr_icworkinggroup_wkg > ref.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t refnas.tr_area_are -t refnas.tr_rivernames_riv > refnas.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t refbast.tr_area_are -t refbast.landings_wbast_river_names -t refbast.tr_rivernames_riv > refbast.pgc

pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t refeel.tr_area_are > refeel.pgc
