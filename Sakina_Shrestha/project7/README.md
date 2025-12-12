
# Baltimore City Homicide Dashboard (2021–2025)

Interactive R + RShiny dashboard visualizing Baltimore City homicide data from 2021–2025.

## Features

- Auto-scrapes data from all 5 years
- Interactive filters (year, date, age, keyword search)
- Visualizations: yearly trends, monthly patterns, cause analysis, camera impact
- Searchable data table
- Fully Dockerized

## Quick Start

```
chmod +x run.sh
./run.sh
```

Open browser: `http://localhost:3838`

## Requirements

- Docker Desktop

## Project Structure

```
project7/
├── app.R          # Main app
├── Dockerfile     # Docker config
├── run.sh         # Run script
└── README.md
```

