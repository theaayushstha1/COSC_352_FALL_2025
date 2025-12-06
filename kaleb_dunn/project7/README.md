# Project 7: Baltimore Homicide Dashboard (R Shiny)

## Overview
An interactive R Shiny web dashboard that visualizes Baltimore City homicide data from 2021 to 2025. This dashboard provides comprehensive analysis with filtering capabilities, interactive charts, and multiple analytical perspectives on the data.

## Features

### Interactive Dashboard Tabs
1. **Overview** - High-level summary with key metrics and trends
2. **Trends** - Temporal patterns (yearly, monthly, daily, seasonal)
3. **District Analysis** - Geographic distribution and district performance
4. **Demographics** - Victim age analysis and breakdowns
5. **Case Closure** - Investigation success rates and trends
6. **Camera Analysis** - Police surveillance camera effectiveness
7. **Data Table** - Searchable and sortable raw data
8. **About** - Project information

### Dynamic Filters
- **Year Filter**: Select specific years (2021-2025)
- **District Filter**: Focus on individual police districts
- All visualizations update in real-time based on filter selections

### Visualizations
- Interactive Plotly charts (hover, zoom, pan)
- Bar charts (vertical and horizontal)
- Line charts with multiple series
- Pie charts
- Histograms
- Summary value boxes
- Data tables with search and export

## How to Run

### Prerequisites
- Docker installed and running
- Bash shell (Mac/Linux) or Git Bash (Windows)

### Quick Start
```bash
# Navigate to project directory
cd project7

# Make run script executable (first time only)
chmod +x run.sh

# Build and run the dashboard
./run.sh
```

**Note:** First build takes 5-10 minutes to download R packages. Be patient!

### Access the Dashboard

Once you see:
```
✓ Dashboard is running!
Access the dashboard at: http://localhost:3838/baltimore-homicide/
```

Open your browser and go to: **http://localhost:3838/baltimore-homicide/**

### Stopping the Dashboard
```bash
docker stop baltimore-dashboard
```

### Restarting the Dashboard
```bash
docker start baltimore-dashboard
```

### Viewing Logs
```bash
docker logs -f baltimore-dashboard
```

