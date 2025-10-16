#!/bin/bash

# Project 3 - HTML Table Extractor

# Exit on error
set -e

# Input check
if [ -z "$1" ]; then
  echo "Usage: $0 \"url1,url2,url3\""
  exit 1
fi

# Convert comma-separated list into array
IFS=',' read -ra URLS <<< "$1"

# Output directory
OUTPUT_DIR="csv_outputs"
mkdir -p "$OUTPUT_DIR"

# Docker image name
IMAGE_NAME="project2_html_parser"

# Check if Docker image exists
if ! docker images --format '{{.Repository}}' | grep -q "$IMAGE_NAME"; then
  echo "Docker image not found. Building..."
  docker build -t $IMAGE_NAME ../project2
fi

# Process each URL
for url in "${URLS[@]}"; do
  echo "Processing: $url"

  # Download webpage
  filename=$(echo "$url" | sed 's~https\?://~~; s~/~_~g')
  html_file="${OUTPUT_DIR}/${filename}.html"
  curl -s "$url" -o "$html_file"

  # Run Docker container to extract tables
  docker run --rm -v "$(pwd)/$OUTPUT_DIR:/data" $IMAGE_NAME \
    /data/"$(basename "$html_file")"
done

# Zip results
zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR" > /dev/null

echo "✅ All CSV files saved in $OUTPUT_DIR and zipped into ${OUTPUT_DIR}.zip"
