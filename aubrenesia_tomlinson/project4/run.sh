#!/bin/bash

# Check for image 
IMAGE_NAME="bmore-homicide-stats"
docker images | grep $IMAGE_NAME > /dev/null

# Build image
if [ $? -ne 0 ]; then
  echo "Building image."
  docker build -t $IMAGE_NAME .
fi

# Run container
echo "Running program."
docker run --rm $IMAGE_NAME
