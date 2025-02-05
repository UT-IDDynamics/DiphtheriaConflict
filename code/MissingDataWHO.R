#### Find weeks with no WHO Weekly bulletins #####
#### TCO
### 2024-11-26

library(tidyverse)

WHO_filenames = read.csv("data/WHO_weekly_bulletin_data/who_weekly_bulletin_filenames.csv")

dates = seq.Date(from = as.Date("2017-03-10"), to = as.Date("2024-03-18"), by = 7)
complete_weeks = as_tibble_col(dates, column_name = "dates") %>%
  mutate(week = isoweek(dates)) %>%
  mutate(year = isoyear(dates)) %>%
  left_join(WHO_filenames, by = c("year" = "year", "week" = "epiweek")) 

incomplete_weeks = complete_weeks %>%
  filter(is.na(url))


