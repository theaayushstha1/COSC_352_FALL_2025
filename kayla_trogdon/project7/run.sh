#!/bin/bash

echo "========================================"
echo "Project 7: Baltimore Homicide Dashboard"
echo "========================================"

IMAGE_NAME="baltimore_homicide_dashboard"
CSV_FILE="baltimore_homicides_2021_2025.csv"

# Fetching the CSV file
if [ ! -f "$CSV_FILE" ]; then
    echo "Fetching homicide data (2021-2025)..." 
    python3 fetch_csv.py
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Error: CSV file was NOT created!"
    exit 1
fi

echo "✅ Data file found!"

# Always rebuild Docker image with NO CACHE
echo "Building Docker image (fresh build, no cache)..."
docker rmi "$IMAGE_NAME" 2>/dev/null || true
docker build --no-cache -t "$IMAGE_NAME" .

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

# Running RShiny dashboard
echo ""
echo "Starting RShiny dashboard..." 
echo "========================================"
echo "🌐 Dashboard URL: http://localhost:3838"
echo "use CTRL+C to stop the dashboard" 
echo "========================================"
echo ""

docker run --rm -p 3838:3838 "$IMAGE_NAME"