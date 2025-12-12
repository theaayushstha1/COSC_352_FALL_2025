# Use Rocker Verse image (R + tidyverse + common packages preinstalled)
FROM rocker/verse:latest

# System dependencies for leaflet, sf, tidygeocoder
RUN apt-get update && apt-get install -y \
    libgeos-dev \
    libgdal-dev \
    libproj-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    && rm -rf /var/lib/apt/lists/*

# Install additional R packages not included in rocker/verse
RUN R -e "install.packages(c('leaflet','plotly','tidygeocoder','DT','stringr','lubridate','rvest','sf'), repos='https://cloud.r-project.org', dependencies=TRUE)"

# Create app directory
RUN mkdir -p /srv/shiny-server/app
WORKDIR /srv/shiny-server/app

# Copy app code
COPY app.R /srv/shiny-server/app/

# Expose Shiny port
EXPOSE 3838

# Run Shiny app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app', host='0.0.0.0', port=3838)"]
