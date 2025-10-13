#!/bin/bash

# Extract tables from HTML using Docker file

# Usage: ./table_bash.sh "http://url.com,http://url2.com,http://url3.com"

DOCKER_IMAGE="html_table_parser"
OUTPUT_DIR="table_output"
ZIP_NAME="table_output.zip"
mkdir -p "$OUTPUT_DIR"



# Check docker
if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
    echo "Docker image not found. Building image."
    docker build -t "$DOCKER_IMAGE" .
else
    echo "Docker image '$DOCKER_IMAGE' found."
fi 

# Split and process URLS 
IFS="," read -ra URLS <<< "$1"
for URL in "${URLS[@]}"; do
    URL=$(echo "$URL" | xargs)
    echo "$URL"
    
    FILE_NAME=$(echo "$URL" | sed -E 's~^(https?://)?(www\.)?~~' | cut -d/ -f1)
    OUTPUT_FILE="${FILE_NAME}.csv"


    # Create and download HTML files
    HTML="$OUTPUT_DIR/${FILE_NAME}.html"

    # Run Docker imager
    docker run --rm \
        -v "$(pwd)/$OUTPUT_DIR":/output \
        "$DOCKER_IMAGE" "$URL" "/output/$OUTPUT_FILE"
done

zip -r "$ZIP_NAME" "$OUTPUT_DIR" > /dev/null
echo "All CSV files directed to '$OUTPUT_DIR' and zipped to '$ZIP_NAME'" 
