#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="baltimore"

# Build if image not present
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image not found. Building image..."
  docker build -t "$IMAGE_NAME" .
fi

echo "Running container..."
docker run --rm "$IMAGE_NAME"
