#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="homicide-scala:latest"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

# Check if Docker image exists; if not, build it
if [[ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]]; then
  echo "[INFO] Docker image not found. Building $IMAGE_NAME ..."
  docker build -t "$IMAGE_NAME" .
else
  echo "[INFO] Using existing image $IMAGE_NAME"
fi

# Run the container (no parameters, per assignment instructions)
docker run --rm -t "$IMAGE_NAME"


