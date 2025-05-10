#########################################################################
########## Data collection script             ###########################
########## Diphtheria model WHO region Africa ###########################
########## Author: Tierney O'Sullivan         ###########################
########## Date last modified: 2025-01-06     ###########################
#########################################################################

## libraries
library(here)
library(stringr)
library(readr)
library(dplyr)
library(padr)
library(sf)
library(units)
library(tidyr)
library(ISOcodes)
library(ISOweek)
library(lubridate)
library(padr)
library(tibbletime)
# set working directory to current folder
setwd(here())


#### Country list ######
country_list = read_csv("data/DHS/Exclusion_inclusion_criteria.csv") %>% select(GID_0)
country_list = country_list %>% filter(!is.na(GID_0))
country_list = country_list$GID_0

##### Geographic data ######
polys <- readRDS("data/geographies/ADM1_pop.rds") 
polys <- polys[(polys$GID_0 %in% country_list),] # remove countries that are excluded
polys_sf <- st_make_valid(polys)
# get area of each ADM1 region
area <- st_area(polys_sf) %>% units::set_units(., km^2)
# get centroids of each ADM1 region
centroids = st_centroid(polys_sf)

# get list of complete set of GID_1 data
polys_idsonly = polys_sf %>% st_drop_geometry() 
# centroids <- data.frame(ADM1_NAME=polys$NAME_1,X=polys$CENTER_LON, Y=polys$CENTER_LAT)
#region <- as.integer(as.factor(polys$ISO))



###### ACLED Time-varying conflict status ############

## create time varying matrices of conflict
# Armed Conflict in Infected Health zones

# to upload pre-downloaded data 
file_names_acled = paste0("data/conflict_all/", list.files("data/conflict_all/"))

acled_total = do.call(rbind,
                      lapply(file_names_acled, 
                             read_csv, col_select = c(event_date, year, disorder_type, event_type, 
                                                      civilian_targeting, iso:admin1, latitude, 
                                                      longitude, fatalities)))




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
  firstweek <- as.Date("2017-01-01")
  tmp <- tmp %>% 
    mutate(isoweek = isoweek(event_date)) %>%
    return(tmp)
  
}

acled <- fun_add_week_start_acled(acled_total)

# convert to simple features data frame
acled_sf <- st_as_sf(acled, coords = c("longitude","latitude"), crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")

acled_buff <- st_buffer(acled_sf, dist = 0.08999) # buffer around conflict points = 10,000 m, which is approximately 0.08999 arc degrees near the equator
polys_acled_join <- st_join(polys_sf, acled_buff, left = F)

#### create a weekly count of conflict evens 
acled_weekly_data = polys_acled_join %>% 
  st_drop_geometry %>%
  group_by(GID_0, COUNTRY, GID_1, NAME_1,year, isoweek) %>% 
  summarise(n_conflict_events_isoweek_adm1 = n(),
            n_fatalities_isoweek_adm1 = sum(fatalities)) %>%
  ungroup()

acled_total = acled_weekly_data %>%
  group_by(GID_0, COUNTRY, GID_1, NAME_1) %>%
  summarise(n_conflict_events_adm1 = n(),
            n_fatalities_total_adm1  = sum(n_fatalities_isoweek_adm1)) 

acled_ts = tibble(expand.grid(year = c(2013:2024),
                              isoweek = c(1:52),
                              GID_1 = polys_idsonly$GID_1)) %>%
  arrange(year, isoweek)

acled_ts2 = acled_weekly_data %>% 
  select(GID_1, year, isoweek, n_conflict_events_isoweek_adm1, n_fatalities_isoweek_adm1)

rollsum_4yr <- tibbletime::rollify(sum, window = 52*4)

acled_ts3 = acled_ts %>% 
  left_join(acled_ts2, by = join_by(GID_1, year, isoweek)) %>%
  arrange(year, isoweek) %>%
  mutate(n_conflict_events_isoweek_adm1 = ifelse(is.na(n_conflict_events_isoweek_adm1), 0, n_conflict_events_isoweek_adm1),
         n_fatalities_isoweek_adm1 = ifelse(is.na(n_fatalities_isoweek_adm1), 0, n_fatalities_isoweek_adm1)) %>%
  
  group_by(GID_1) %>%
  mutate(cum_conflict = rollsum_4yr(n_conflict_events_isoweek_adm1),
         cum_fatalities = rollsum_4yr(n_fatalities_isoweek_adm1)) 


write_rds(acled_ts3, "data/acled_ts.rds")

###### DHS time varying data on vaccine coverage ############


dhs_spatial = read_rds("data/DHS/spatial_dhs_boundaries_full_list_updatedNov24.RDS") 
dhs_valid <- st_make_valid(dhs_spatial)

dhs_spatial_join = st_join(polys_sf, dhs_valid, left = F)




# to upload pre-downloaded DHS Survey data 
file_names2 = paste0("data/DHS/DHS_survey_data_Nov24/", list.files("data/DHS/DHS_survey_data_Nov24/"))

dhs_all_files = do.call(rbind,
                        lapply(file_names2, 
                               read_csv))


dhs_surveys = dhs_all_files %>% dplyr::select(SurveyId,
                                              DPT3_vacc_coverage = Value,
                                              RegionId,
                                              SurveyYear,
                                              SurveyType,
                                              DHS_CountryCode)


dhs_total = dhs_spatial_join %>% left_join(dhs_surveys, by = join_by(REG_ID == RegionId), relationship = "many-to-many")

write_rds(dhs_total, "data/DHS/spatial_and_survey_data_updatedMar25.rds")

dhs_total_avg = dhs_total %>% 
  st_drop_geometry() %>%
  group_by(GID_1, SurveyYear) %>%
  mutate(mean_vax_cov = mean(DPT3_vacc_coverage, na.rm = T)) %>%
  ungroup()
  

dhs_ts = tibble(expand.grid(year = c(2002:2024),
                            GID_1 = polys_idsonly$GID_1)) %>%
  arrange(year)

dhs_ts2 = dhs_total_avg %>%
  select(GID_1, DPT3_vacc_coverage = mean_vax_cov, DHS_Survey_Year = SurveyYear) %>%
    distinct()
    

dhs_ts3 = dhs_ts %>% 
  # left_join(dhs_ts2, by = join_by(GID_1, year == DHS_Survey_Year), relationship = "many-to-many") %>%
  left_join(dhs_ts2, by = join_by(GID_1, year == DHS_Survey_Year)) %>%
  group_by(GID_1) %>%
  mutate(Vax_coverage = DPT3_vacc_coverage) %>%
  fill(Vax_coverage, .direction = "downup")


write_rds(dhs_ts3, "data/DHS/dhs_timeseries_survey_nogeo_updatedMar25.rds")


########## Diphtheria outbreak status ###########

diphtheria_df = read_csv("data/diphtheria/diphtheria_cases_time_series.csv") %>% 
  select(GID_0, COUNTRY, GID_1, NAME_1, isoweek, year, cumulative_cases) %>%
  mutate(outbreak_ever = 1,
         year_week = as.numeric(paste0(year, str_pad(isoweek, width = 2, side = "left", pad = 0)))) %>%
  group_by(GID_0, COUNTRY, GID_1, NAME_1) %>%
  mutate(outbreak_earliest = min(year_week)) %>%
  ungroup()

rollsum_24wk <- tibbletime::rollify(sum, window = 24)
diphtheria_ts = tibble(expand.grid(year = c(2017:2024),
                                   isoweek = c(1:52), 
                                   GID_1 = polys_idsonly$GID_1)) %>%
  arrange(year, isoweek) %>%
  # remove data from prior to week 11 in 2017
  filter(!(year == 2017 & isoweek < 11)) %>%
  left_join(diphtheria_df %>% select(GID_1, isoweek, year, cumulative_cases), by = join_by(year, isoweek, GID_1)) %>%
  group_by(GID_1) %>%
  mutate(year_iso = paste0(year, str_pad(isoweek, width = 2, side = "left", pad = "0"))) %>%
  arrange(year_iso) %>%
  tidyr::fill(cumulative_cases, .direction = "down") %>%
  ungroup() %>%
  mutate(cum_cases = case_when(is.na(cumulative_cases) ~ 0, 
                               TRUE ~ cumulative_cases)) %>%
  group_by(GID_1) %>%
  mutate(new_cases = cum_cases - lag(cum_cases, default = 0),
         new_cases_24wk = rollsum_24wk(new_cases),
         new_cases_24wk = case_when(is.na(new_cases_24wk) ~ 0,
                                    TRUE ~ new_cases_24wk),
         outbreak_status = case_when(new_cases_24wk > 1 ~ 1, 
                                     TRUE ~ 0)) 


####### Static data set creation ##############

static <- polys_idsonly %>% 
  left_join(diphtheria_df
            %>% select(GID_1, outbreak_ever, outbreak_earliest)) %>%
  distinct() %>%
  mutate(outbreak_ever = ifelse(is.na(outbreak_ever), 0, outbreak_ever)) %>%
  mutate(year = substr(as.character(outbreak_earliest), 1, 4)) %>%
  mutate(isoweek = substr(as.character(outbreak_earliest), 5, 6)) %>%
  left_join(acled_total %>% select(GID_1, n_conflict_events_adm1, n_fatalities_total_adm1)) %>%
  mutate(n_conflict_events_adm1 = ifelse(is.na(n_conflict_events_adm1), 0, n_conflict_events_adm1),
         n_fatalities_total_adm1 = ifelse(is.na(n_fatalities_total_adm1), 0, n_fatalities_total_adm1))


write_csv(static, "data/clean/static.csv")





######### timeseries data set for outcome of diphtheria #################
timeseries_full = tibble(expand.grid(year = c(2017:2024),
                                     isoweek = c(1:52), 
                                     GID_1 = polys_idsonly$GID_1)) %>%
  arrange(year, isoweek) %>%
  # remove data from prior to week 11 in 2017
  filter(!(year == 2017 & isoweek < 11)) %>%
  # remove weeks from after week 12 2024
  filter(!(year == 2024 & isoweek > 12)) %>%
  # left_join(dhs_ts3 %>% select(-DPT3_vacc_coverage), by = join_by(GID_1, year), relationship = "many-to-many") %>%
  left_join(dhs_ts3 %>% select(-DPT3_vacc_coverage), by = join_by(GID_1, year)) %>%
  left_join(acled_ts3 %>% select(year, isoweek, GID_1, cum_conflict, cum_fatalities), by = join_by(GID_1, year, isoweek)) %>%
  left_join(diphtheria_ts %>% select(year, isoweek, GID_1, cum_cases, new_cases, outbreak_status), by = join_by(GID_1, year, isoweek), relationship = "many-to-many") %>%
  mutate(year_iso_weekday = paste0(year, "-W", str_pad(isoweek, width = 2, side = "left", pad = "0"), "-", 1),
         week_start = ISOweek2date(year_iso_weekday)) %>%
  left_join(polys_idsonly %>% select(GID_0, COUNTRY, GID_1, adm1_pop_size)) %>%
  mutate(fatal_100k = cum_fatalities/adm1_pop_size * 100000) %>%
  filter(!is.na(Vax_coverage)) %>%
  group_by(GID_1) %>%
  mutate(Vax_cov_wavg = mean(Vax_coverage))


write_csv(timeseries_full, "data/clean/full_timeseries_updatedMar25.csv")


######### timeseries data set for outcome of vaccine coverage #################

rollsum_4yr_yr <- tibbletime::rollify(sum, window = 4)

acled_ts_yr = acled_ts %>% 
  left_join(acled_ts2, by = join_by(GID_1, year, isoweek)) %>%
  arrange(year, isoweek) %>%
  mutate(n_conflict_events_isoweek_adm1 = ifelse(is.na(n_conflict_events_isoweek_adm1), 0, n_conflict_events_isoweek_adm1),
         n_fatalities_isoweek_adm1 = ifelse(is.na(n_fatalities_isoweek_adm1), 0, n_fatalities_isoweek_adm1)) %>%
  group_by(GID_1, year) %>%
  mutate(n_conflict_events_yr_adm1 = sum(n_conflict_events_isoweek_adm1),
         n_fatalities_yr_adm1 = sum(n_fatalities_isoweek_adm1)) %>%
  ungroup() %>%
  select(year, GID_1, n_conflict_events_yr_adm1, n_fatalities_yr_adm1) %>%
  distinct() %>%
  group_by(GID_1) %>%
  arrange(year) %>%
  mutate(cum_conflict_4yr = rollsum_4yr_yr(n_conflict_events_yr_adm1),
         cum_fatalities_4yr = rollsum_4yr_yr(n_fatalities_yr_adm1)) 

ts_vax = dhs_ts2 %>%
  left_join(acled_ts_yr, by = join_by("GID_1", "DHS_Survey_Year" == "year")) %>%
  filter(!is.na(cum_conflict_4yr))


timeseries_vax = ts_vax %>%
  left_join(polys_idsonly %>% select(GID_0, COUNTRY, GID_1, adm1_pop_size)) %>%
  mutate(fatal_100k = cum_fatalities_4yr/adm1_pop_size * 100000)


write_csv(timeseries_vax, "data/clean/vax_timeseries.csv")
