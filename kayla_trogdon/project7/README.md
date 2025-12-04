# Project 7: Baltimore Homicides RShiny Dashboard (2021-2025)

## Overview
This project creates an **interactive web dashboard** to visualize and analyze Baltimore City homicide statistics from 2021-2025. It fetches data from multiple years using Python with BeautifulSoup, then displays the data through an RShiny dashboard running in a Docker container with comprehensive visualizations, filters, and statistical insights.

## How to Run
1) Install Python dependencies:
```bash
pip3 install -r requirements.txt --break-system-packages
```

2) Make the script executable:
```bash
chmod +x run.sh
```

3) Run the project:
```bash
./run.sh
```

4) Access the dashboard:
   - Open browser to: **http://localhost:3838** (local machine)
   - Or use the forwarded port URL in **GitHub Codespaces** (PORTS tab → port 3838)

5) Stop the dashboard:
   - Press `CTRL+C` in the terminal

## Project Components

### fetch_csv.py → Python Script
Fetches and combines homicide data from multiple years (2021-2025)
- Scrapes 5 different URLs from https://chamspage.blogspot.com/
- Uses native `HTMLParser` with **BeautifulSoup fallback** for problematic pages
- Extracts all 9 columns plus adds a Year column (10 total)
- Combines data from all years into `baltimore_homicides_2021_2025.csv`
- Connected to `requirements.txt` file for the imported Python libraries used

### app.R → RShiny Dashboard Application
Creates the interactive web dashboard with 5 main tabs
- **Overview Tab**: Summary statistics and year/month breakdowns
  - Total homicides, unique locations, average age, case closure rate
  - Interactive bar charts for yearly and monthly trends
  - Top 10 most dangerous locations
  
- **Time Trends Tab**: Temporal analysis
  - Yearly trend line chart
  - Monthly distribution by year (multi-line chart)
  - Cumulative homicides over time
  
- **Locations Tab**: Geographic analysis
  - Top 20 most dangerous address blocks
  - Locations with multiple homicides
  - Case closure rates by location
  
- **Demographics Tab**: Victim statistics
  - Age distribution histogram
  - Age distribution by year (box plots)
  - Case closure status pie chart
  - Surveillance camera availability
  
- **Data Explorer Tab**: Searchable data table
  - Full dataset with filtering and searching
  - Sortable columns
  - Exportable data

**Interactive Features:**
- Year filter (All, 2021, 2022, 2023, 2024, 2025)
- Month filter (All, January through December)
- All charts update dynamically based on filters

### Dockerfile
Creates a containerized RShiny environment
- Uses `rocker/shiny:latest` as base image
- Installs system dependencies for R packages (`libssl-dev`, `libcurl4-openssl-dev`, `libxml2-dev`, `libfontconfig1-dev`, `libcairo2-dev`)
- Installs R packages: shiny, shinydashboard, dplyr, ggplot2, lubridate, DT, plotly
- Copies `app.R` and CSV data into container
- Exposes port 3838 for web access
- Runs the Shiny application

### run.sh → Orchestration Script
Automates the complete workflow
- Checks if `baltimore_homicides_2021_2025.csv` exists
  - If not, runs `fetch_csv.py` to generate it
- Verifies CSV was created successfully
- Rebuilds Docker image with `--no-cache` flag
- Runs the RShiny dashboard in Docker container
- Maps port 3838 for web access

### requirements.txt → Python Dependencies
Specifies required Python libraries for web scraping
- `requests>=2.31.0` - HTTP library for fetching web pages
- `beautifulsoup4>=4.12.0` - HTML parser for complex page structures

### .gitignore → Git Exclusions
Excludes generated and temporary files from version control
- Python cache files (`__pycache__/`, `*.pyc`)
- Virtual environments (`venv/`, `env/`)
- IDE files (`.vscode/`, `.idea/`)
- OS files (`.DS_Store`, `Thumbs.db`)
- R history and environment files (`.Rhistory`, `.RData`)
- **Note:** CSV files are **NOT** excluded so the dataset is included in the repository