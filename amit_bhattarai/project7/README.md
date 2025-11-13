Project 7 – Baltimore Homicide Dashboard (2021–2025)
This project uses R + RShiny to scrape, clean, and visualize Baltimore City homicide data from Cham’s Page for the years 2021–2025.
All five years are combined into a single dataset and displayed in an interactive dashboard.
Features
Automatic web scraping (2021–2025)
Data cleaning with dplyr, janitor, and lubridate
Interactive filters:
Year
Date range
Age range
Keyword search (address/block/notes)
Visualizations:
Homicides by year (bar chart)
Homicides by month (time series)
Searchable data table (DT)
Fully Dockerized using rocker/shiny
How to Run
Ensure Docker Desktop is running
Open the project directory
Run:
./run.sh
Open your browser at:
http://localhost:3838

