#!/usr/bin/env bash
set -euo pipefail

IMAGE="project4-baltimore:latest"
HERE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# We'll forward any provided arguments into the container (e.g. --output=csv --out-file=path)
ARGS=("$@")

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Docker image $IMAGE not found. Building..."
  docker build -t "$IMAGE" "$HERE_DIR"
else
  echo "Docker image $IMAGE found."
fi

echo "Running container..."
# Bind-mount the project directory so any files written inside /app are available on the host.
if [ ${#ARGS[@]} -gt 0 ]; then
  # run sbt run inside the container and pass program args as a single sbt command
  # join args into a single string
  ARGLINE="${ARGS[*]}"
  docker run --rm -v "$HERE_DIR":/app "$IMAGE" /usr/bin/sbt "run $ARGLINE"
else
  docker run --rm -v "$HERE_DIR":/app "$IMAGE" /usr/bin/sbt run
fi
