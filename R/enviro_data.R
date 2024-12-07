#https://knmi-ecad-assets-prd.s3.amazonaws.com/ensembles/data/Grid_0.25deg_reg_ensemble/tg_ens_mean_0.25deg_reg_v29.0e.nc
#https://www.ecad.eu/
#tg, precipitation, pressure
library(terra)
library(tidyterra)
library(lubridate)
library(sf)
library(dplyr)

load("~/Documents/Bordeaux/migrateurs/Sudoeel/Shiny_results/EDA_data/zonew.Rdata")
load("~/Documents/Bordeaux/migrateurs/Sudoeel/Shiny_results/EDA_data/emuw.Rdata")
emuw=st_transform(emuw,4326)
zonew=st_transform(zonew,4326)

#temperature moyenne
setwd("~/Documents/Bordeaux/migrateurs/theseMathilde/Stage_M2_2024/")


extract_enviro = function(filename,name="tg",cl=5){
  myrast=terra::rast(filename)
  
  years=lubridate::year(time(myrast))
  myrast=subset(myrast,which(years>=1980))
  years=lubridate::year(time(myrast))
  yearlyrast=lapply(unique(years),function(y) {
    rasty=terra::mean(subset(myrast,which(years==y)))
    emu_y=data.frame(year=y,
                     emu=emuw$id,
                     var=terra::extract(rasty,emuw,mean,na.rm=TRUE)$mean) %>%
      dplyr::rename_with(~name,all_of("var"))
    zone_y=data.frame(year=y,
                      zone=zonew$id,
                      var=terra::extract(rasty,zonew,mean,na.rm=TRUE)$mean) %>%
      dplyr::rename_with(~name,all_of("var"))
    
    return(list(emu=emu_y,zone=zone_y))
  })
  list(emu=do.call(dplyr::bind_rows,lapply(yearlyrast,function(y) y$emu)),
       zone=do.call(dplyr::bind_rows,lapply(yearlyrast,function(y) y$zone)))
  
}

tg_y=extract_enviro("tg_ens_mean_0.1deg_reg_v29.0e.nc", "tg")
tg_emu=tg_y$emu
tg_zone=tg_y$zone
save(tg_emu,tg_zone,file="tg.rdata")


rr_y=extract_enviro("rr_ens_mean_0.1deg_reg_v29.0e.nc", "rr")
rr_emu=rr_y$emu
rr_zone=rr_y$zone
save(rr_emu,rr_zone,file="rr.rdata")


pp_y=extract_enviro("pp_ens_mean_0.1deg_reg_v29.0e.nc", "pp")
pp_emu=pp_y$emu
pp_zone=pp_y$zone
save(pp_emu,pp_zone,file="p.rdata")



#plot(tg[[2]])
#average_tg=mean(tg)
#plot(average_tg)
begin=Sys.time()
yearly_tg=tapp(tg,"years",fun=mean,cores=5) 
end=Sys.time()
library(ggplot2)
ggplot()+geom_spatraster(data=yearly_tg-average_tg)+facet_wrap(~lyr)+scale_fill_viridis_c()


#https://land.copernicus.eu/en/products/corine-land-cover
years=c(1990,2000,2006,2012,2018)
clc_cat=read.table("clc.csv",header=TRUE,sep=";")
extent=ext(st_bbox(zonew)[c("xmin","xmax","ymin","ymax")])
emuw=vect(st_transform(emuw,3035))
zonew=vect(st_transform(zonew,3035))
extract_clc = function(y){
  print(y)
  path=list.files("./75894/",pattern=paste0("CLC",y,".+\\.tif$"),recursive=TRUE,full.names=TRUE)
  path = path[!grepl('DOMs',path)]
  clc=terra::rast(path)
  crs(clc)="epsg:3035"
  gc()

  print("emu")
  emu_clc=terra::extract(clc,emuw,mean)
  emu_clc$ID=emuw$id
  emu_clc$year=y
  names(emu_clc)[2]="clc"
  gc()
  print("zone")
  
  zone_clc=terra::extract(clc,zonew,mean)
  zone_clc$ID=zonew$id
  zone_clc$year=y
  names(zone_clc)[2]="clc"
  gc()
  return(list(emu=emu_clc[,c("ID","clc","year")],
       zone=zone_clc[,c("ID","clc","year")]))
}

clc_y=lapply(years,function(y){
  res=extract_clc(y)
  gc()
  res
})

clc_emu=do.call(bind_rows, lapply(clc_y, function(y) y$emu))
clc_zone=do.call(bind_rows, lapply(clc_y, function(y) y$zone))
save(clc_emu,clc_zone,file="clc.rdata")

######
#WISE dcf
library("RSQLite")

rbd=list(ATL_IB=c("ES014","ES010",
                  paste0("PTRH",1:3),
                  "PTRH4A","PTRH5A",
                  paste0("PTRH",6:8),
                  "ES040", "ES050","ES063"),
         MED=c(paste("ES0",seq(60,80,10)),
               "ES091", "ES0100","FRCD"),
         CANT=c("ES017","ES018"),
         ATL_F=c("FRF","FRG"),
         CHAN=c("FRH", "FRAR"),
         RhinMeu=c("FRCRR","FRB"))

rbd=do.call(bind_rows,lapply(seq_len(length(rbd)),
                             function(r) data.frame(zone=names(rbd)[r],
                                                    euRBDCode=rbd[[r]])))
library(DBI)
## connect to db
con <- dbConnect(drv=RSQLite::SQLite(), dbname="eea_t_wise-wfd_p_2000-now_v01_r00/wise-wfd-database_v01_r04/WISE_SOW.sqlite")


## create a data.frame for each table
status=dbReadTable(con,name="SOW_SWB_SurfaceWaterBody")
status <- status %>%
  filter(euRBDCode %in% rbd$euRBDCode) %>%
  left_join(rbd) %>%
  group_by(cYear, zone) %>%
  summarise(ecological=mean(as.numeric(swEcologicalStatusOrPotentialValue), na.rm=TRUE),
            chemical=mean(as.numeric(swChemicalStatusValue), na.rm=TRUE)) %>%
  ungroup()
save(status,file="wfd.rdata")


##landings
library(yaml)
library(RPostgres)
cred=read_yaml("~/Documents/Bordeaux/migrateurs/WGEEL/github/wg_WGEEL/credentials.yml")
con=dbConnect(Postgres(), host=cred$host, user=cred$user,
              dbname=cred$dbname,password=cred$password,
              port=cred$port)
landings=dbGetQuery(con,"select eel_year, eel_lfs_code, sum(eel_value) eel_value,
           eel_emu_nameshort from datawg.t_eelstock_eel where eel_cou_code in 
           ('FR','ES','PT') and eel_qal_id <5 and eel_typ_id=4  and eel_year>2008
           group by
            eel_year, eel_lfs_code,
           eel_emu_nameshort" )
library(dplyr)
library(tidyr)
`%+%` <- function(x, y)  mapply(sum, x, y, MoreArgs = list(na.rm = TRUE))
landings_emu <- landings %>%
  pivot_wider(values_from=eel_value,names_from=eel_lfs_code) %>%
  mutate(YS=Y%+%S%+%YS) %>%
  select(all_of(c("eel_year","eel_emu_nameshort","G","YS")))

landings_zone <- landings_emu %>%
  mutate(zone=ifelse(eel_emu_nameshort %in%
                       c("ES_Cata", "ES_Murc","FR_Cors","ES_Vale","FR_Rhon","ES_Bale"), "MED",
                     ifelse(eel_emu_nameshort %in% 
                              c("PT_Port", "PT_total", "ES_Mino", "ES_Minh","ES_Gali","ES_Anda") , "ATL_IB",
                            ifelse(eel_emu_nameshort %in%
                                     c("ES_Basq", "ES_Cant", "ES_Nava", "ES_Astu","FR_Adou"), "CANT",
                                   ifelse(eel_emu_nameshort %in% c("FR_Garo","FR_Loir","FR_Bret"), "ATL_FR",
                                          ifelse(eel_emu_nameshort %in% c("FR_Sein","FR_Arto"), "CHAN",
                                                 ifelse(eel_emu_nameshort %in% c("FR_Meus", "FR_Rhin"), "RhinMeu", NA)))))))%>%
  filter(!is.na(zone)) %>%
  group_by(eel_year,zone) %>%
  summarize(G=sum(G,na.rm=TRUE),
            YS=sum(YS,na.rm=TRUE)) %>%
  ungroup()
save(landings_emu,landings_zone,file="landings.rdata")

#######discodata
library(httr)
library(tidyjson)
query=
'https://discodata.eea.europa.eu/sql?query=%0ASELECT%20observedPropertyDeterminandCode%2CobservedPropertyDeterminandLabel%20FROM%20%5BWISE_SOE%5D.%5Blatest%5D.%5BWaterbase_T_WISE6_AggregatedData%5D%0Awhere%20countryCode%20in%20(%27ES%27%2C%27PT%27%2C%27FR%27)%20group%20by%20observedPropertyDeterminandCode%2CobservedPropertyDeterminandLabel%0A%0A&p=1&nrOfHits=1000&mail=null&schema=null'
res = GET(query)
content(res,as="parsed")  %>% bind_rows()
#water quality (contaminants)
#SELECT TOP 100 * FROM [WISE_SOE].[latest].[Waterbase_T_WISE6_AggregatedData]
query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_S_WISE_SpatialObject_DerivedData] where countryCode in ('ES')" 
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
monitoring_sites_ES=content(res,as="parsed")  %>% bind_rows()

query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_S_WISE_SpatialObject_DerivedData] where countryCode in ('FR')" 
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
monitoring_sites_FR=content(res,as="parsed")  %>% bind_rows()

query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_S_WISE_SpatialObject_DerivedData] where countryCode in ('PT')" 
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
monitoring_sites_PT=content(res,as="parsed")  %>% bind_rows()


monitoring_sites=bind_rows(monitoring_sites_ES,monitoring_sites_FR,monitoring_sites_PT)
monitoring_sites_sf=st_as_sf(monitoring_sites %>%
                               filter(! (is.na(lon)| is.na(lat))),
                             coords = c("lon","lat")) %>%
  st_set_crs(4326)


emuw=st_transform(emuw,4326)
zonew=st_transform(zonew,4326)
sf_use_s2(FALSE)
monitoring_sites_emu=st_join(monitoring_sites_sf,emuw) %>%
  rename(eel_emu_nameshort=id) %>%
  select(monitoringSiteIdentifier,eel_emu_nameshort) %>%
  st_drop_geometry()

monitoring_sites_zone=monitoring_sites_sf %>%
  st_join(zonew) %>%
  rename(zone=id) %>%
  st_drop_geometry() %>%
  select(monitoringSiteIdentifier,zone) 

pcb6=c("CAS_7012-37-5","CAS_35693-99-3",
       "CAS_37680-73-2",
       "CAS_35065-28-2",
       "CAS_35065-27-1",
       "CAS_35065-29-3")

#cd="CAS_7440-43-9"
#mercury="CAS_7439-97-6"
#plomb="CAS_7439-92-1"


# we have a status biological aggregated by monitoring site
#SELECT TOP 100 * FROM [WISE_SOE].[latest].[Waterbase_T_WISE2_BiologyEQRData]


##pcb ES
query=paste0("SELECT observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod,avg(resultMeanValue) as value FROM [WISE_SOE].[latest].[Waterbase_T_WISE6_AggregatedData]",
             " where countryCode in ('ES') and observedPropertyDeterminandCode in ('",
             paste(pcb6, collapse="','"),
             "') and parameterWaterBodyCategory='RW' and monitoringSiteIdentifierScheme='euMonitoringSiteCode'",
             " group by observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod")

res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
               query = list(
                 query = query,
                 p = 1,
                 nrOfHits=10000,
                 mail="null",
                 schema="null")
)

pcbES <- content(res,as="parsed")  %>% bind_rows() %>%
  pivot_wider(names_from=observedPropertyDeterminandCode,
              values_from=value) %>%
  mutate(pcb=`CAS_35065-28-2`+`CAS_35065-29-3`+`CAS_35693-99-3`+`CAS_37680-73-2`+`CAS_7012-37-5`+`CAS_35065-27-1`) %>%
  select(-starts_with("CAS")) 



##pcb FR
query=paste0("SELECT observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod,avg(resultMeanValue) as value FROM [WISE_SOE].[latest].[Waterbase_T_WISE6_AggregatedData]",
             " where countryCode in ('FR') and observedPropertyDeterminandCode in ('",
             paste(pcb6, collapse="','"),
             "') and parameterWaterBodyCategory='RW' and monitoringSiteIdentifierScheme='euMonitoringSiteCode'",
             " group by observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod")

res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)

pcbFR <- content(res,as="parsed")  %>% bind_rows() %>%
  pivot_wider(names_from=observedPropertyDeterminandCode,
              values_from=value) %>%
  mutate(pcb=sum(c_across(cols = starts_with('CAS')))) %>%
  select(-starts_with("CAS")) 

##pcb PT
query=paste0("SELECT observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod,avg(resultMeanValue) as value FROM [WISE_SOE].[latest].[Waterbase_T_WISE6_AggregatedData]",
             " where countryCode in ('PT') and observedPropertyDeterminandCode in ('",
             paste(pcb6, collapse="','"),
             "') and parameterWaterBodyCategory='RW' and monitoringSiteIdentifierScheme='euMonitoringSiteCode'",
             " group by observedPropertyDeterminandCode,monitoringSiteIdentifier,parameterSamplingPeriod")

res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
#no data there
# pcbPT <- content(res,as="parsed")  %>% bind_rows() %>%
#   pivot_wider(names_from=observedPropertyDeterminandCode,
#               values_from=value) %>%
#   mutate(pcb=sum(c_across(cols = starts_with('CAS')))) %>%
#   select(-starts_with("CAS"))

library(tidyr)
pcb_emu <- bind_rows(pcbES,pcbFR) %>%
  inner_join(monitoring_sites_emu) %>% 
  separate_wider_delim(parameterSamplingPeriod,delim="--",names=c("start","end")) %>%
  mutate(start=as.Date(start),
          end=as.Date(end)) %>%
  rowwise()%>%
  mutate(period=mean.Date(c(start,end))) %>%
  ungroup() %>%
  mutate(year=lubridate::year(period)) %>%
  group_by(eel_emu_nameshort,year) %>%
  summarize(pcb=mean(pcb,na.rm=TRUE))%>%
  ungroup()
  

pcb_zone <- bind_rows(pcbES,pcbFR) %>%
  inner_join(monitoring_sites_zone) %>% 
  separate_wider_delim(parameterSamplingPeriod,delim="--",names=c("start","end")) %>%
  mutate(start=as.Date(start),
         end=as.Date(end)) %>%
  rowwise()%>%
  mutate(period=mean.Date(c(start,end))) %>%
  ungroup() %>%
  mutate(year=lubridate::year(period)) %>%
  group_by(zone,year) %>%
  summarize(pcb=mean(pcb,na.rm=TRUE)) %>%
  ungroup()

#monitoring sites

# we have a status  biological aggregated by station
query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_T_WISE2_BiologyEQRData] where countryCode in ('ES') and parameterWaterBodyCategory='RW' and parameterNaturalAWBHMWB='Natural'"
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
bio_ES <- content(res,as="parsed")  %>% bind_rows() %>%
  select(monitoringSiteIdentifier,observedPropertyDeterminandLabel,resultNormalisedEQRValue,phenomenonTimeReferenceYear) 

query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_T_WISE2_BiologyEQRData] where countryCode in ('FR') and parameterWaterBodyCategory='RW' and parameterNaturalAWBHMWB='Natural'"
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
bio_FR <- content(res,as="parsed")  %>% bind_rows() %>%
  select(monitoringSiteIdentifier,observedPropertyDeterminandLabel,resultNormalisedEQRValue,phenomenonTimeReferenceYear) 


query="SELECT * FROM [WISE_SOE].[latest].[Waterbase_T_WISE2_BiologyEQRData] where countryCode in ('PT') and parameterWaterBodyCategory='RW' and parameterNaturalAWBHMWB='Natural'"
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
bio_PT <- content(res,as="parsed")  %>% bind_rows() %>%
  select(monitoringSiteIdentifier,observedPropertyDeterminandLabel,resultEcologicalStatusClassValue,phenomenonTimeReferenceYear) %>%
  mutate(resultNormalisedEQRValue=as.numeric(resultEcologicalStatusClassValue)/5) %>%
  select(-resultEcologicalStatusClassValue) 

bio = bind_rows(bio_PT,bio_FR,bio_ES)

bio_emu <- bio %>%
  inner_join(monitoring_sites_emu, relationship="many-to-many") %>%
  group_by(eel_emu_nameshort,phenomenonTimeReferenceYear,observedPropertyDeterminandLabel) %>%
  summarize(resultNormalisedEQRValue=mean(resultNormalisedEQRValue,na.rm=TRUE)) %>%
  ungroup()


bio_zone <- bio %>%
  inner_join(monitoring_sites_zone, relationship="many-to-many") %>%
  group_by(zone,phenomenonTimeReferenceYear,observedPropertyDeterminandLabel) %>%
  summarize(resultNormalisedEQRValue=mean(resultNormalisedEQRValue,na.rm=TRUE)) %>%
  ungroup()


bio_FR <- content(res,as="parsed")  %>% bind_rows() %>%
  select(monitoringSiteIdentifier,observedPropertyDeterminandLabel,resultNormalisedEQRValue,phenomenonTimeReferenceYear) 


query="SELECT * FROM [WISE_Indicators].[latest].[BiologyEQRData] where countryCode in ('FR') and waterBodyCategory	='RW'"
res <- GET(url = "https://discodata.eea.europa.eu/sql?", 
           query = list(
             query = query,
             p = 1,
             nrOfHits=10000,
             mail="null",
             schema="null")
)
bio2_FR <- content(res,as="parsed")  %>% bind_rows() %>%
  select(monitoringSiteIdentifier,eeaIndicator,resultNormalisedEQRValue,phenomenonTimeReferenceYear) 
bio2_FR %>%
  inner_join(monitoring_sites_zone, relationship="many-to-many") %>%
  group_by(zone,phenomenonTimeReferenceYear,eeaIndicator) %>%
  summarize(resultNormalisedEQRValue=mean(resultNormalisedEQRValue,na.rm=TRUE)) %>%
  ungroup()
