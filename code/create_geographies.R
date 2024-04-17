
library(sf)
library(tidyverse)
library(raster)


#### load GADM data of geographies at ADM0 level (country boundaries)
GADM0_world = st_read("data/GADM/gadm_410-levels.gpkg", 
                       layer = "ADM_0")

### load GADM data of geographies at ADM1 level (state/territory)
GADM1_world = st_read("data/GADM/gadm_410-levels.gpkg", 
                       layer = "ADM_1")


#### load countries with DHS survey data ####
dhs_countries = read_csv("data/country_data/DHS_countries_iso.csv")

#Population - from Landscan - https://landscan.ornl.gov/about
# Database requires login based on asking for access
# Used 2022 data LandScan Global with spatial resolution of 30 arc-seconds (~1 km)
# 
# world_pop_ls <- raster("data/LandScan_Global_2017/lspop2017/w001001.adf")
world_pop_ls <- raster('data/LandScan/landscan-global-2022-assets/landscan-global-2022.tif')
# health.districts <- spTransform(health.districts.raw, CRS(projection(world_pop_ls)))
# health.districts.DRC <- spTransform(health.districts.DRC, CRS(projection(world_pop_ls)))

adm1 <- st_transform(GADM1_world, CRS(projection(world_pop_ls)))

# filter so we only have ADM1 data for the countries of interest
adm1_subset <- adm1 %>% filter(GID_0 %in% dhs_countries$Alpha_3)

#This gets the population for each ADM1 region by summing across each 1 km raster cells
#Sum raster cells within each polygon
adm1_pop <- raster::extract(world_pop_ls, adm1_subset, fun=sum, df=T, na.rm=T)
#Add new column containing population to the health.district object
adm1 <- spCbind(health.districts, health.districts.pop[,2]); names(health.districts)[37]<-"pop.size"

health.districts.pop.drc <- raster::extract(world_pop_ls, health.districts.DRC, fun=sum, df=T, na.rm=T)

#Produce plot to check
#spplot(health.districts, "pop.size", main="Central Africa Population by health district", col= "transparent")
#checking pop.size errors
#what is the population for the entire country?
#as.data.frame(health.districts) %>% group_by(ADM0_NAME) %>% summarise(total_pop = sum(afripop))
