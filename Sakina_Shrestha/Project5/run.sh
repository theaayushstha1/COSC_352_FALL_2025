#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="baltimore"

# Build if image not present
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image not found. Building image..."
  docker build -t "$IMAGE_NAME" .
fi

echo "Running container..."

# Always mount current directory as /output for file generation
docker run --rm -v "$(pwd):/output" "$IMAGE_NAME" scala -classpath /app Baltimore "$@"
