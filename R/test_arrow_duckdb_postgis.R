# test arrow & duckDB
install.packages("geoarrow")

library(arrow)
library(lobstr)
library(tictoc)
library(fs)
library(palmerpenguins)
library(duckdb)
library(dplyr)
library(tictoc)
library(geoarrow)

glimpse(penguins)

penguins |> 
  group_by(species, sex) |> 
  summarise(avg_body_mass = mean(body_mass_g, na.rm = TRUE)) |> 
  ungroup()

penguins_arrow <- arrow_table(penguins)
penguins_arrow

penguins_arrow |> 
  group_by(species, sex) |> 
  summarise(avg_body_mass = mean(body_mass_g, na.rm = TRUE)) |> 
  ungroup()

# compute(): runs the query and the data is stored in the Arrow object.
# collect(): runs the query and returns the data in R as a tibble.

penguins_arrow |> 
  group_by(species, sex) |> 
  summarise(avg_body_mass = mean(body_mass_g, na.rm = TRUE)) |> 
  collect()

write_parquet(penguins_arrow, here::here("data", "penguins.parquet"))
# The write_dataset() function provides a more efficient storage format and in particular it can partition data based on a variable, using Hive style.
write_dataset(penguins, 
              here::here("data", "penguins_species"), 
              format = "parquet",
              partitioning = c("species"))
dir_tree(here::here("data", "penguins_species"))


penguins_arrow <- open_dataset(here::here("data", "penguins_species"))
penguins_arrow

# UTILISER CETTE SYNTAXE pour ne pas passer par une bdd particulière

penguins_arrow |> 
  group_by(species, sex) |> 
  summarise(avg_body_mass = mean(body_mass_g, na.rm = TRUE)) |> 
  collect()


penguins_arrow |> 
  to_duckdb(con="C:/duckdb/test.duckdb") |> 
  group_by(species, sex) |> 
  summarise(avg_body_mass = mean(body_mass_g, na.rm = TRUE))

# UTILISER CETTE SYNTAXE POUR CONNECTER UNE BASE PARTICULIERE

con <- dbConnect(duckdb::duckdb("C:/duckdb/pinguin.duckdb"))
arrow::to_duckdb(penguins_arrow, table_name = "penguins", con = con)
dbGetQuery(con, "SELECT species, sex, AVG(body_mass_g) FROM penguins GROUP BY species, sex")
duckdb_unregister(con, "penguins") # disconnect from table
dbDisconnect(con)

# UTLISER CETTE FONCTON POUR CONNECTER UNE BASE POSTGRES

## open a duckdb (I don't know yet how to do this in R)
.open C:/duckdb/test.duckdb
LOAD postgres_scanner;
CALL postgres_attach("host=localhost port=5432 dbname='eda2.3' user='postgres' password='supersecret'", source_schema='france');
PRAGMA show_tables;
SELECT * FROM france.rn;
-- using all schema
COPY (SELECT * FROM postgres_scan("host=localhost port=5432 dbname='eda2.3' user='postgres' password='postgres'", 'france', 'rn')) TO 'francern.parquet' (FORMAT PARQUET);
-- note : this is not a postgis table




## Test for reading arrow using open_dataset
tic()
DS <- arrow::open_dataset(sources = "C:/duckdb/francern.parquet")
toc() # 0.03 s
## Create a scanner
SO <- Scanner$create(DS)
DS |> head() # geom is a string

# To load partitioned files
#https://stackoverflow.com/questions/58439966/read-partitioned-parquet-directory-all-files-in-one-r-dataframe-with-apache-ar
## Define the dataset
DS <- arrow::open_dataset(sources = "/path/to/directory")
## Create a scanner
SO <- Scanner$create(DS)
## Load it as n Arrow Table in memory
AT <- SO$ToTable()
## Convert it to an R data frame
DF <- as.data.frame(AT)


# Read gis data and store them in geoarrow format


