# Dockerfile for Baltimore Homicide Dashboard

FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libxt-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'dplyr', 'ggplot2', 'lubridate', 'DT', 'plotly', 'tidyr', 'rvest', 'xml2', 'stringr', 'bslib'), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicides
WORKDIR /srv/shiny-server/baltimore-homicides

# Copy application files
COPY app.R .
COPY data_processing.R .
COPY fetch_data.sh .
COPY data/ ./data/

# Make scripts executable
RUN chmod +x fetch_data.sh

# Expose port
EXPOSE 3838

# Run the app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/baltimore-homicides/app.R', host='0.0.0.0', port=3838)"]
