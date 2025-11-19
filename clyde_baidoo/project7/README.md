**Option 1 (running with docker) - takes longer time since it installs number of dependencies and package compilation.**
- cd project7
- chmod +x run.sh
- ./run.sh   (contains all information to build and run docker image)
- view dashboard on https://localhost:3838 

**option 2 (without docker)**
- activate R terminal by typing ---> R
- install.packages(c('shiny','rvest','lubridate','DT','leaflet','plotly','tidygeocoder','sf','stringr','ggplot2'))
- verify package installation by ---> library(shiny, rvest, lubridate, DT, leaflet, plotly, tidygeocoder, sf, stringr, ggplot2)
- running dashboard ---> shiny::runApp("app.R")

**on the dashboard;**
- geocoding caching is recommended to avoid repeated API calls.
- The app automatically caches HTML pages in data/raw to avoid re-downloading every time.
- navigate to table to view all scraped data from 2021.


