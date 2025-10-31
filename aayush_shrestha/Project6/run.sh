#!/bin/bash

# Project 6 - Baltimore Homicide Analysis in Golang
# Author: Aayush Shrestha
# Course: COSC_352_FALL_2025

set -e

IMAGE_NAME="baltimore-homicide-golang"
CONTAINER_NAME="baltimore-golang-container"

echo "========================================="
echo "Baltimore Homicide Analysis - Project 6"
echo "Golang Implementation"
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

# Build image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .
echo "Image built successfully!"
echo ""

# Remove existing container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "Removing existing container..."
  docker rm -f $CONTAINER_NAME > /dev/null 2>&1
fi

# Run the container
echo "Running analysis..."
echo ""

if [ -n "$OUTPUT_FORMAT" ]; then
  docker run --name $CONTAINER_NAME -v "$(pwd):/output" $IMAGE_NAME $OUTPUT_FORMAT
else
  docker run --name $CONTAINER_NAME $IMAGE_NAME
fi

# Clean up container
docker rm $CONTAINER_NAME > /dev/null 2>&1

echo ""
if [ "$OUTPUT_FORMAT" = "csv" ]; then
  echo "Analysis complete! Output saved to baltimore_homicide_analysis.csv"
elif [ "$OUTPUT_FORMAT" = "json" ]; then
  echo "Analysis complete! Output saved to baltimore_homicide_analysis.json"
else
  echo "Analysis complete!"
fi
