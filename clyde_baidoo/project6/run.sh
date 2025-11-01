#!/bin/bash
set -e

# Capture optional --output flag
OUTPUT_FLAG=""
if [[ "$1" == --output=* ]]; then
  OUTPUT_FLAG="$1"
fi

# Build Docker image
docker build -t baltimore-homicides-go .

# Run container
if [[ -n "$OUTPUT_FLAG" ]]; then
  docker run --rm -v "$(pwd):/app" baltimore-homicides-go "$OUTPUT_FLAG"
else
  docker run --rm baltimore-homicides-go
fi