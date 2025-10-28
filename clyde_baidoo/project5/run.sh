#!/bin/bash
set -e

# Capture optional flag
OUTPUT_FLAG=""
if [[ "$1" == --output=* ]]; then
  OUTPUT_FLAG="$1"
fi

# Build Docker image (adjust Dockerfile path if needed)
docker build -t baltimore-homicides -f Dockerfile .

# Run container
# Mount current folder so outputs appear locally
if [[ -n "$OUTPUT_FLAG" ]]; then
  # Run with output flag (CSV or JSON)
  docker run --rm -v "$(pwd):/app" baltimore-homicides sbt "run $OUTPUT_FLAG"
else
  # Default: run without flag -> prints all web info + questions to terminal
  docker run --rm -v "$(pwd):/app" baltimore-homicides sbt "run"
fi
