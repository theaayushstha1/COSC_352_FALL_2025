Project 7: Baltimore Homicide Dashboard (R Shiny)
Interactive dashboard analyzing Baltimore City homicides from 2021-2025.
Features
Dashboard Tabs

Overview - Key metrics and yearly trends
Trends - Time series and seasonal patterns
Geographic - District analysis and comparisons
Demographics - Age, race, and cause breakdowns
Data Table - Filterable raw data view

Visualizations

Yearly homicide totals with bar charts
Monthly trends comparing years
District rankings and comparisons
Time series analysis
Seasonal and day-of-week patterns
Age distribution histograms
Race and cause pie charts
Interactive filters by year and district

Usage
bash# Build and run
chmod +x run.sh
./run.sh

# Access dashboard
open http://localhost:3838/baltimore-homicides/

# Stop app
docker stop shiny-app

# View logs
docker logs shiny-app
Data Sources
The dashboard processes data from:

http://chamspage.blogspot.com/2021/
http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html
http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html
http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html
http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html

Note: Current implementation uses generated sample data. For production, implement web scraping in the generate_sample_data() function.
R Packages Used

shiny - Web application framework
shinydashboard - Dashboard layout
ggplot2 - Data visualization
dplyr - Data manipulation
lubridate - Date handling
DT - Interactive tables
plotly - Interactive charts


Technical Details

Framework: R Shiny
Docker Base: rocker/shiny
Port: 3838
Dashboard Theme: AdminLTE (red skin)

Key Metrics
Dashboard displays:

Total homicides (filtered)
Year-to-date count
Year-over-year change percentage
Top 5 districts by homicides
Monthly and seasonal trends
Demographic breakdowns