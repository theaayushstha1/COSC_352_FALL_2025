#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project4-scala"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 ; then
  echo "Building Docker image $IMAGE_NAME..."
  docker build -t "$IMAGE_NAME" .
fi

echo "Running analysis..."
docker run --rm "$IMAGE_NAME"
