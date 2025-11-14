Project 7 — Baltimore Homicide Dashboard (R + Shiny)

Overview
- This project fetches Baltimore City homicide lists (2021–2025), combines them into a CSV, and provides an R Shiny dashboard to explore the data.

Files
- `data-fetch.R`: Script to download and parse the homicide lists and write `data/homicides.csv`.
- `app.R`: Shiny application.
- `Dockerfile`: Docker image based on `rocker/shiny` that installs dependencies and builds the app.
- `.gitignore`: Ignore R artifacts.

Quick local run
1. Install R (>=4.0) and required packages.
2. From the `project7` folder run:
```bash
Rscript data-fetch.R
R -e "shiny::runApp('.')"
```

Build & run with Docker
```bash
docker build -t christian_project7 .
docker run -p 3838:3838 christian_project7
# Then open http://localhost:3838 in your browser
```

Notes
- The data parser is best-effort; inspect `data/homicides.csv` for accuracy.
- You should commit the project into git and push to your remote for grading.
