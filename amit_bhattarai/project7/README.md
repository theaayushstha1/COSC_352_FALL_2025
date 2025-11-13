
# Project 7 – Baltimore Homicide Dashboard (2021–2025)

This project uses **R + RShiny** to scrape, clean, and visualize Baltimore City homicide data from **Cham’s Page** for the years **2021–2025**.  
All five years are combined into one dataset and displayed through an interactive dashboard.

---

## ⭐ Features
- Automatic web scraping (2021–2025)
- Data cleaning with **dplyr**, **janitor**, **lubridate**
- Interactive filters:
  - Year selector
  - Date range filter
  - Age range slider
  - Keyword search (address/block/notes)
- Visualizations:
  - Homicides by year (bar chart)
  - Homicides by month (time series)
- Searchable, sortable data table (DT)
- Fully Dockerized using **rocker/shiny**

---

## 🚀 How to Run

1. Start **Docker Desktop**  
2. Navigate to this folder  
3. Run:

   ```bash
   ./run.sh

Open your browser at:
http://localhost:3838

