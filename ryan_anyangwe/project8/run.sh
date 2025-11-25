#!/bin/bash

# Project 8: Functional Programming - Baltimore Homicide Analysis
# Language: Clojure

IMAGE_NAME="baltimore-homicide-functional"
CONTAINER_NAME="baltimore-functional-run"

echo "=================================================="
echo "Baltimore Homicide Analysis - Functional Programming"
echo "Language: Clojure"
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

# Check if CSV file exists
if [ ! -f "baltimore_homicides_combined.csv" ]; then
    echo "Downloading baltimore_homicides_combined.csv..."
    curl -L -o baltimore_homicides_combined.csv \
        "https://raw.githubusercontent.com/professor-jon-white/COSC_352_FALL_2025/main/professor_jon_white/func_prog/baltimore_homicides_combined.csv"
    
    if [ $? -eq 0 ]; then
        echo "✓ CSV file downloaded successfully"
    else
        echo "ERROR: Failed to download CSV file"
        echo "Please download manually from:"
        echo "https://github.com/professor-jon-white/COSC_352_FALL_2025/blob/main/professor_jon_white/func_prog/baltimore_homicides_combined.csv"
        exit 1
    fi
fi

echo ""
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
echo "Running Functional Programming Analysis..."
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