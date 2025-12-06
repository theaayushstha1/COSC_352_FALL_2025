# Use rocker/shiny as base image
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'ggplot2', 'dplyr', 'tidyr', 'lubridate', 'plotly', 'DT', 'rvest', 'stringr', 'leaflet', 'scales'), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicide

# Copy app files
COPY app.R /srv/shiny-server/baltimore-homicide/

# Set working directory
WORKDIR /srv/shiny-server/baltimore-homicide

# Expose port 3838
EXPOSE 3838

# Run app
CMD ["/usr/bin/shiny-server"]