#!/bin/bash

# Script to run Baltimore Homicides R Shiny Dashboard
# Usage: ./run.sh

echo "Building Docker image for Baltimore Homicides Dashboard..."
docker build -t baltimore-homicides-dashboard .

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed"
    exit 1
fi

echo "Starting Baltimore Homicides Dashboard..."
echo "Dashboard will be available at: http://localhost:3838"
echo "Press Ctrl+C to stop the dashboard"

docker run --rm -p 3838:3838 baltimore-homicides-dashboard
