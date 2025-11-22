#!/usr/bin/env bash
set -euo pipefail

IMAGE="amitbhattarai-project5-scala"
DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_FLAG="${1:-}"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[run.sh] Building Docker image..."
  docker build -t "$IMAGE" "$DIR"
else
  echo "[run.sh] Rebuilding Docker image..."
  docker build -t "$IMAGE" "$DIR"
fi

echo "[run.sh] Running container..."
if [ -n "$OUTPUT_FLAG" ]; then
  docker run --rm -v "$DIR:/app" "$IMAGE" bash -c "mkdir -p out && scalac -d out src/Main.scala && scala -cp out Main $OUTPUT_FLAG"
else
  docker run --rm -v "$DIR:/app" "$IMAGE" bash -c "mkdir -p out && scalac -d out src/Main.scala && scala -cp out Main"
fi
