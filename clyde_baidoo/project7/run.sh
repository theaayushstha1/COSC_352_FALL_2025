#!/bin/bash
# Build and run the Shiny app Docker container

IMAGE_NAME="baltimore-homicides"
PORT=3838

echo "🧹 Stopping and removing old container if exists..."
docker rm -f $IMAGE_NAME 2>/dev/null || true

echo "🔧 Building Docker image ($IMAGE_NAME)..."
docker build -t $IMAGE_NAME .

echo "🚀 Running Shiny app on http://localhost:$PORT ..."
docker run -d -p $PORT:3838 --name $IMAGE_NAME $IMAGE_NAME
