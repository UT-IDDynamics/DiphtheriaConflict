#########################################################################
########## Data collection script             ###########################
########## Diphtheria model WHO region Africa ###########################
########## Author: Tierney O'Sullivan         ###########################
########## Date last modified: 2024-04-13     ###########################
#########################################################################

## libraries
library(here)
library(stringr)
library(readr)
library(dplyr)
library(RcppRoll)
library(padr)
library(sf)
library(units)
library(tidyr)
library(ISOcodes)
# set working directory to current folder
setwd(here())

##### Geographic data ######
polys <- readRDS("~/EbolaCentralAfrica2020-files/data/HealthDistricts_CA_Data_allstationary.rds")
polys <- polys[!(polys$ADM2_NAME %in% c("KABWE RURAL", "TORORO & PALLISA")),] # remove health zones that have no land mass
polys_sf <- st_as_sf(polys)
area <- st_area(polys_sf) %>% units::set_units(., km^2)
centroids <- data.frame(ADM2_NAME=polys$ADM2_NAME,X=polys$CENTER_LON, Y=polys$CENTER_LAT)
#region <- as.integer(as.factor(polys$ISO))


###### Establish countries ################
countries = read_csv("data/country_list.csv", col_names = "Name") %>% 
  mutate(Name = case_when(Name == "C\x99te d'Ivoire" ~ "Côte d'Ivoire",
                          TRUE ~ Name))

country_df = ISO_3166_1 %>% filter(Name %in% countries$Name | Official_name %in% countries$Name | Common_name %in% countries$Name)
###### ACLED Time-varying conflict status ############

## create time varying matrices of conflict
# Armed Conflict in Infected Health zones

# get country codes from acled_iso_codes (downloaded from ACLED website: https://www.acleddata.com/download/3987/)

acled_iso = read_csv("data/conflict/acled_iso_codes.csv",col_names = c("Name", "Region", "Start_date", "ISO_numeric"), skip = 1) %>%
  mutate(ISO_numeric_pad = str_pad(ISO_numeric, width = 3, side = "left", pad = "0"))

acled_iso_use = acled_iso %>% filter(ISO_numeric_pad %in% country_df$Numeric)

country_df = country_df %>% left_join(acled_iso_use %>% select(Numeric = ISO_numeric_pad, Acled_numeric = ISO_numeric))

# to download new data
# load API key
source("code/acled_access_key.R")
# myurl <- paste0("https://api.acleddata.com/acled/read?terms=accept&t&last_event_date={2018-06-01|2020-06-25}&last_event_date_where=BETWEEN&country=Democratic%20Republic%20of%20Congo&country_where=%3D&limit=0&key=", acled_api_key, "&email=t.osullivan@utah.edu")
myurl <- paste0("https://api.acleddata.com/acled/read?key=", acled_api_key, "&email=t.osullivan@utah.edu&year=2017|2024&year_where=BETWEEN&iso=180&iso_where=%3D&limit=0")

for (i in 1:nrow(country_df)){
  iso_num = country_df$Acled_numeric[i]
  iso3 = country_df$Alpha_3[i]
  
  myurl <- paste0("https://api.acleddata.com/acled/read?key=", acled_api_key, "&email=t.osullivan@utah.edu&year=2017|2024&year_where=BETWEEN&iso=",iso_num,"&iso_where=%3D&limit=0")
  
  
  acled_js <- jsonlite::fromJSON(myurl)
  acled <- acled_js$data
  write.csv(acled, paste0("data/conflict/2017_2024_", iso3,".csv"))
  
}

# single country examples
# myurl <- paste0("https://api.acleddata.com/acled/read?key=", acled_api_key, "&email=t.osullivan@utah.edu&year=2017|2024&year_where=BETWEEN&iso=24&iso_where=%3D&limit=0")
# 
# 
# acled_js <- jsonlite::fromJSON(myurl)
# acled <- acled_js$data
# write.csv(acled, paste0("data/conflict/2017_2024", "Angola.csv"))

# to upload pre-downloaded data for time period of interest
acled <- read.csv("data/conflict/2018-03-13-2021-03-19-Democratic_Republic_of_Congo.csv")
# https://api.acleddata.com/{data}/{command}.csv need to figure out how to automate this
polys <- readRDS("data/HealthDistricts_CA_Data_noroads.rds")
polys_sf <- st_as_sf(polys)

# changing event_date to Date format
acled <- acled %>% mutate(event_date = as.Date(event_date, format = "%d %B %Y")) %>% 
  # filter data to include time period of the outbreak
  filter(event_date >= "2018-06-01" & event_date <= "2020-06-25")

fun_add_week_start_acled <- function(x){
  # start of the week = Monday
  tmp <- x %>% mutate(Weekday = weekdays(event_date))
  tmp <- tmp %>% mutate(event_date_week_start = case_when(Weekday == "Tuesday" ~ event_date - 1,
                                                          Weekday == "Wednesday" ~ event_date - 2,
                                                          Weekday == "Thursday" ~ event_date - 3, 
                                                          Weekday == "Friday" ~ event_date - 4,
                                                          Weekday == "Saturday" ~ event_date - 5,
                                                          Weekday == "Sunday" ~ event_date - 6,
                                                          Weekday == "Monday" ~ event_date
  ))
  firstweek <- as.Date("2018-05-28")
  tmp <- tmp %>% 
    # mutate(event_date_week_num = as.numeric(difftime(event_date_week_start, firstweek, units = "weeks"), units = "weeks" )) %>%
    mutate(event_date_week_end = event_date_week_start + 21) %>%
    # mutate(event_date_week_num_end = event_date_week_num + 3)
    return(tmp)
  
}

acled <- fun_add_week_start_acled(acled)

# selecting variables of interest
acled <- acled %>% select(data_id, event_id_cnty, event_date, year, event_type, sub_event_type, 
                          country, admin1, admin2, latitude, longitude, notes, fatalities, iso3, 
                          event_date_week_start, 
                          #event_date_week_num, 
                          event_date_week_end, 
                          #event_date_week_num_end
)
