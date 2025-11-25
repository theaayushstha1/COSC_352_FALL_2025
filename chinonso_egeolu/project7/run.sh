#!/bin/bash
# Docker image name
IMAGE_NAME="baltimore-homicide-shiny"
CONTAINER_NAME="shiny-app"

# Check if image exists, build if not
if ! docker images | grep -q "$IMAGE_NAME"; then
  echo "Building Docker image..."
  docker build -t "$IMAGE_NAME" .
  if [ $? -ne 0 ]; then
    echo "Failed to build Docker image."
    exit 1
  fi
fi

# Stop and remove existing container if running
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# Run the container
echo "Starting Shiny app..."
docker run -d --name $CONTAINER_NAME -p 3838:3838 "$IMAGE_NAME"

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Shiny app is running!"
  echo ""
  echo "Access the dashboard at: http://localhost:3838/baltimore-homicides/"
  echo ""
  echo "To stop the app: docker stop $CONTAINER_NAME"
  echo "To view logs: docker logs $CONTAINER_NAME"
else
  echo "Failed to start container."
  exit 1
fi