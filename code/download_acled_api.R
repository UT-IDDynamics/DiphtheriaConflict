#########################################################################
########## Conflict data collection from API  ###########################
########## Diphtheria model WHO region Africa ###########################
########## Author: Tierney O'Sullivan         ###########################
########## Date last modified: 2024-04-13     ###########################
#########################################################################

## libraries
library(here)
library(stringr)
library(readr)
library(dplyr)
library(padr)
library(tidyr)
library(ISOcodes)
# set working directory to current folder
setwd(here())


###### Establish countries ################
countries = read_csv("data/country_data/country_list.csv", col_names = "Name") %>% 
  mutate(Name = case_when(Name == "C\x99te d'Ivoire" ~ "Côte d'Ivoire",
                          TRUE ~ Name))

country_df = ISO_3166_1 %>% 
  filter(Name %in% countries$Name | Official_name %in% countries$Name | Common_name %in% countries$Name)

# get country codes from acled_iso_codes (downloaded from ACLED website: https://www.acleddata.com/download/3987/)

acled_iso = read_csv("data/conflict/acled_iso_codes.csv",col_names = c("Name", "Region", "Start_date", "ISO_numeric"), skip = 1) %>%
  mutate(ISO_numeric_pad = str_pad(ISO_numeric, width = 3, side = "left", pad = "0"))

acled_iso_use = acled_iso %>% filter(ISO_numeric_pad %in% country_df$Numeric)

country_df = country_df %>% 
  left_join(acled_iso_use %>% 
              select(Numeric = ISO_numeric_pad, Acled_numeric = ISO_numeric)) %>%
  filter(!(Alpha_2 %in% c("BW", "CV", "DZ", "CF", "GQ", "ER", "GW", "MU", "ST", "SC", "SS", "KM")))
# to download new data
# load API key
source("code/acled_access_key.R")

for (i in 1:nrow(country_df)){
  iso_num = country_df$Acled_numeric[i]
  iso3 = country_df$Alpha_3[i]
  
  myurl <- paste0("https://api.acleddata.com/acled/read?key=", acled_api_key, "&email=", acled_api_email,"&year=2013|2024&year_where=BETWEEN&iso=",iso_num,"&iso_where=%3D&limit=0")
  
  
  acled_js <- jsonlite::fromJSON(myurl)
  acled <- acled_js$data
  write.csv(acled, paste0("data/conflict_all/2013_2024_", iso3,".csv"))
  
}
