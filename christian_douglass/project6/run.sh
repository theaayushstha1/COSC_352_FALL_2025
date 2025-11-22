#!/usr/bin/env bash
set -euo pipefail

# Build docker image and run it. If you want outputs to persist in the host project folder,
# run the container with -v "$PWD":/app. This script shows both ways.

IMG_NAME="christian_douglass_project6:latest"

if [ "$#" -eq 0 ]; then
  docker build -t "$IMG_NAME" .
  docker run --rm "$IMG_NAME"
else
  docker build -t "$IMG_NAME" .
  # If user wants outputs persisted, run with bind mount to current directory
  docker run --rm -v "$PWD":/app "$IMG_NAME" "$@"
fi
