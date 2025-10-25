#!/bin/bash

echo "======================================"
echo "  Baltimore Homicide Analysis"
echo "======================================"
echo ""

DOCKER_IMAGE="rohan_homicide_analysis"

# Check if Docker image exists
if ! docker images | grep -q "$DOCKER_IMAGE"; then
    echo "Docker image not found. Building..."
    docker build -t "$DOCKER_IMAGE" .
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image"
        exit 1
    fi
    echo "Docker image built successfully!"
    echo ""
fi

# Run the Docker container
echo "Running analysis..."
echo ""
docker run --rm "$DOCKER_IMAGE"
