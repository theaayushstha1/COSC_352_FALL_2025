#!/bin/bash

# Project 4 - Baltimore Homicide Analysis
# Author: Aayush Shrestha
# Course: COSC_352_FALL_2025

set -e

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-container"

echo "========================================="
echo "Baltimore Homicide Analysis - Project 4"
echo "========================================="
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

# Run the container
echo "Running analysis..."
echo ""
docker run --name $CONTAINER_NAME $IMAGE_NAME

# Clean up container after execution
docker rm $CONTAINER_NAME > /dev/null 2>&1

echo ""
echo "Analysis complete!"
