#!/bin/bash
set -e

# Default output flag
OUTPUT_FLAG="stdout"

# Parse optional flag
for arg in "$@"; do
  case $arg in
    --output=csv)
      OUTPUT_FLAG="csv"
      ;;
    --output=json)
      OUTPUT_FLAG="json"
      ;;
  esac
done

# Build Docker image
docker build -t baltimore-homicide-analyzer .

# Run container with flag
docker run --rm -v "$(pwd)":/app baltimore-homicide-analyzer "$OUTPUT_FLAG"