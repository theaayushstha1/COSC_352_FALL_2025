#!/bin/bash

# Project 4 - Baltimore Homicide Analysis
# This script builds and runs the Scala program in a Docker container

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-run"

# Check if Docker image exists, if not build it
if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
    echo "Docker image not found. Building image..."
    docker build -t $IMAGE_NAME .
    
    if [ $? -ne 0 ]; then
        echo "Error: Docker build failed"
        exit 1
    fi
    echo "Image built successfully!"
else
    echo "Docker image found. Using existing image..."
fi

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME > /dev/null 2>&1

# Run the container
echo "Running Baltimore Homicide Analysis..."
echo ""
docker run --name $CONTAINER_NAME $IMAGE_NAME

# Check if the run was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "Analysis completed successfully!"
else
    echo ""
    echo "Error: Analysis failed"
    exit 1
fi

# Clean up the container
docker rm $CONTAINER_NAME > /dev/null 2>&1

