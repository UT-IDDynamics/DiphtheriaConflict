##########################################################################################
########################### DHS API data collection script     ###########################
########################### Diphtheria model WHO region Africa ###########################
########################### Author: Tierney O'Sullivan         ###########################
########################### Date last modified: 2024-11-28    ###########################
##########################################################################################

###### Establish countries ################

library(here)
library(tidyverse)
library(ISOcodes)
library(RJSONIO)

# load dataframe of countries included in the WHO Africa region
countries = read_csv("data/country_data/country_list.csv", col_names = "Name") %>% 
  mutate(Name = case_when(Name == "C\x99te d'Ivoire" ~ "Côte d'Ivoire",
                          TRUE ~ Name))

# filter the 
country_df = ISO_3166_1 %>% 
  filter(Name %in% countries$Name | Official_name %in% countries$Name | Common_name %in% countries$Name) %>%
  mutate(Common_name = case_when(Name == "Côte d'Ivoire" ~ "Cote d'Ivoire",
                                 Name == "Cabo Verde" ~ "Cape Verde",
                                 Name == "Congo, The Democratic Republic of the" ~ "Congo Democratic Republic",
                                 TRUE ~ Common_name)) %>%
  mutate(Name_use = case_when(Name %in% c("Côte d'Ivoire", 
                                          "Cabo Verde", 
                                          "Congo, The Democratic Republic of the",
                                          "Tanzania, United Republic of") ~ Common_name,
                              TRUE ~ Name))

# load data dictionary from DHS API 
# includes a list of countries with data, their names and the DHS_CountryCode
# these will be the codes used to query the data for those countries from the API
dhs_countries = read_csv("data/DHS/DHS_country_list.csv")

dhs_df = country_df %>% left_join(dhs_countries, by = join_by("Name_use" == "CountryName")) %>%
  filter(!is.na(DHS_CountryCode))

write_csv(dhs_df, "data/country_data/DHS_countries_iso.csv")

# load survey list for all DHS surveys, will need to identify appropriate surveyIDs from the DHS API query
# url = https://api.dhsprogram.com/rest/dhs/surveys?returnFields=SurveyId,SurveyYearLabel,SurveyType,CountryName&f=html

dhs_surveys = read_csv("data/DHS/DHS_survey_list_updatedNov2024.csv") %>% 
  left_join(dhs_countries) %>%
  select(SurveyId: DHS_CountryCode) %>%
  # include only DHS surveys 
  filter(SurveyType == "DHS") %>%
  # include relevant countries only
  filter(CountryName %in% dhs_df$Name_use) %>%
  left_join(dhs_df %>% select(Alpha_2, DHS_CountryCode)) %>%
  # remove survey data from before the year 2000
  filter(str_starts(SurveyYearLabel, "2"))


# Import DHS Indicator data for TFR for each survey

for(i in 2:nrow(dhs_surveys)){
  
  countryid = dhs_surveys$DHS_CountryCode[i]
  surveyid = dhs_surveys$SurveyId[i]
  iso2code = dhs_surveys$Alpha_2[i]
  # use DHS API to download DHS Survey data for the DPT variable of interest
  # key indicator = CH_VACC_C_DP3
  # definition: Percentage of children 12-23 months who had received DPT 3 vaccination 
  # breakdown = subnational to get ADM1 estimates
  # indicatiorIds = CH_VACC_C_DP3
  # countryIds = use DHS country code from dataframe above (iterate via for loop)
  # surveyIds = AO2015DHS use DHS country code from dataframe above (iterate via for loop & survey year of interest)
  json_file <- fromJSON(paste0("https://api.dhsprogram.com/rest/dhs/data?breakdown=subnational&indicatorIds=CH_VACC_C_DP3&countryIds=", countryid,"&surveyIds=", surveyid,"&lang=en&returnGeometry=false&f=json"))
  
  # Unlist the JSON file entries
  json_data <- lapply(json_file$Data, function(x) { unlist(x) })
  
  # Convert JSON input to a data frame
  APIdata <- as.data.frame(do.call("rbind", json_data),stringsAsFactors=FALSE)
  
  write.csv(APIdata, paste0("data/DHS/DHS_survey_data_Nov24/", iso2code, "_", surveyid,".csv"))
  
}


