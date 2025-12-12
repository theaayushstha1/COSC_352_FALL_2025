FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shinydashboard', 'rvest', 'dplyr', 'ggplot2', 'lubridate', 'DT', 'plotly', 'tidyr'), repos='https://cran.rstudio.com/')"

# Copy the Shiny app
COPY app.R /srv/shiny-server/app.R

# Make sure the app is readable
RUN chmod -R 755 /srv/shiny-server/

# Expose port
EXPOSE 3838

# Run the app
CMD ["/usr/bin/shiny-server"]
