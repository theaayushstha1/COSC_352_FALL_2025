#!/bin/bash

# Usage: ./process_sites.sh "https://site1.com,https://site2.com,https://site3.com"

OUTPUT_DIR="csv_outputs"
mkdir -p "$OUTPUT_DIR"

IMAGE_NAME="project2"

if ! docker image inspect $IMAGE_NAME > /dev/null 2>&1; then
    echo "Docker image $IMAGE_NAME not found. Building it now..."
    docker build -t $IMAGE_NAME ./kaleb_dunn/project2
fi

IFS=',' read -r -a websites <<< "$1"

for site in "${websites[@]}"; do
    
    clean_name=$(echo "$site" | sed -E 's#https?://##; s#/$##; s#[/:]#_#g')

    TEMP_DIR="$OUTPUT_DIR/$clean_name"
    mkdir -p "$TEMP_DIR"

    echo "Processing $site ..."
    docker run --rm -v "$(pwd)/$TEMP_DIR":/data $IMAGE_NAME "$site"

    echo "CSV files for $site saved in $TEMP_DIR"
done

ZIP_FILE="csv_outputs.zip"
zip -r "$ZIP_FILE" "$OUTPUT_DIR"

echo "All CSV files zipped into $ZIP_FILE"
