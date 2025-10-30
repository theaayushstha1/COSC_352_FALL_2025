#!/bin/bash

# Project 4: Baltimore Homicide Analysis
# This script builds and runs the Scala application in a Docker container

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-run"

echo "=================================================="
echo "Baltimore City Homicide Analysis - Project 4"
echo "=================================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "Checking for existing Docker image..."

# Check if image exists
if docker image inspect $IMAGE_NAME &> /dev/null; then
    echo "✓ Docker image '$IMAGE_NAME' found"
else
    echo "✗ Docker image '$IMAGE_NAME' not found"
    echo ""
    echo "Building Docker image (this may take a few minutes)..."
    
    # Build the Docker image
    if docker build -t $IMAGE_NAME .; then
        echo "✓ Docker image built successfully"
    else
        echo "ERROR: Failed to build Docker image"
        exit 1
    fi
fi

echo ""
echo "Running Baltimore Homicide Analysis..."
echo ""
echo "=================================================="
echo ""

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME &> /dev/null

# Run the container
docker run --rm --name $CONTAINER_NAME $IMAGE_NAME

echo ""
echo "=================================================="
echo "Analysis complete!"
echo "=================================================="
