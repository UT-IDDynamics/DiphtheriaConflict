##### Script to create spatial boundaries for each country (ADM0) and state (ADM1) #####
##### Overlay with population data                                                 #####

library(sf)
library(tidyverse)
library(raster)

### Database of global administrative areas (GADM)
### download from https://gadm.org/download_world.html 
### specific download URL: https://geodata.ucdavis.edu/gadm/gadm4.1/gadm_410-levels.zip
### load GADM data of geographies at ADM0 level (country boundaries)
### Accessed on April 16, 2024
#### load GADM data of geographies at ADM0 level (country boundaries)
GADM0_world = st_read("data/GADM/gadm_410-levels.gpkg", 
                      layer = "ADM_0")

### load GADM data of geographies at ADM1 level (state/territory)
GADM1_world = st_read("data/GADM/gadm_410-levels.gpkg", 
                      layer = "ADM_1")


#### load countries with DHS survey data ####
dhs_countries = read_csv("data/country_data/DHS_countries_iso.csv")

# Population - from Landscan - https://landscan.ornl.gov/about
# Database requires login based on asking for access
# Used 2022 data LandScan Global with spatial resolution of 30 arc-seconds (~1 km)
# Accessed on April 17, 2024

world_pop_ls <- raster('data/LandScan/landscan-global-2022-assets/landscan-global-2022.tif')

adm1 <- st_transform(GADM1_world, CRS(projection(world_pop_ls)))
adm0 <- st_transform(GADM0_world, CRS(projection(world_pop_ls)))

# filter so we only have ADM1 data for the countries of interest
adm1_subset <- adm1 %>% filter(GID_0 %in% dhs_countries$Alpha_3)
# filter so we only have ADM0 data for the countries of interest
adm0_subset <- adm0 %>% filter(GID_0 %in% dhs_countries$Alpha_3)
#This gets the population for each ADM1 region by summing across each 1 km raster cells
#Sum raster cells within each polygon
adm1_pop <- raster::extract(world_pop_ls, adm1_subset, fun=sum, df=T, na.rm=T)
#Add new column containing population to the ADM1 object
adm1_afr <- bind_cols(adm1_subset, pop_size = adm1_pop[,2])


#Produce plot to check
#checking pop_size errors
#what is the population for the entire country?
as.data.frame(adm1_afr) %>% group_by(GID_0) %>% summarise(total_pop = sum(pop_size))
# plot(adm1_afr["pop_size"])

saveRDS(adm1_afr, "data/geographies/ADM1_pop.rds")