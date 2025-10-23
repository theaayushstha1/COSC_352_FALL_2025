#!/bin/bash

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-container"

# Check if the Docker image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Docker image not found. Building image..."
    docker build -t $IMAGE_NAME .
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image"
        exit 1
    fi
    echo "Image built successfully!"
else
    echo "Docker image found. Using existing image..."
fi

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME 2>/dev/null

# Run the container
echo "Running analysis..."
echo ""
docker run --name $CONTAINER_NAME $IMAGE_NAME

# Clean up the container after execution
docker rm $CONTAINER_NAME > /dev/null 2>&1