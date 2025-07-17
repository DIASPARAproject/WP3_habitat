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
pg_dump -U postgres -F custom -d diaspara -n h_medeast > h_medeast.pgc
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

pg_dump -U postgres -F custom -d diaspara -t ref.tr_area_are > ref_area.pgc
pg_dump -U postgres -F custom -d diaspara -t refnas.tr_area_are > refnas_area.pgc
pg_dump -U postgres -F custom -d diaspara -t refbast.tr_area_are > refbast_area.pgc


pg_dump --dbname=postgresql://${env:usermercure}:${env:passmercure}@${env:hostmercure}/diaspara -F custom -t ref.tr_destination_des ref.tr_maturity_mat ref.tr_species_spe ref.tr_category_cat ref.tr_lifestage_lfs ref.tr_country_cou ref.tr_habitatlevel_lev ref.tr_version_ver ref.tr_nimble_nim ref.tr_units_uni ref.tr_missvalueqal_mis ref.tr_age_age ref.tr_icworkinggroup_wkg ref.tr_fishingarea_fia ref.tr_dataaccess_dta ref.tr_trait_tra ref.tr_metric_mtr ref.tr_objecttype_oty ref.tr_outcome_oco ref.tr_area_are ref.tr_quality_qal ref.tr_habitat_hab ref.tr_rivernames_riv ref.tr_habitattype_hty ref.tr_fishway_fiw ref.tr_gear_gea ref.tr_monitoring_mon ref.tr_sex_sex ref.tr_traitmethod_trm ref.tr_traitnumeric_trn ref.tr_traitqualitative_trq ref.tr_traitvaluequal_trv > ref.pgc
