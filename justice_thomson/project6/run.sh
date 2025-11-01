#!/usr/bin/env bash
set -euo pipefail
IMAGE_NAME="project6:latest"

# Enable BuildKit for faster, cache-friendly builds
export DOCKER_BUILDKIT=1

# Always (re)build to ensure the latest code is in the image
echo "🛠️  Building Docker image ${IMAGE_NAME}..."
docker build -t "${IMAGE_NAME}" -f Dockerfile .

echo " Running container..."
# --rm to auto-remove, --network default so it can reach the internet
# Mount current directory to /app/output for file writing
docker run -v "$(pwd)":/app/output --rm "${IMAGE_NAME}" "$@"