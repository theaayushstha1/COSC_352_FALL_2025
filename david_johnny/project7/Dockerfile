
FROM rocker/shiny:4.3.2

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shiny', 'tidyverse', 'rvest', 'lubridate', 'DT', 'plotly'), repos='https://cran.rstudio.com/')"

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicides

# Copy app files
COPY app.R /srv/shiny-server/baltimore-homicides/

# Set permissions
RUN chown -R shiny:shiny /srv/shiny-server/baltimore-homicides

# Expose port
EXPOSE 3838

# Run app
CMD ["/usr/bin/shiny-server"]