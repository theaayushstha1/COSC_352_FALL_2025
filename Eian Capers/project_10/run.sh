#!/bin/bash

# Turing Machine Simulator - Quick Start Script
# This script builds and runs the Docker container

set -e  # Exit on error

echo "=========================================="
echo "Turing Machine Simulator - Setup"
echo "=========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✓ Docker is installed"
echo ""

# Build the Docker image
echo "Building Docker image..."
echo "This may take a few minutes on first run..."
docker build -t turing-machine .

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Docker image built successfully"
    echo ""
else
    echo ""
    echo "❌ Docker build failed"
    exit 1
fi

# Stop any existing container
echo "Checking for existing containers..."
if [ "$(docker ps -q -f name=turing-machine-app)" ]; then
    echo "Stopping existing container..."
    docker stop turing-machine-app
    docker rm turing-machine-app
fi

# Run the container
echo ""
echo "Starting Turing Machine Simulator..."
docker run -d \
    --name turing-machine-app \
    -p 5000:5000 \
    turing-machine

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "✓ Application started successfully!"
    echo "=========================================="
    echo ""
    echo "Access the application at:"
    echo "  → http://localhost:5000"
    echo ""
    echo "Useful commands:"
    echo "  View logs:    docker logs -f turing-machine-app"
    echo "  Stop app:     docker stop turing-machine-app"
    echo "  Restart app:  docker restart turing-machine-app"
    echo "  Remove app:   docker rm -f turing-machine-app"
    echo ""
    echo "Press Ctrl+C to stop following logs"
    echo "=========================================="
    echo ""
    
    # Follow logs
    docker logs -f turing-machine-app
else
    echo ""
    echo "❌ Failed to start container"
    exit 1
fi