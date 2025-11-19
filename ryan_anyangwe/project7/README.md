# Baltimore City Homicides Dashboard

R Shiny dashboard visualizing Baltimore City homicide data from 2021-2025.

## Quick Start

### With Docker:
```bash
docker build -t baltimore-dashboard .
docker run -p 3838:3838 baltimore-dashboard
```

Access at: http://localhost:3838/baltimore-homicides

## Data Source
http://chamspage.blogspot.com/

## Features
- Interactive visualizations
- Geographic mapping
- Demographic analysis
- Year-over-year trends
- Filterable data

## Technology
- R + Shiny
- Docker
- plotly, leaflet, DT
