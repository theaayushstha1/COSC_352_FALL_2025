FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('shinydashboard', 'ggplot2', 'dplyr', 'tidyr', 'lubridate', 'plotly', 'DT', 'leaflet'), repos='https://cloud.r-project.org/')"

# Remove default sample apps
RUN rm -rf /srv/shiny-server/*

# Create app directory
RUN mkdir -p /srv/shiny-server/baltimore-homicides

# Set working directory
WORKDIR /srv/shiny-server/baltimore-homicides

# Copy Python requirements and install
COPY requirements.txt /srv/shiny-server/baltimore-homicides/
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

# Copy the Python scraper script
COPY scrape_data.py /srv/shiny-server/baltimore-homicides/

# Run the scraper to get data
RUN python3 /srv/shiny-server/baltimore-homicides/scrape_data.py

# Copy the Shiny app
COPY app.R /srv/shiny-server/baltimore-homicides/

# Make sure the app is readable
RUN chmod -R 755 /srv/shiny-server/baltimore-homicides

# Expose port 3838
EXPOSE 3838

# Run the Shiny server
CMD ["/usr/bin/shiny-server"]