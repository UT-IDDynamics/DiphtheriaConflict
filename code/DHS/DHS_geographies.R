
####### Script to get geographic data for DHS surveys ##########

library(tidyverse)
library(sf)


### file_names 

# to upload pre-downloaded data on DHS geographies
file_names = paste0("data/DHS/spatial_boundaries/", list.files("data/DHS/spatial_boundaries/"), "/shps/sdr_subnational_boundaries.shp")
file_names
dhs_spatial = do.call(rbind,
                    lapply(file_names, 
                           st_read))

write_rds(dhs_spatial, "data/DHS/spatial_dhs_boundaries_full_list_updatedNov24.RDS")

