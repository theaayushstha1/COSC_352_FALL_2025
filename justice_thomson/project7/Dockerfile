# ==========================
# Project 7 — R Shiny + Docker
# ==========================
FROM rocker/shiny:4.4.1

# Install system dependencies
RUN apt-get update -y && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('rvest', 'stringr', 'dplyr', 'ggplot2', 'DT', 'shinydashboard'), repos='https://cran.rstudio.com/')"

# Copy app to image
COPY app.R /srv/shiny-server/app.R

# Expose port
EXPOSE 3838

# Run as shiny user
USER shiny