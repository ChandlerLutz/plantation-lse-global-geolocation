# Historical Plantation Geolocation

This repository contains an R-based pipeline designed to acquire spatial data and geocode historical plantation and economic data from the **early 20th century**. 

The code handles the translation of colonial and historical place names (e.g., "German East Africa", "British Guiana") into modern equivalents to ensure accurate geocoding via the Google Maps API.

---

## Project Structure

```text
.
├── .gitignore
├── .here                  # Root anchor for the 'here' package
├── 010-get_se_shp.R       # Script: Fetches Natural Earth shapefiles
├── 010-get_se_shp.R~      # (Backup)
├── 020-get_gmaps_geolocation.R # Script: Batch geocoding pipeline
├── 020-get_gmaps_geolocation.R~ # (Backup)
├── core/
│   └── gmaps_utils.R      # Module: Google Maps API helper functions
├── data-raw/
│   └── unique_region_operational_region.csv # Input data for geocoding
└── work/                  # Output directory for RDS and GeoPackage files
```

## Dependencies

The project relies on the following R packages. Ensure they are installed before running the scripts:

*   **Core/Data Manipulation:** `data.table`, `dplyr`, `here`
*   **Spatial:** `sf`, `rnaturalearth`
*   **API/Web:** `ggmap`, `keyring`
*   **Modularization:** `box`
*   **Custom/Internal:** `CLmisc` (Ensure this package is available in your environment)

## Setup and Configuration

### Google Maps API Key
Script `020` and the `core/gmaps_utils.R` module require a valid Google Maps API Key with **Geocoding API** enabled. The key is retrieved securely using the `keyring` package.

Before running the scripts, set your API key in your R console:

```r
# Run this once in your R console
keyring::key_set("gmaps_lse_key")
# You will be prompted to paste your API key securely
```

*Note: Ensure your Google Cloud Project has billing enabled, as the Geocoding API is a paid service.*

## Usage

### 010-get_se_shp.R
**Purpose:** Fetches modern administrative boundaries for specific South and Southeast Asian countries relevant to the study.

1.  Downloads "Medium" scale data from Natural Earth.
2.  Filters for: Cambodia, India, Indonesia, Laos, Malaysia, Myanmar, Philippines, Sri Lanka, Thailand, and Vietnam.
3.  Transforms the geometry to **CRS 8859** (WGS 84 / Equal Earth Asia-Pacific).
4.  **Output:** `work/010-dt_asia_shp.rds`

### 020-get_gmaps_geolocation.R
**Purpose:** Geocodes a list of regions provided in `data-raw/`, accounting for early 20th-century historical names.

1.  **Preprocessing:** Reads `unique_region_operational_region.csv`.
2.  **Historical Mapping:** Manually maps colonial names to modern equivalents to ensure API success:
    *   *Portuguese East Africa* $\to$ Mozambique
    *   *German East Africa* $\to$ Tanzania
    *   *British East Africa* $\to$ Kenya
    *   *British West Africa* $\to$ Ghana
    *   *British Guiana* $\to$ Guyana
    *   *Rio Archipelago* $\to$ Philippines
3.  **Geocoding:** Uses `core/gmaps_utils.R` to fetch coordinates, address components, and viewports (bounding boxes).
4.  **Output:**
    *   `work/020-dt_lse_global_gmaps_geolocation.rds`: Full data table with simple features columns.
    *   `work/020-dt_lse_global_gmaps_geolocation.gpkg`: GeoPackage containing `regions_points` and `regions_bbox` layers.

## Modules

### core/gmaps_utils.R
A reusable module loaded via `box`. It contains:
*   `geocode_place_to_dt_with_bbox(place_string)`: Robust wrapper around `ggmap::geocode`. It handles errors, validates result types (e.g., political, locality, natural feature), and constructs `sf` point and polygon objects from the raw JSON response.

## Authors

*   **Valeria Giacomin**
*   **Chandler Lutz**
*   **Matteo Calabrese**

## Citation

If you use this code or data in your research, please cite it as follows:

> Giacomin, V., & Lutz, C., & Calabrese, M. (2025). plantation-lse-global-geolocation [Computer software].

### BibTeX

```bibtex
@misc{giacomin_plantation_2025,
  author = {Giacomin, Valeria and Lutz, Chandler and Calabrese, Matteo},
  title = {plantation-lse-global-geolocation},
  year = {2025},
  publisher = {GitHub},
  journal = {GitHub repository},
  url = {https://github.com/ChandlerLutz/plantation-lse-global-geolocation}
}
```
