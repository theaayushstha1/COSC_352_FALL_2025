# Baltimore Homicide Dashboard

## How to Run

1. Open R or RStudio
2. Set working directory to this folder
3. Run:
   source("data_loader.R")
   shiny::runApp("app.R")

## Requirements

Install these packages if needed:

install.packages(c("shiny", "DT", "leaflet", "dplyr", "lubridate", "rvest", "stringr"))

## What It Does

- Select year (2021–2025)
- Search by name or location
- View map, table, and monthly stats
