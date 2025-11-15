# Use official Rocker Shiny image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shinydashboard', 'rvest', 'dplyr', 'tidyr', 'ggplot2', 'plotly', 'lubridate', 'DT', 'leaflet', 'jsonlite'), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicides

# Copy the Shiny app
COPY app.R /srv/shiny-server/baltimore-homicides/

# Make sure the app has correct permissions
RUN chown -R shiny:shiny /srv/shiny-server/baltimore-homicides

# Expose port 3838
EXPOSE 3838

# Run the Shiny Server
CMD ["/usr/bin/shiny-server"]