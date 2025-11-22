#!/bin/bash

echo "=========================================="
echo "Project 8: Baltimore Homicides Functional Analysis"
echo "Clojure CLI Tools Implementation"
echo "=========================================="

CSV_FILE="baltimore_homicides_combined.csv"

# Check if CSV exists
if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Error: $CSV_FILE not found!"
    echo ""
    echo "Please copy the CSV file from project7:"
    echo "  cp ../project7/$CSV_FILE ."
    exit 1
fi

echo "✅ Data file found: $CSV_FILE"

# Check if we should use Docker or local Clojure
if command -v clojure &> /dev/null; then
    echo "Running with local Clojure CLI..."
    clojure -M -m core
else
    echo "Clojure CLI not found locally. Building Docker image..."
    docker build -t baltimore-homicides-clojure .
    
    if [ $? -ne 0 ]; then
        echo "❌ Docker build failed!"
        exit 1
    fi
    
    echo ""
    echo "Running analysis in Docker container..."
    docker run --rm baltimore-homicides-clojure
fi