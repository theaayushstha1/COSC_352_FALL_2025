# Use official Shiny image
FROM rocker/shiny:latest

# Install required packages
RUN R -e "install.packages(c('shiny','DT','leaflet','dplyr','lubridate','rvest','stringr'), repos='https://cloud.r-project.org')"

# Copy app files
COPY app.R /srv/shiny-server/
COPY data_loader.R /srv/shiny-server/

# Expose Shiny port
EXPOSE 3838

# Start Shiny server
CMD ["/usr/bin/shiny-server"]
