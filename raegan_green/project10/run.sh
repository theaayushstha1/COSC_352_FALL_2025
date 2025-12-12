#!/bin/bash

# Project 10 - Turing Machine Simulator Runner
# Builds and runs the Dockerized Turing Machine simulator

IMAGE_NAME="turing-machine-simulator"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Build Docker image if it doesn't exist
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Building Docker image..."
    docker build -t $IMAGE_NAME .
    if [ $? -ne 0 ]; then
        echo "Error: Docker build failed"
        exit 1
    fi
    echo "Build complete!"
fi

# Run the container
echo "Running Turing Machine Simulator..."
echo ""

if [ $# -eq 0 ]; then
    # Interactive mode
    docker run -it --rm $IMAGE_NAME
else
    # Command-line mode
    docker run -it --rm $IMAGE_NAME "$@"
fi