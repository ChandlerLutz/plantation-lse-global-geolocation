## ./020-get_gmaps_geolocation.R

##Clear the workspace
rm(list = ls()) 
suppressWarnings(CLmisc::detach_all_packages())

##Set wd using the here package
setwd(here::here("./"))

suppressPackageStartupMessages({library(CLmisc); })

gmaps_utils <- load_module(here::here("core/gmaps_utils.R"))

dt <- fread("./data-raw/unique_region_operational_region.csv") %>%
  .[!duplicated(location), .(location)] %>%
  .[order(location)] %>%
  .[, gmaps_geolocation_input := location] %>%
  .[location == "Java", gmaps_geolocation_input := "Java Island, Indonesia"] %>%
  .[location == "Rio Archipelago", gmaps_geolocation_input := "Philippines"] %>% 
  .[location == "Portuguese East Africa", gmaps_geolocation_input := "Mozambique"] %>%
  .[location == "German East Africa", gmaps_geolocation_input := "Tanzania"] %>%
  .[location == "British East Africa", gmaps_geolocation_input := "Kenya"] %>%
  .[location == "British West Africa", gmaps_geolocation_input := "Ghana"] %>%
  .[location == "British Guiana", gmaps_geolocation_input := "Guyana"]


f_get_gmaps_geolocation <- function(location_string) {
  dt_out <- try({
    gmaps_utils$geocode_place_to_dt_with_bbox(location_string)
  }, silent = TRUE)

  if (inherits(dt_out, "try-error")) {
    warning(paste("Geocoding failed for location:", location_string))
    return(data.table(
      gmaps_geolocation_input = location_string
    ))
  } else {

    dt_out <- dt_out[, gmaps_geolocation_input := location_string] %>%
      setcolorder(c("gmaps_geolocation_input"))
    return(dt_out)
  }
}

dt_gmaps_geolocation <- lapply(
  unique(dt$gmaps_geolocation_input), f_get_gmaps_geolocation
) %>%
  rbindlist(use.names = TRUE, fill = TRUE) %>%
  .[order(gmaps_geolocation_input)] %>%
  merge(dt, by = "gmaps_geolocation_input", all.y = TRUE) %>%
  setcolorder(c("location", "gmaps_geolocation_input"))

saveRDS(
  dt_gmaps_geolocation,
  file = here::here("work/020-dt_lse_global_gmaps_geolocation.rds")
)

library(sf); library(dplyr)

dt_export <- copy(dt_gmaps_geolocation)

if (any(sapply(dt_export$gmaps_center_point, is.null))) {
  null_pts <- sapply(dt_export$gmaps_center_point, is.null)
  dt_export$gmaps_center_point[null_pts] <- lapply(1:sum(null_pts), function(x) st_point())
}

if (any(sapply(dt_export$gmaps_bbox_polygon, is.null))) {
  null_bbox <- sapply(dt_export$gmaps_bbox_polygon, is.null)
  dt_export$gmaps_bbox_polygon[null_bbox] <- lapply(1:sum(null_bbox), function(x) st_polygon())
}

dt_sf <- st_as_sf(dt_export, sf_column_name = "gmaps_center_point", crs = 4326)

dt_sf <- dt_sf %>%
  mutate(across(where(is.list) & !all_of(c("gmaps_center_point", "gmaps_bbox_polygon")), as.character))

output_file <- "work/020-dt_lse_global_gmaps_geolocation.gpkg"

points_layer <- dt_sf %>%
  select(-gmaps_bbox_polygon)

st_write(points_layer, dsn = output_file, layer = "regions_points", delete_layer = TRUE)

bbox_layer <- dt_sf %>%
  st_set_geometry("gmaps_bbox_polygon") %>%
  select(-gmaps_center_point)

st_write(bbox_layer, dsn = output_file, layer = "regions_bbox", delete_layer = TRUE)
