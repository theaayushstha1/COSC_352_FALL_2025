FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shinydashboard', 'ggplot2', 'dplyr', 'lubridate', 'DT', 'plotly'), repos='https://cran.rstudio.com/', Ncpus=4)"

# Remove default shiny apps
RUN rm -rf /srv/shiny-server/*

# Copy our app
RUN mkdir -p /srv/shiny-server/baltimore-homicides
COPY app.R /srv/shiny-server/baltimore-homicides/app.R

# Set permissions
RUN chmod -R 755 /srv/shiny-server/

# Expose port
EXPOSE 3838

# Run shiny server
CMD ["/usr/bin/shiny-server"]