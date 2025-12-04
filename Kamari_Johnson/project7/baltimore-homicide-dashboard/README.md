# Baltimore Homicide Dashboard

This project is an interactive R Shiny dashboard that visualizes homicide data in Baltimore from 2021 to 2025. The data is scraped from ChamsPage and includes yearly trends, a map of incidents, and a searchable data table. The application is fully containerized using Docker for reproducibility and portability.

## Features

- Overview tab: Bar chart showing homicides per year
- Map tab: Interactive leaflet map with randomized coordinates
- Table tab: Searchable and sortable data table
- Loading spinners for visual feedback
- Data caching to avoid repeated scraping

