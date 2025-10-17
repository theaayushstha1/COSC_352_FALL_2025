#!/usr/bin/env bash
set -euo pipefail
IMAGE_NAME="project4:latest"

# Enable BuildKit for faster, cache-friendly builds
export DOCKER_BUILDKIT=1

# Always (re)build to ensure the latest code is in the image
echo "🛠️  Building Docker image ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" -f Dockerfile .

echo " Running container..."
# --rm to auto-remove, --network default so it can reach the internet
docker run --rm "${IMAGE_NAME}"