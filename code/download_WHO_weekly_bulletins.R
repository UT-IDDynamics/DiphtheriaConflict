library(pdftools)
library(purrr)
library(tidyverse)


# get the data set of file names for the WHO African region weekly bulletins
file_names <- read_csv("data/who_weekly_bulletin_filenames.csv")
# extract the urls for each bulletin
urls = file_names$url

# create a pdf name to store each weekly bulletin under labeled with EPIWEEK and YEAR
pdf_names = paste0("weeklybulletins/", "epiweek_", file_names$epiweek, "_year_",file_names$year, ".pdf")

# use walk2() to download the urls 
# walk2 is a function from the purrr package that is similar to map2
walk2(urls, pdf_names, download.file, mode = "wb")

# now use the pdf_text() function from the pdftools package to extract text from the pdfs
# stores the pdf extracted text as a long character vector, each is one item in a list
raw_text <- map(pdf_names, pdf_text)


# use map to apply the str_detect() function to return a TRUE or FALSE if the pdf contains the word diphtheria
# return FALSE or TRUE
# use (?i) to ensure that the query is not case sensitive
cont_diphtheria = raw_text %>% map(function(x) str_detect(x, pattern = "(?i)diphtheria"))
# consolidate to a single true value if there was any mention of diphtheria in the entire document, and false otherwise
cont_diphtheria_ls = lapply(cont_diphtheria, any)
cont_diphtheria_vec = unlist(cont_diphtheria_ls)

cont_diphtheria_df = tibble(epiweek = file_names$epiweek, 
                            year = file_names$year, 
                            url = file_names$url,
                            cont_dphth = cont_diphtheria_vec)
