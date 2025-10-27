#!/usr/bin/env bash
set -euo pipefail

IMAGE="project5-baltimore:latest"
HERE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# We'll forward any provided arguments into the container (e.g. --output=csv --out-file=path)
ARGS=("$@")

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Docker image $IMAGE not found. Building..."
  docker build -t "$IMAGE" "$HERE_DIR"
else
  echo "Docker image $IMAGE found."
fi

# Run container with the project directory bind-mounted so outputs persist to host
# This makes it easy to get homicides_2025.csv/json after the run.
if [ ${#ARGS[@]} -gt 0 ]; then
  ARGLINE="${ARGS[*]}"
  docker run --rm -v "$HERE_DIR":/app "$IMAGE" /usr/bin/sbt "run $ARGLINE"
else
  docker run --rm -v "$HERE_DIR":/app "$IMAGE" /usr/bin/sbt run
fi
