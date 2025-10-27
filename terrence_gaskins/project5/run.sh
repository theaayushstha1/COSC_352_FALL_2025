#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="baltimore"
FORMAT="stdout"

# Parse optional --output flag
if [[ $# -gt 0 && $1 == --output=* ]]; then
  FORMAT="${1#--output=}"
fi

# Navigate to the directory where this script lives
cd "$(dirname "$0")" || {
  echo "Error: Could not cd into script directory."
  exit 1
}

# Build Docker image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image not found. Building image..."
  docker build -t "$IMAGE_NAME" .
else
  echo "Docker image '$IMAGE_NAME' already exists."
fi

# Run the container and pass the format argument
echo "Running container with output format: $FORMAT"
docker run --rm "$IMAGE_NAME" "$FORMAT"
