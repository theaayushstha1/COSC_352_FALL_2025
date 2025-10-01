#!/bin/bash

# Usage: ./tables.sh "url1,url2,url3"

URL_LIST=$1
DOCKER_IMAGE="project3-tables"
OUTPUT_DIR="scraped_tables"
ZIP_NAME="tables_$(date +%Y%m%d_%H%M%S).zip"

# Check Docker image
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
    echo "[INFO] Docker image not found. Building..."
    docker build -t "$DOCKER_IMAGE" .
fi

# Prepare output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Convert comma-separated list to space-separated
IFS=',' read -ra URL_ARRAY <<< "$URL_LIST"

# Run container with all URLs
docker run --rm \
    -v "$(pwd)/$OUTPUT_DIR:/output" \
    "$DOCKER_IMAGE" "${URL_ARRAY[@]}"

# Zip the output
zip -r "$ZIP_NAME" "$OUTPUT_DIR" >/dev/null
echo "✅ All CSVs saved in $OUTPUT_DIR and zipped as $ZIP_NAME"
