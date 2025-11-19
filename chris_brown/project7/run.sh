#!/bin/bash

# Baltimore Homicide Dashboard Runner
# R Shiny Application

IMAGE_NAME="baltimore-homicide-dashboard"
CONTAINER_NAME="baltimore-dashboard"
PORT=3838

echo "========================================"
echo "Baltimore Homicide Dashboard (R Shiny)"
echo "========================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running. Please start Docker."
    exit 1
fi

# Check if image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Docker image not found. Building image..."
    echo "This may take several minutes on first run..."
    echo ""
    
    # Build the Docker image
    docker build -t $IMAGE_NAME .
    
    if [ $? -ne 0 ]; then
        echo ""
        echo "ERROR: Failed to build Docker image"
        exit 1
    fi
    
    echo ""
    echo "Image built successfully!"
    echo ""
else
    echo "Docker image found. Using existing image."
    echo ""
fi

# Stop and remove any existing container
echo "Stopping any existing container..."
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# Run the container
echo "Starting Shiny Server..."
echo ""

docker run -d \
    --name $CONTAINER_NAME \
    -p $PORT:3838 \
    $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo "========================================"
    echo "Dashboard started successfully!"
    echo "========================================"
    echo ""
    echo "Access the dashboard at:"
    echo "  http://localhost:$PORT"
    echo ""
    echo "To stop the dashboard, run:"
    echo "  docker stop $CONTAINER_NAME"
    echo ""
    echo "To view logs, run:"
    echo "  docker logs $CONTAINER_NAME"
    echo ""
else
    echo ""
    echo "ERROR: Failed to start container"
    exit 1
fi
