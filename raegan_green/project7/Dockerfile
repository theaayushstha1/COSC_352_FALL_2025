FROM rocker/shiny:4.3.1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'shinydashboard', 'ggplot2', 'dplyr', 'lubridate', 'httr', 'xml2', 'stringr', 'plotly', 'DT'), repos='https://cran.rstudio.com/')"

# Copy app files
WORKDIR /srv/shiny-server
COPY app.R /srv/shiny-server/

# Expose port
EXPOSE 3838

# Run app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]
