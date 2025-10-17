#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project4-scala-homicides"
CONTAINER_NAME="project4-scala-run"

if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "Docker image $IMAGE_NAME not found — building..."
  docker build -t $IMAGE_NAME .
else
  echo "Docker image $IMAGE_NAME already exists."
fi

# run container
docker run --rm --name $CONTAINER_NAME $IMAGE_NAME
