FROM rocker/shiny:latest

# system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# R packages
RUN R -e "install.packages(c('shiny', 'ggplot2', 'dplyr', 'DT', 'lubridate'), repos='http://cran.rstudio.com/')"

# app directory
RUN mkdir -p /srv/shiny-server/data

# Copy 
COPY app.R /srv/shiny-server/

# Set directory
WORKDIR /srv/shiny-server

# Expose port
EXPOSE 3838

# Run the app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]