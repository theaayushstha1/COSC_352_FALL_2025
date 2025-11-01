#!/bin/bash

# Baltimore Homicide Analysis Runner Script
# This script builds the Docker image if needed and runs the Scala analysis

IMAGE_NAME="project4"

# Check if Docker image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "Docker image '$IMAGE_NAME' not found. Building..."
  docker build -t $IMAGE_NAME .
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build Docker image"
    exit 1
  fi
  
  echo "Build complete!"
  echo ""
fi

# Run the container
echo "Running Baltimore Homicide Analysis..."
echo ""
docker run --rm $IMAGE_NAME
