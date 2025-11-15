# Project 7: Baltimore City Homicides Dashboard

## Overview
An interactive R Shiny dashboard that visualizes Baltimore City homicide data from 2021-2025. The dashboard scrapes data from Cham's Baltimore Crime Blog and presents comprehensive analytics through multiple interactive visualizations.

## Features

### 📊 Dashboard Tabs

1. **Overview**
   - Total homicides across all years
   - Current year (2025) homicides
   - Average victim age
   - Yearly homicide counts
   - Monthly distribution patterns

2. **Trends**
   - Cumulative homicides by year (day-by-day comparison)
   - Monthly trends across all years
   - Year-over-year comparisons

3. **Demographics**
   - Age distribution histogram
   - Age groups by year (stacked bar chart)
   - Statistical summary table (min, mean, median, max age by year)

4. **Locations**
   - Top 20 locations with most homicides
   - Interactive horizontal bar chart

5. **Data Table**
   - Complete searchable and filterable dataset
   - Columns: Year, Name, Age, Date, Location
   - Export capabilities

6. **About**
   - Data sources
   - Project information
   - Feature descriptions

## Data Sources

The dashboard scrapes homicide data from the following URLs:
- **2021**: http://chamspage.blogspot.com/2021/
- **2022**: http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html
- **2023**: http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html
- **2024**: http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html
- **2025**: http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html

## Technologies Used

### R Packages
- **shiny**: Web application framework
- **shinydashboard**: Dashboard layout and components
- **rvest**: Web scraping
- **dplyr**: Data manipulation
- **ggplot2**: Data visualization
- **lubridate**: Date handling
- **DT**: Interactive data tables
- **plotly**: Interactive plots
- **tidyr**: Data tidying

## Installation & Usage

### Prerequisites
- Docker installed on your system

### Running the Dashboard

#### Option 1: Using the run script (Recommended)
```bash
chmod +x run.sh
./run.sh
```

#### Option 2: Manual Docker commands
```bash
# Build the image
docker build -t baltimore-homicides-dashboard .

# Run the container
docker run --rm -p 3838:3838 baltimore-homicides-dashboard
```

### Accessing the Dashboard
Once running, open your browser and navigate to:
```
http://localhost:3838
```

### Stopping the Dashboard
Press `Ctrl+C` in the terminal where the container is running.

## Project Structure
```
project7/
├── app.R              # Main R Shiny application
├── Dockerfile         # Docker configuration
├── run.sh            # Launch script
└── README.md         # This file
```

## Key Features & Implementation

### Data Scraping
- Automatically scrapes data from blog pages using `rvest`
- Parses homicide entries in the format: `#. Name, Age, Date, Location`
- Handles variations in data formatting across years
- Robust error handling for missing or malformed data

### Data Processing
- Extracts and parses dates using `lubridate`
- Converts age strings to numeric values
- Calculates day of year for cumulative analysis
- Creates age groups for demographic analysis

### Interactive Visualizations
- **Plotly integration**: All charts are interactive with hover tooltips
- **Responsive design**: Dashboard adapts to different screen sizes
- **Real-time filtering**: Data table supports search and column filters
- **Color-coded visuals**: Consistent color schemes across all visualizations

### Performance Optimization
- Data loaded reactively to minimize redundant processing
- Efficient data aggregation using `dplyr`
- Caching of processed data

## Data Accuracy Notes

The dashboard implements several measures to ensure data accuracy:

1. **Robust Parsing**: Handles variations in data formatting
2. **Error Handling**: Gracefully manages missing or malformed entries
3. **Data Validation**: Filters out empty or invalid records
4. **Age Extraction**: Uses regex patterns to extract numeric ages
5. **Date Parsing**: Flexible date parsing to handle multiple formats

## Development Notes

### Known Limitations
- Web scraping depends on consistent blog formatting
- Date parsing may fail for non-standard date formats
- Location data is unstructured and may contain variations

### Future Enhancements
- Geocoding for map visualizations
- Time-series forecasting
- Comparison with other crime statistics
- Export dashboard to PDF
- Mobile-optimized views

## Docker Configuration

The Dockerfile uses the official `rocker/shiny` base image which includes:
- R language runtime
- Shiny Server
- Common R packages

Additional packages installed:
- System libraries: libcurl, libssl, libxml2
- R packages: shinydashboard, rvest, dplyr, ggplot2, lubridate, DT, plotly, tidyr

## Troubleshooting

### Dashboard won't load
- Ensure Docker is running
- Check that port 3838 is not already in use
- Verify Docker image built successfully

### Data not displaying
- Check internet connection (required for web scraping)
- Verify blog URLs are accessible
- Review Docker logs: `docker logs <container_id>`

### Build errors
- Ensure Dockerfile and app.R are in the same directory
- Check Docker has sufficient resources allocated
- Try rebuilding with `--no-cache`: `docker build --no-cache -t baltimore-homicides-dashboard .`

## Academic Integrity

This project was completed as part of COSC 352 coursework. The data source (Cham's Baltimore Crime Blog) is publicly available and used for educational purposes.

## Author
[Your Name]  
COSC 352 - Fall 2025  
Project 7: R Shiny Dashboard

## License
Educational use only. Data sourced from public blog posts.
