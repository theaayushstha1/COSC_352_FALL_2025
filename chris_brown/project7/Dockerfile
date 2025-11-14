# Use rocker/shiny as base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    libgdal-dev \
    libudunits2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shinydashboard', 'ggplot2', 'dplyr', 'lubridate', 'plotly', 'DT', 'leaflet', 'tidyr'), repos='https://cran.rstudio.com/')"

# Copy application files
COPY app.R /srv/shiny-server/

# Make sure the application has proper permissions
RUN chmod -R 755 /srv/shiny-server/

# Expose port 3838
EXPOSE 3838

# Run the Shiny app
CMD ["/usr/bin/shiny-server"]
