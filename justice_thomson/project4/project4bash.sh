#!/bin/bash

IMAGE_NAME="project4-image"

if ! docker images | grep -q "$IMAGE_NAME"; then
  docker build -t "$IMAGE_NAME" .
fi

docker run --rm "$IMAGE_NAME"
