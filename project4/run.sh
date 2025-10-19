<<<<<<< HEAD
#!/bin/bash
set -e

IMAGE_NAME="homicide-scala:latest"

if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
  echo "[INFO] Docker image not found. Building..."
  docker build -t $IMAGE_NAME .
=======
#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="homicide-scala:latest"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

# Check if Docker image exists; if not, build it
if [[ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]]; then
  echo "[INFO] Docker image not found. Building $IMAGE_NAME ..."
  docker build -t "$IMAGE_NAME" .
>>>>>>> 932780b (Final submission: Project 4 (Baltimore City Homicide Analysis with Docker & Scala))
else
  echo "[INFO] Using existing image $IMAGE_NAME"
fi

<<<<<<< HEAD
echo "============================================================"
echo "Baltimore City Homicide Analysis: Insights for the Mayor's Office"
echo "============================================================"

docker run --rm $IMAGE_NAME
=======
# Run the container (no parameters, per assignment instructions)
docker run --rm -t "$IMAGE_NAME"


>>>>>>> 932780b (Final submission: Project 4 (Baltimore City Homicide Analysis with Docker & Scala))
