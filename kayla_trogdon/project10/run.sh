#!/bin/bash

echo "=================================================="
echo "Turing Machine Simulator - Docker Setup"
echo "=================================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed!"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "Building Docker image..."
docker build -t turing-machine-simulator .

if [ $? -ne 0 ]; then
    echo "❌ Docker build failed!"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""
echo "Starting Turing Machine Simulator..."
echo "Visit: http://localhost:5000"
echo ""
echo "Press Ctrl+C to stop"
echo "=================================================="
echo ""

docker run -p 5000:5000 --name tm-simulator turing-machine-simulator

# Cleanup on exit
docker rm tm-simulator