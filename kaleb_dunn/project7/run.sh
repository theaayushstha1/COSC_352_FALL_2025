#!/bin/bash

# Baltimore Homicide Dashboard Runner Script
# Builds and runs the R Shiny dashboard in Docker

IMAGE_NAME="project7"
CONTAINER_NAME="baltimore-dashboard"

# Check if container is already running
if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
    echo "Container '$CONTAINER_NAME' is already running."
    echo "Access the dashboard at: http://localhost:3838/baltimore-homicide/"
    exit 0
fi

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

# Stop and remove old container if it exists
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "Removing old container..."
    docker rm -f $CONTAINER_NAME
fi

# Run the container
echo "Starting Baltimore Homicide Dashboard..."
docker run -d \
  --name $CONTAINER_NAME \
  -p 3838:3838 \
  $IMAGE_NAME

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Dashboard is running!"
  echo ""
  echo "Access the dashboard at: http://localhost:3838/baltimore-homicide/"
  echo ""
  echo "To stop the dashboard, run: docker stop $CONTAINER_NAME"
  echo "To view logs, run: docker logs -f $CONTAINER_NAME"
else
  echo "Error: Failed to start container"
  exit 1
fi