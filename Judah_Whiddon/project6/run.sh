#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project6-go"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1 ; then
  echo "Building Docker image $IMAGE_NAME..."
  DOCKER_BUILDKIT=0 docker build -t "$IMAGE_NAME" .
fi

mkdir -p out
echo "Running analysis $* ..."
docker run --rm -v "$PWD/out":/out "$IMAGE_NAME" "$@"
