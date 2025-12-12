#!/usr/bin/env bash
set -euo pipefail
IMG="project6-go:latest"

# Create host out dir
mkdir -p out

# Prefer Git Bash Windows path; fall back to POSIX
if WIN_PWD=$(pwd -W 2>/dev/null); then
  HOST_OUT="$WIN_PWD/out"
else
  HOST_OUT="$PWD/out"
fi

if ! docker image inspect "$IMG" >/dev/null 2>&1; then
  echo "Docker image not found. Building..."
  docker build -t "$IMG" .
fi

# Pass through either bare "csv|json" or "--output=csv|json"
ARGS=("$@")

docker run --rm -v "${HOST_OUT}:/out" "$IMG" "${ARGS[@]}"
