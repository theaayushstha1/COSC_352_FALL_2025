#!/bin/bash

# Check if an argument (comma-separated list of URLs) is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 \"url1,url2,url3,...\""
    exit 1
fi

# Define the Docker image name
IMAGE_NAME="table-extractor"

# Check if the Docker image exists; build if not
if [ -z "$(docker images -q $IMAGE_NAME)" ]; then
    echo "Docker image $IMAGE_NAME not found. Building now..."
    docker build -t $IMAGE_NAME .
    if [ $? -ne 0 ]; then
        echo "Failed to build Docker image."
        exit 1
    fi
fi

# Create output directory if it doesn't exist
OUTPUT_DIR="csv_outputs"
mkdir -p "$OUTPUT_DIR"

# Split the comma-separated URLs into an array
IFS=',' read -r -a URLS <<< "$1"

# Process each URL
for URL in "${URLS[@]}"; do
    echo "Processing $URL..."
    docker run -v "$(pwd)/$OUTPUT_DIR:/app" $IMAGE_NAME "$URL"
done

# Create a zip file of the output directory
ZIP_FILE="csv_outputs.zip"
zip -r "$ZIP_FILE" "$OUTPUT_DIR"
echo "Created zip file: $ZIP_FILE"

