#!/bin/bash

# Run.sh script for Baltimore Homicide Analysis Scala Project
# This script builds and runs the Docker container

set -e

# Configuration
IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-homicide-container"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "Baltimore Homicide Analysis - Scala Project"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed. Please install Docker first."
    exit 1
fi

echo "[1/3] Checking for existing Docker image..."

# Check if the image already exists
if docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo "      Image '$IMAGE_NAME' found. Skipping build."
else
    echo "      Image '$IMAGE_NAME' not found. Building now..."
    echo ""
    echo "[2/3] Building Docker image..."
    
    docker build -t "$IMAGE_NAME" "$PROJECT_DIR"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "      ✓ Docker image built successfully!"
    else
        echo ""
        echo "ERROR: Failed to build Docker image."
        exit 1
    fi
fi

echo ""
echo "[3/3] Running the Scala program in Docker container..."
echo ""
echo "=========================================="
echo ""

# Run the container
docker run --rm \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME"

# Check if the container ran successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Program executed successfully!"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "ERROR: Container execution failed."
    echo "=========================================="
    exit 1
fi