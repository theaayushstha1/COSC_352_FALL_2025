FROM rocker/shiny:latest

# Install system dependencies for leaflet, rvest, and tidyverse packages
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libglpk-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libpq-dev \
    libsqlite3-dev \
    libmagick++-dev

# Install remotes to ensure robust package installation
RUN R -e "install.packages('remotes', repos='http://cran.rstudio.com/')"

# Install all required R packages with full dependencies
RUN R -e "remotes::install_cran(c( \
  'shiny', 'shinydashboard', 'leaflet', 'DT', 'ggplot2', \
  'dplyr', 'rvest', 'stringr', 'lubridate', 'tidyr', 'tibble', 'shinycssloaders' \
), dependencies = TRUE)"

# Copy app files
COPY . /srv/shiny-server/
EXPOSE 3838