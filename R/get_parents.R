library(DBI)
library(RPostgres)
library(dplyr)

con <- DBI::dbConnect(drv=RPostgres::Postgres(),
		dbname = "diaspara",
		host = "185.135.126.250",
		user = "diaspara_read",
		password = "************"  
)


area <- dbGetQuery(con, "SELECT 
				are_id,
				are_are_id, 
				are_code,
				are_lev_code,
				are_ismarine,
				are_name FROM refbast.tr_area_are;")


save(area, file = "C:/workspace/DIASPARA_WP3_habitat/data/area.Rdata")

get_area <- function(are_id, area, tab=data.frame()) {
	if (is.na(are_id)) {
		return(tab) 
	} else {
		if (nrow(tab)==0){
			tab <- area[area$are_id == are_id,]
		} else {			
			tab <- rbind(tab, area[area$are_id == are_id,])
		}
		are_id <- tab[nrow(tab), "are_are_id"]
		get_area(are_id, area, tab)		
	}
}


# So we can use a recursive from R 
hierar <- get_area(area,are_id = 1275)

# or from postgres

get_area_postgres <- function( con, are_id){
	return(dbGetQuery(con, "SELECT * FROM ref.get_parent_area(1275, 'WGBAST')"))
}

hierar <- get_area_postgres(con, are_id = 1275)
# Lets say you have the main_river code as a vector from your points (you know this by spatial join between points and the river segment)

main_rivers <- c("20056363", "20056030")

selected_areas <- dplyr::left_join(data.frame("main_riv"= main_rivers), area, by = join_by("main_riv" == "are_code"))

# to work with more than one argument to the function I would use mapply

ll <- mapply(get_area, selected_areas$are_id, MoreArgs = list(area=area),SIMPLIFY = FALSE)
bind_rows(ll)