#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project4-scala"
IMAGE_TAG="latest"

cd "$(dirname "$0")"

have_image() {
  docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" >/dev/null 2>&1
}

if ! have_image; then
  echo "[INFO] Docker image not found. Building ${IMAGE_NAME}:${IMAGE_TAG} ..."
  docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
else
  echo "[INFO] Using existing image ${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "[INFO] Running Scala program in Docker..."
docker run --rm "${IMAGE_NAME}:${IMAGE_TAG}"
