#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="amitbhattarai-project6-go"
CONTAINER_NAME="project6-run"
OUT_DIR="$(pwd)/out"
ARGS=("$@")  # collect any arguments, may be empty

mkdir -p "$OUT_DIR"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "[build] Docker image not found. Building..."
  docker build -t "$IMAGE_NAME" .
else
  echo "[build] Rebuilding Docker image..."
  docker build -t "$IMAGE_NAME" .
fi

docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

# If ARGS is empty, skip expansion
if [ "$#" -eq 0 ]; then
  docker run --name "$CONTAINER_NAME" --rm \
    -v "$OUT_DIR":/app/out \
    "$IMAGE_NAME"
else
  docker run --name "$CONTAINER_NAME" --rm \
    -v "$OUT_DIR":/app/out \
    "$IMAGE_NAME" \
    "$@"
fi
