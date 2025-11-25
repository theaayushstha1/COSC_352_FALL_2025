#!/bin/bash

IMAGE_NAME="baltimore-homicide-scala"

echo "Checking for Docker image..."

if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "Image not found. Building Docker image..."
  docker build -t $IMAGE_NAME .
else
  echo "Docker image already exists."
fi

echo "Running Docker container..."
docker run --rm $IMAGE_NAME
echo "Done."