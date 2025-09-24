library(DBI)
library(RPostgres)


con <- DBI::dbConnect(drv=RPostgres::Postgres(),
		dbname = "diaspara",
		host = "185.135.126.250",
		user = "diaspara_read",
		password = "************"  
		)


area <- dbGetQuery(con, "SELECT * FROM refbast.t_area_are;")
