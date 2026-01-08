## ./010-get_se_shp.R

##Clear the workspace
rm(list = ls()) 
suppressWarnings(CLmisc::detach_all_packages())

##Set wd using the here package
setwd(here::here("./"))

suppressPackageStartupMessages({
  library(CLmisc); library(rnaturalearth); library(sf); 
})


dt_asia_sf <- ne_countries(continent = "Asia", returnclass = "sf", scale = "medium") %>%
  as.data.table() %>%
  .[admin %chin% c("Cambodia", "India", "Indonesia", "Laos", "Malaysia", "Myanmar",
                   "Philippines", "Sri Lanka", "Thailand", "Vietnam")] %>%
  select_by_ref(c("admin", "iso_a3", "geometry")) %>%
  .[, geometry := st_transform(geometry, crs = 8859)]


## ggplot() + geom_sf(data = dt_asia_sf$geometry) +
##   geom_sf_text(data = st_as_sf(dt_asia_sf), aes(label = admin)) + 
##   theme_minimal()

saveRDS(dt_asia_sf, file = here::here("work/010-dt_asia_shp.rds"))
