#!/bin/bash
set -e

IMAGE_NAME="homicide-scala:latest"

if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
  echo "[INFO] Docker image not found. Building..."
  docker build -t $IMAGE_NAME .
else
  echo "[INFO] Using existing image $IMAGE_NAME"
fi

echo "============================================================"
echo "Baltimore City Homicide Analysis: Insights for the Mayor's Office"
echo "============================================================"

docker run --rm $IMAGE_NAME
