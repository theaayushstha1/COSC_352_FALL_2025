FROM --platform=linux/amd64 rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'rvest', 'dplyr', 'lubridate', 'janitor', 'ggplot2', 'DT', 'stringr', 'httr'), repos='http://cran.rstudio.com/')"

# Copy app
RUN rm -rf /srv/shiny-server/*
COPY app.R /srv/shiny-server/

# Expose port
EXPOSE 3838

# Run
CMD ["/usr/bin/shiny-server"]
