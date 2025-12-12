# Project 7: Baltimore City Homicide Dashboard

## Overview
This project creates an interactive RShiny dashboard to visualize Baltimore City homicide data from 2021-2025.

## Requirements
- R (version 4.0+)
- RShiny
- Required R packages: shiny, dplyr, ggplot2, lubridate, DT, plotly

## Setup Instructions

1. Install R and required packages:
```bash
   bash install_r.sh
```

2. Fetch the homicide data:
```bash
   bash fetch_data.sh
```

3. Run the Shiny app:
```bash
   Rscript run_app.R
```

## Docker Instructions

1. Build the Docker image:
```bash
   docker build -t baltimore-homicide-dashboard .
```

2. Run the container:
```bash
   docker run -p 3838:3838 baltimore-homicide-dashboard
```

3. Access the dashboard at: http://localhost:3838

## Project Structure
- `app.R` - Main Shiny application
- `data_processing.R` - Data extraction and cleaning functions
- `fetch_data.sh` - Script to download HTML data
- `install_r.sh` - R installation script
- `Dockerfile` - Docker configuration
- `data/` - Directory for raw HTML and processed CSV files
