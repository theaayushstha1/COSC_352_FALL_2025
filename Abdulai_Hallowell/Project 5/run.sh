#!/bin/bash
set -e

IMAGE_NAME="project5_scala"

# always (re)build — uses cache after first time, so it's fast
docker build -t "$IMAGE_NAME" .

# accept: --output=csv|json|stdout OR csv|json|stdout
OUTPUT="stdout"
case "${1:-}" in
  --output=*) OUTPUT="${1#--output=}";;
  csv|json|stdout) OUTPUT="$1";;
esac

echo "Running (OUTPUT=$OUTPUT)…"
exec docker run --rm -e OUTPUT="$OUTPUT" -v "$(pwd)":/app "$IMAGE_NAME" scala src/main.scala

