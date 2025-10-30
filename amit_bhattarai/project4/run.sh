#!/usr/bin/env bash
set -euo pipefail

IMAGE="amitbhattarai-project4-scala"
DIR="$(cd "$(dirname "$0")" && pwd)"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[run.sh] Docker image not found. Building..."
  docker build -t "$IMAGE" "$DIR"
else
  echo "[run.sh] Rebuilding image to ensure latest code..."
  docker build -t "$IMAGE" "$DIR"
fi

echo "[run.sh] Running container..."
docker run --rm "$IMAGE"
