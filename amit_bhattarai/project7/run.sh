#!/usr/bin/env bash
set -e

IMAGE_NAME=project7_baltimore_shiny

echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Running Shiny Dashboard at http://localhost:3838 ..."
docker run --rm -p 3838:3838 "$IMAGE_NAME"
