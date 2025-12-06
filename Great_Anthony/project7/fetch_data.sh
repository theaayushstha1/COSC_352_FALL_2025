#!/bin/bash
# Script to fetch Baltimore homicide data from all years

echo "Fetching Baltimore City Homicide data..."

# Create data directory if it doesn't exist
mkdir -p data/raw

# Download data for each year
echo "Downloading 2021 data..."
curl -o data/raw/2021.html "http://chamspage.blogspot.com/2021/"

echo "Downloading 2022 data..."
curl -o data/raw/2022.html "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html"

echo "Downloading 2023 data..."
curl -o data/raw/2023.html "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html"

echo "Downloading 2024 data..."
curl -o data/raw/2024.html "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"

echo "Downloading 2025 data..."
curl -o data/raw/2025.html "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"

echo "Data download complete!"
echo "Files saved in data/raw/"

# Process the data
echo "Processing data..."
Rscript data_processing.R

echo "All done! You can now run the Shiny app with: Rscript run_app.R"
