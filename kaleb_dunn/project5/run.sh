#!/bin/bash

# Baltimore Homicide Analysis Runner Script
# This script builds the Docker image if needed and runs the Scala analysis
# Supports output format flags: --output=csv, --output=json, or default stdout

IMAGE_NAME="project5"
OUTPUT_DIR="output"

# Check if Docker image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
  echo "Docker image '$IMAGE_NAME' not found. Building..."
  docker build -t $IMAGE_NAME .
  
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build Docker image"
    exit 1
  fi
  
  echo "Build complete!"
  echo ""
fi

# Create output directory if it doesn't exist
mkdir -p $OUTPUT_DIR

# Parse arguments
OUTPUT_FORMAT=""
for arg in "$@"; do
  if [[ $arg == --output=* ]]; then
    OUTPUT_FORMAT=$arg
  fi
done

# Run the container
echo "Running Baltimore Homicide Analysis..."
echo ""

if [[ -z "$OUTPUT_FORMAT" ]]; then
  # No output format specified, run normally (stdout)
  docker run --rm $IMAGE_NAME
else
  # Output format specified, mount volume to save files
  docker run --rm -v "$(pwd)/$OUTPUT_DIR:/app/output" -w /app/output $IMAGE_NAME $OUTPUT_FORMAT
  
  echo ""
  echo "Output files saved to: ./$OUTPUT_DIR/"
  ls -lh ./$OUTPUT_DIR/ | tail -n +2
fi