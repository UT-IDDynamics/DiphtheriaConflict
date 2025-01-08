# Data file directory

Most data files are available for download, with instructions below.


## Data requiring registration
### Conflict data
Data on fatalities from armed conflict events, their timing and locations are available from the [Armed Conflict Location and Event Database](https://acleddata.com/) (ACLED). Instructions for registration for an API key are available [here](https://acleddata.com/data/).

### Vaccination Coverage Data

Subnational data on childhood three-dose diphtheria tetanus and pertussis (DTP3) vaccination coverage are available as survey-based estimates from the [Demographic Health Survey](https://dhsprogram.com/data/). Data are free to users after [registration](https://dhsprogram.com/data/Registration-Rationale.cfm). This project used the most up to date data from DHS surveys as of November 25, 2024. 

### ADM1 geographic data

### ADM1 population level data

# Data description

## Diphtheria cases

Data on diphtheria case counts in sub-Saharan Africa are reported in the World Health Organization’s African region’s weekly bulletin on outbreaks and other emergencies, which report case counts and other metadata (patient age, date of onset of symptoms, date of laboratory confirmation, case fatality rate, etc.) at the ADM1 (subnational: province/state) level [(World Health Organization, 2024)](ttps://www.afro.who.int/health-topics/disease-outbreaks/outbreaks-and-other-emergencies-updates?page=0). These data are available in tables in pdfs and so variables will need to be extracted from these reports via text scraping from the pdfs based on diphtheria keywords. Where available, I also used the Nigerian CDC’s situation reports for more granular data on diphtheria cases for each ADM1 region as these were updated more often than the case counts in the WHO data [(Nigeria Centre for Disease Control and Prevention, 2023)](https://ncdc.gov.ng/diseases/sitreps/?cat=18&name=An%20Update%20of%20Diphtheria%20Outbreak%20in%20Nigeria).

#### Appropriateness
These data are the most comprehensive and thus most appropriate publicly available data set for suspected and confirmed diphtheria cases at a subnational level in the WHO African Region. Because the research question was to estimate the risk of diphtheria outbreaks at a geographic scale more granular than the country level, this is the most appropriate data set to use. 

#### Robustness
The WHO recommends that surveillance for diphtheria should be national and facility-based. Because it has been historically rare, the WHO recommends case-based surveillance, and reporting of suspected and confirmed cases of diphtheria. Unfortunately there is no consistent surveillance system or definitive reporting mechanisms of suspected or diphtheria cases across countries in Africa, and International Health Regulations (IHR) do not require reporting of diphtheria cases [(World Health Organization, 2018)](https://cdn.who.int/media/docs/default-source/immunization/vpd_surveillance/vpd-surveillance-standards-publication/who-surveillancevaccinepreventable-04-diphtheria-r2.pdf?sfvrsn=3840f49a_10&download=true). 

Thus, it is extremely likely that the diphtheria cases reported to the WHO are a severe undercount, and the real burden of the disease in likely much higher. It is for this reason that we decided to use the suspected case counts rather than the laboratory confirmed case counts for this analysis. Case definitions for suspected diphtheria cases are based on illness of the upper respiratory tract that are characterized by pharyngitis, nasopharyngitis, tonsillitis, or laryngitis AND an adherent pseudomembrane of the pharynx, tonsils, larynx and nose [(World Health Organization, 2018)](https://cdn.who.int/media/docs/default-source/immunization/vpd_surveillance/vpd-surveillance-standards-publication/who-surveillancevaccinepreventable-04-diphtheria-r2.pdf?sfvrsn=3840f49a_10&download=true). I chose to include suspected cases because laboratory confirmation is not feasible for all suspected cases, especially in resource-poor areas and areas with large numbers of suspected cases. 

This data set, while including weekly reports, often does not have updated data for diphtheria outbreaks at a weekly time step. For example, the WHO weekly report may summarize that 1000 new reported cases have been reported between a set of dates that span months, rather than a 7 day reporting period.  

Because of the likely severe underestimation of diphtheria cases, and the irregular reporting intervals for new cases, this data set is not suitable for modelling granular time series of new diphtheria cases. Instead, we plan to use it to construct a binary outcome variable of whether each state or province currently has a diphtheria outbreak or not. In order to ensure that the diphtheria outbreaks are in fact outbreaks, we limited the case definition of reported diphtheria presence for each state or territory to having more than 1 diphtheria case reported in the past 24 weeks or months (6 month time frame to allow for delays in reporting). 

#### Strengths and weaknesses
The strength of this data set is that it is publicly available and reports diphtheria cases at a subnational level. The reports also span a long time frame, from March (Epiweek 11) 2017 to present, enabling longitudinal analysis. 

The weaknesses are many. The pdfs contain tables with the information, but data are not systematically entered so some manual extraction is required to obtain data on diphtheria cases. There are a few weeks of missing reports (Weeks 31-32 2023, Week 17 2021, Week 52 2020, Weeks 43-46 2020, and Week 11 2020). Some metadata is reported for small outbreaks, but often is excluded once the outbreaks grow in scale. There is also no information on testing rates, so it is difficult to know if large outbreaks are simply larger because there is greater surveillance. 

## Armed conflict data
Conflict event data is collected by the Armed Conflict Location and Event Data Project (ACLED) and is freely available to researchers who register for an API key, which allows users to download data to match specific search criteria in a .csv format. Their data are available in near-real time with each observation representing a single conflict event, the date it occurred, the location (latitude, longitude, ADM1, ADM2, AMD3, ISO3 country code, etc.), event type (e.g. violence against civilians, battles, etc.), and the scale (e.g. number of affected or killed) among many others. 

#### Appropriateness
The ACLED data is the most appropriate data set for this analysis because of it's high geographic and temporal coverage of the WHO African Region member countries for the duration of the study period. Only a single country was excluded from this analysis because it did not have conflict data spanning back to 2013. It is the leading source of real-time data on conflict events throughout the world, and for the countries included in this analysis it had conflict event data from 1997 to present. 

#### Robustness
The ACLED data measures both violent and non-violent actions between a variety of actors, including political agents, governments, rebels, militias, political parties, rioters, protesters, and others. They gain information from a variety of sources in over 75 languages, and the project is especially robust in Africa, where the program was initially developed. The data are published weekly, but first undergo a multi-stage internal review process to ensure their integrity, and the methodology, coding decisions, and other information are available on the ACLED website [(ACLED, 2023)](https://acleddata.com/acleddatanew/wp-content/uploads/dlm_uploads/2023/06/ACLED_Codebook_2023.pdf).

#### Strengths and weaknesses
ACLED data strengths include it’s being freely available (upon registering for access via an API key). The data are consistent across countries and time periods. They also include extremely granular data on the locations of the events at the latitude and longitude point as well as the administrative names. They also include detailed metadata on the nature of the events, which allows researchers to select event types that are most important to the research question of interest. For example, since we are interested in studying whether there is a destabilizing effect of conflict events that increases the risk of diphtheria outbreaks, we were able to limit the conflict data to just include reported fatalities from conflict events, thus removing less serious events from the analysis (e.g. non-violent protests). The data would allow many different formulations to be tested as well (e.g. including only events that included violence against civilians).  

## Regional DPT3 immunization data
Regional rates of DPT3 completion within childhood immunization schedules are estimated from the Demographic Health Survey, which collects data in a way to make it comparable across countries using standard model questionnaires. We specifically plan to access this regional level data for each country’s subnational survey data from the beginning of the diphtheria surveillance in 2017 until the most recent available data. If countries do not have data available in 2017, we plan to use their most recent vaccine coverage estimate available. We accessed the data via the DHS’s API, with which I was able to pull regional key indicator data on vaccination coverage rate estimates directly from DHS. The date of final access for the DHS surveys used in the analysis was November 25, 2024. 

Specifically, the data we plan to use from DHS’s regional surveys is the key indicator estimating regional rates of:

`CH_VACC_C_DP3` = Percentage of children 12-23 months who had received DPT 3 vaccination

#### Appropriateness
The Demographic Health Surveys are the most complete dataset available for estimating childhood vaccination levels in African countries at the subnational level. The DHS surveys contain a wealth of information, including vaccination coverage estimates for children between the ages of 12-23 months and 24-25 months. It is possible to get individual-level response data for each of these surveys, which include survey weights for each respondent. However, for this analysis, I was solely interested in the estimated childhood DPT3 vaccine coverage estimate for each ADM1. The DHS API allows this population-level estimate data to be extracted for each survey location and year. 

#### Robustness
The DHS ADM1 level vaccine coverage estimates are given as a point estimate only, and confidence limits are not reported, which makes it difficult to know the degree of uncertainty surrounding the data. It would be possible to reconstruct confidence intervals around these values, but this was beyond the scope of this project. We thus only used the point estimates for the vaccine coverage data. 

#### Strengths and weaknesses
The DHS data’s main strengths lie in their longitudinal nature and their mostly complete geographical coverage of countries within the WHO African region. They also have comparable surveys across times and locations, which make the results comparable across times and locations. Additionally, the DHS provides spatial data polygons for all surveys so the data for vaccine coverage in each location and survey are assigned spatially, not just via region name. This is important because some administrative regions have changed over time. 

The weaknesses include not having estimates of overall diphtheria coverage, just coverage within children between 12-23 months of age. Additionally, the DHS surveys are not conducted at regular time intervals and the time between surveys vary from country to country. In order to address this, we assumed vaccine coverage in each state remained at its most recent measurement until a new survey was published with updated estimates.  

## ADM1 geographic data
I used spatial data from the Database of Global Administrative Areas (GADM 4.1) for the ADM1 level geographic boundaries for all mapping and any spatial joining.

#### Appropriateness
This is a data set that contains polygons of each state or territory (ADM1) in the world, and is the most recent available version.

#### Robustness
It will allow for appropriate assignment of any spatial data (e.g. conflict events, location of vaccine coverage survey estimates) to be assigned via a spatial join rather than matching names, which is important for areas that have had geopolitical changes over the past few years. 

#### Strengths and weaknesses
The strengths of this data are it’s completeness and the inclusion of a large number of codes to identify countries and subnational regions under different naming conventions. The weakness of this data is that it is quite large, so performing spatial operations can be time consuming depending on your computer’s processing power. 

## ADM1 population level data
The population sizes of each ADM1 region in each country of interest will be obtained from LandScan’s annual global 1 km population raster (Sims et al., 2023), which can be used with the ADM1 geographic polygons from GADM to estimate yearly population sizes for each region of interest (GADM, 2022). This will allow me to adjust the rates of fatalities from conflict events to a per-capita basis (e.g. rates per 100,000 residents). 

#### Appropriateness
This population is appropriate for this analysis specifically because it can be overlaid with the GADM ADM1 polygons to get a good estimate of the size of the population in 2022. This is helpful because most of the world datasets of population that already exist are only available at the country level, not subnational. 

#### Robustness
The data are downloaded as a raster grid, which contains raster cells that approximate a 1 km by 1 km grid at the equator. This means that the further away from the equator, the less accurate these cells are at approximating a 1 km area. This is unlikely to be a major problem in this analysis because many of the countries fall along the equator, but it is a consideration especially for countries like South Africa. 

#### Strengths and weaknesses
The main strength of this data set is that it allows a single operation to estimate the population sizes of each ADM1 region in each country included in the analysis. The weaknesses include that I only have the 2022 data, and since I am interested in conducting a longitudinal analysis from 2017-2024, the true population estimates may be different than what is calculated here. 


