#!/bin/bash

echo "Setting up Project 6 (Go Homicide Analysis)..."

# Create data directory if it doesn't exist
mkdir -p data

# Check if we need to download the data
if [ ! -f "data/homicide-data.csv" ]; then
    echo "Downloading homicide data..."
    wget -O data/homicide-data.csv https://raw.githubusercontent.com/washingtonpost/data-homicides/master/homicide-data.csv 2>/dev/null || echo "Please add your data file manually to data/homicide-data.csv"
fi

# Initialize Go module if not exists
if [ ! -f "go.mod" ]; then
    echo "Initializing Go module..."
    go mod init homicide-analysis
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t homicide-analysis .

echo "Setup complete!"
echo ""
echo "To run the program:"
echo "  ./run.sh          # Output to stdout"
echo "  ./run.sh csv      # Output to CSV file"
echo "  ./run.sh json     # Output to JSON file"
