#!/bin/bash
set -e
IMAGE_NAME="baltimore-homicides-haskell"
echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .
echo ""
echo "Running analysis..."
docker run --rm "$IMAGE_NAME"
