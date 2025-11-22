# Project 7 - Baltimore City Homicide Dashboard (2021-2025)

**Author:** Aayush Shrestha  
**Course:** COSC 352, Morgan State University  
**Date:** November 2025

## Overview

This project is an interactive R Shiny dashboard that automatically scrapes, processes, and visualizes Baltimore City homicide data from 2021-2025. The application is fully containerized using Docker and provides real-time analytics on crime patterns, case closure rates, and surveillance camera effectiveness.

## Features

- **Automated Data Collection**: Web scraping from Cham's Page for all 5 years (2021-2025)
- **Interactive Dashboard**: 
  - Year and age range filters
  - Keyword search functionality
  - Real-time data filtering
- **Visualizations**:
  - Homicides by year (bar chart)
  - Monthly trends (time series)
  - Cause-of-death distribution
  - Camera surveillance impact on closure rates
- **Analytics**:
  - Case closure rate analysis
  - Camera effectiveness comparison
  - Average victim demographics
- **Data Table**: Searchable, sortable table with full dataset

## Tech Stack

- **Language**: R
- **Framework**: Shiny, shinydashboard
- **Web Scraping**: rvest, httr
- **Data Processing**: dplyr, lubridate, janitor
- **Visualization**: ggplot2
- **Tables**: DT (DataTables)
- **Containerization**: Docker (rocker/shiny base image)

## Data Sources

- 2021: http://chamspage.blogspot.com/2021/
- 2022-2025: http://chamspage.blogspot.com/[year]/01/[year]-baltimore-city-homicide-list.html

## Quick Start

### Prerequisites
- Docker Desktop installed and running

### Run the Application

chmod +x run.sh
text

Open your browser and navigate to: [**http://localhost:3838**](http://localhost:3838)

### Stop the Application

Press `Ctrl + C` in the terminal where the container is running.

## Project Structure


text
    # Main Shiny application with scraping logic
├── Dockerfile # Docker configuration
├── run.sh # Build and run script
├── README.md # Project documentation
text

## Key Insights

The dashboard answers important questions:

1. **Surveillance Effectiveness**: How do case closure rates differ when surveillance cameras are present vs absent?
2. **Cause Analysis**: What are closure rates by cause of death (shooting, stabbing, blunt force, other)?
3. **Temporal Patterns**: How do homicides vary by year and month?
4. **Demographics**: What is the average age of victims across different categories?

## Docker Details

- **Base Image**: rocker/shiny:latest (with linux/amd64 platform for Apple Silicon compatibility)
- **Port**: 3838
- **Dependencies**: All R packages automatically installed during build
- **Build Time**: ~5-10 minutes for first build (cached for subsequent builds)

## Development Notes

- Data is scraped on application startup
- Handles missing or malformed data gracefully with fallback mechanisms
- Responsive filters update all visualizations in real-time
- Compatible with Apple Silicon Macs (M1/M2/M3) through Rosetta 2 emulation
