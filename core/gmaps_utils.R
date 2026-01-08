## core/gmaps_utils.R

## gmaps_api <- keyring::key_set("gmaps_lse_key")
gmaps_api_key <- keyring::key_get("gmaps_lse_key")

ggmap::register_google(key = gmaps_api_key)

geocode_place_to_dt_with_bbox <- function(place_string) {
  
  box::use(
    ggmap[has_google_key, geocode], 
    data.table[data.table, fcase, as.data.table, rbindlist],
    sf[st_point, st_polygon, st_sfc]
  )
  
  if (!has_google_key()) {
    stop("Google Maps API key not set. Use ggmap::register_google().")
  }

  geocode_list <- tryCatch({
    geocode(location = place_string, output = "all")
  }, error = function(e) {
    stop(paste("API call failed for:", place_string, "\nError:", e$message))
  })

  if (is.null(geocode_list) || geocode_list$status != "OK" || 
        length(geocode_list$results) == 0) {
    stop(paste("Geocoding failed for:", place_string, "- No results returned."))
  }
  
  res <- geocode_list$results[[1]]

  # --- UPDATED: Expanded Type Checking ---
  # We check if the result intersects with a broader list of acceptable types
  # to handle Countries, Continents, Islands (natural_feature), and Historical (political)
  result_types <- res$types
  
  valid_types <- c(
    "locality", "sublocality", 
    "administrative_area_level_1", "administrative_area_level_2", "administrative_area_level_3", 
    "country", "continent", 
    "natural_feature", "colloquial_area", "political", 
    "archipelago", "establishment" # Establishment sometimes catches odd historical names
  )
  
  if (!any(result_types %in% valid_types)) {
    warning(paste0("'", place_string, "' returned type '", result_types[1], 
                   "' which is not in the standard valid list. Proceeding anyway."))
  }
  
  safe_pluck_base <- function(l, ...) {
    path <- list(...)
    for (p in path) {
      l <- l[[p]]; if (is.null(l)) return(NULL)
    }
    return(l)
  }
  
  extract_component <- function(components, type) {
    if (is.null(components)) return(NA_character_)
    match <- Filter(function(x) type %in% x$types, components)
    if (length(match) > 0) return(match[[1]]$long_name) else return(NA_character_)
  }

  # --- UPDATED: Dynamic Type Assignment ---
  # Instead of fcase, we take the first type returned by Google (usually the most descriptive)
  place_type <- result_types[1]

  dt <- data.table(
    gmaps_place_query_string = place_string,
    gmaps_place_type = place_type,
    gmaps_lon = safe_pluck_base(res, "geometry", "location", "lng"),
    gmaps_lat = safe_pluck_base(res, "geometry", "location", "lat"),
    gmaps_formatted_address = safe_pluck_base(res, "formatted_address"),
    gmaps_place_id = safe_pluck_base(res, "place_id"),
    # These will often be NA for continents/oceans, which is expected behavior
    gmaps_city = extract_component(res$address_components, "locality"),
    gmaps_county = extract_component(res$address_components, "administrative_area_level_2"),
    gmaps_state = extract_component(res$address_components, "administrative_area_level_1"),
    gmaps_country = extract_component(res$address_components, "country"),
    
    gmaps_bbox_ne_lat = safe_pluck_base(res, "geometry", "bounds", "northeast", "lat"),
    gmaps_bbox_ne_lon = safe_pluck_base(res, "geometry", "bounds", "northeast", "lng"),
    gmaps_bbox_sw_lat = safe_pluck_base(res, "geometry", "bounds", "southwest", "lat"),
    gmaps_bbox_sw_lon = safe_pluck_base(res, "geometry", "bounds", "southwest", "lng")
  )

  # 1. Create BBOX polygon
  if (all(!is.na(c(dt$gmaps_bbox_sw_lon, dt$gmaps_bbox_sw_lat, dt$gmaps_bbox_ne_lon, 
                   dt$gmaps_bbox_ne_lat)))) {
    coords <- matrix(c(
      dt$gmaps_bbox_sw_lon, dt$gmaps_bbox_sw_lat,
      dt$gmaps_bbox_sw_lon, dt$gmaps_bbox_ne_lat,
      dt$gmaps_bbox_ne_lon, dt$gmaps_bbox_ne_lat,
      dt$gmaps_bbox_ne_lon, dt$gmaps_bbox_sw_lat,
      dt$gmaps_bbox_sw_lon, dt$gmaps_bbox_sw_lat
    ), ncol = 2, byrow = TRUE)
    
    bbox_poly <- st_polygon(list(coords))
    dt[, gmaps_bbox_polygon := list(st_sfc(bbox_poly, crs = 4326))]
  } else {
    dt[, gmaps_bbox_polygon := list(st_sfc(st_polygon(), crs = 4326))]
  }

  # 2. Create the center point sfc
  if (is.null(dt$gmaps_lon) || is.null(dt$gmaps_lat)) {
    stop("Could not extract coordinates from the geocoding result.")
  }
  
  center_point <- st_point(c(dt$gmaps_lon, dt$gmaps_lat))
  dt[, gmaps_center_point := list(st_sfc(center_point, crs = 4326))]
    
  return(dt)
}
