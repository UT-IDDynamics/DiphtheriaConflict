# To create mapbox maps with Plotly, you'll need a Mapbox account and a Mapbox Access Token that you can add to your Plotly Settings. If you're using a Plotly On-Premise server, please see additional instructions here: https://help.plot.ly/mapbox-atlas/.

library(plotly)
library(tidyverse)
library(processx)
library(sf)
library(reticulate)


source("code/mapbox.R")

# Load data -----------------------------------------------------------------------------------

adm1_pop = read_rds("data/geographies/ADM1_pop.rds")
static = read_csv("data/clean/static.csv")

static = static %>% 
  # make variable: n deaths from conflict per 100,000 population
  mutate(p_100k_conflict_fatal = n_fatalities_total_adm1 /pop_size * 100000)

# select vars for map
adm1_map = left_join(adm1_pop, static %>% 
                       dplyr::select(GID_1,
                                     outbreak_ever:n_fatalities_total_adm1, 
                                     p_100k_conflict_fatal))

# clean up geographies
adm1_map = st_make_valid(adm1_map)
adm1_map2 = adm1_map %>%
  # establish centroids of each ADM1 region
  mutate(centroid = st_centroid(geom),
         longitude = st_coordinates(centroid)[, 1],
         latitude = st_coordinates(centroid)[, 2]) %>%
  filter(!is.na(outbreak_ever)) %>%
  # create categorical conflict fatalities for hover info
  mutate(conflict_label = case_when(p_100k_conflict_fatal <= 1 ~ "0-1",
                                    p_100k_conflict_fatal >1 & p_100k_conflict_fatal <= 10 ~ "1-10",
                                    p_100k_conflict_fatal >10 & p_100k_conflict_fatal <=100 ~ "10-100",
                                    p_100k_conflict_fatal >100 ~ ">1000"))

adm1_nogeo = adm1_map2 %>% st_drop_geometry()

# Scales for selected data --------------------------------------------------------------------

# Colors
color.palette = c("#5c4e6e", "#c46439")

# Sizes
sizes.min <- 10 # minimum size (pixels)
sizes.max <- 18 # maximum size (pixels)
sizes <- c(sizes.min,sizes.max)
marker.scale <- 2

# Visual map variables ------------------------------------------------------------------------

layout.mapbox <- list(
  # subplot variables: set x and y domain of mapbox subplot (in plot fractions)
  domain = list(x = c(0, 1), y = c(0, 1)),
  
  # map variables
  center = list(lat = 0.5, lon = 21.0),
  zoom = 2.5, # default 1
  bearing = 0., # default 0 degrees
  pitch = 0., # default 0
  
  # Set custom Mapbox base map style:  
  style = 'mapbox://styles/ericmarty/cjoetwe010d2r2snrvujwgkbw'
)

# Map ------------------------------------------------------------------------------------

p.mapbox <- adm1_nogeo %>% 
  plotly::plot_mapbox(mode = 'markers', 
                      showlegend = T, 
                      y = ~latitude, 
                      x = ~longitude,
                      
                      # COLORS
                      colors = color.palette, # discrete palette for explicitly mapping data to color
                      color = ~ifelse(outbreak_ever == 0, "Absent", "Present"), # numeric mappings not supported
                      
                      # SIZES
                      size = ~scales::rescale(p_100k_conflict_fatal,sizes),
                      
                      # MARKERS
                      marker = list(
                        symbol = "circle",
                        opacity = .85,
                        sizemode = "diameter",
                        sizeref = marker.scale,
                        showlegend = TRUE
                      ),
                      
                      # HOVER TEXT
                      hoverinfo = "text",
                      text = ~paste(COUNTRY, ",", NAME_1,",", conflict_label)
  ) %>%
  plotly::layout(
    hovermode = 'closest',
    mapbox = layout.mapbox,
    # put color legend within plot boundaries
    legend = list(x = 0.05, y = 0.35, title=list(text = "<b> Diphtheria status </b>"))
  ) 

# View interactive map
p.mapbox

# Export as a static image
# Requires installation of command line tool `kaleido`  from plotly
# https://github.com/plotly/kaleido


# reticulate::use_miniconda('r-reticulate')
save_image(p.mapbox, 
           paste0("maps/","conflict_by_diphtheria_presence_nolog_legend",".png"),width=762,height=706, scale = 2)

