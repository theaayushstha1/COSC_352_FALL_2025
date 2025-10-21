#!/usr/bin/env bash
set -euo pipefail

IMAGE="project4-baltimore:latest"
HERE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Docker image $IMAGE not found. Building..."
  docker build -t "$IMAGE" "$HERE_DIR"
else
  echo "Docker image $IMAGE found."
fi

echo "Running container..."
docker run --rm "$IMAGE"
