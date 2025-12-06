#!/bin/bash
# Installation script for R and required packages

echo "Installing R and dependencies..."

# Update package list
sudo apt-get update

# Install R
sudo apt-get install -y r-base r-base-dev

# Install required system libraries for R packages
sudo apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libcairo2-dev \
    libxt-dev

# Install R packages
echo "Installing R packages..."
Rscript -e "install.packages(c('shiny', 'dplyr', 'ggplot2', 'lubridate', 'DT', 'plotly', 'tidyr', 'rvest', 'xml2', 'stringr', 'bslib'), repos='https://cran.rstudio.com/')"

echo "Installation complete!"
echo "You can now run: bash fetch_data.sh"
