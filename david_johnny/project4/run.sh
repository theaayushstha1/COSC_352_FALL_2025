#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project4-scala-homicide:latest"
DIRNAME=$(cd "$(dirname "$0")" && pwd)

# Check if Docker image exists; if not, build it
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image $IMAGE_NAME not found. Building..."
  docker build -t "$IMAGE_NAME" "$DIRNAME"
else
  echo "Docker image $IMAGE_NAME found. Skipping build."
fi

# Run the container (automatically executes scala Main)
echo "Running Scala program inside Docker..."
docker run --rm "$IMAGE_NAME"
