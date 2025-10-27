#!/bin/bash

# Project 5 - Baltimore Homicide Analysis with CSV/JSON Output
# Author: Aayush Shrestha
# Course: COSC_352_FALL_2025

set -e

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-container"

echo "========================================="
echo "Baltimore Homicide Analysis - Project 5"
echo "========================================="
echo ""

# Parse command line arguments
OUTPUT_FORMAT=""
if [ $# -gt 0 ]; then
    case "$1" in
        --output=csv)
            OUTPUT_FORMAT="csv"
            echo "Output format: CSV"
            ;;
        --output=json)
            OUTPUT_FORMAT="json"
            echo "Output format: JSON"
            ;;
        *)
            echo "Unknown argument: $1"
            echo "Usage: ./run.sh [--output=csv|--output=json]"
            exit 1
            ;;
    esac
else
    echo "Output format: STDOUT (default)"
fi
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if image exists, if not build it
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Docker image not found. Building image..."
    docker build -t $IMAGE_NAME .
    echo "Image built successfully!"
    echo ""
else
    echo "Docker image found. Using existing image."
    echo ""
fi

# Remove existing container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing existing container..."
    docker rm -f $CONTAINER_NAME > /dev/null 2>&1
fi

# Run the container with volume mount for output files
echo "Running analysis..."
echo ""

if [ -n "$OUTPUT_FORMAT" ]; then
    # Mount current directory to /output in container for file output
    docker run --name $CONTAINER_NAME -v "$(pwd):/output" $IMAGE_NAME $OUTPUT_FORMAT
else
    docker run --name $CONTAINER_NAME $IMAGE_NAME
fi

# Clean up container after execution
docker rm $CONTAINER_NAME > /dev/null 2>&1

echo ""
if [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo "Analysis complete! Output saved to baltimore_homicide_analysis.csv"
elif [ "$OUTPUT_FORMAT" = "json" ]; then
    echo "Analysis complete! Output saved to baltimore_homicide_analysis.json"
else
    echo "Analysis complete!"
fi
