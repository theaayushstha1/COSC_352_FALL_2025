#!/bin/bash

# Check if an argument was provided
if [ $# -eq 0 ]; then 
    echo "Usage: $0 <comma,separated,list>"
    exit 1
fi

# Store the comma-separated list from the first argument
List=$1

# Name of your Docker image
IMAGE_NAME="project2:latest"
CSV_DIR="csv_output"
ZIP_FILE="csv_output.zip"

# Check if Docker image exists, otherwise build it
if [[ -z "$(docker images -q $IMAGE_NAME 2>/dev/null)" ]]; then
    echo "Docker image $IMAGE_NAME not found. Building..."
    docker build -t $IMAGE_NAME ./project2
fi

# Prepare output directory
rm -rf "$CSV_DIR" "$ZIP_FILE"
mkdir -p "$CSV_DIR"

# Set IFS (Internal Field Separator) to comma for splitting
IFS=','

# Loop through each item in the list
for item in $List; do
    if [[ -f "$item" ]]; then
        base_name=$(basename "$item")
        website_name="${base_name%.*}"

        echo "Processing $item -> $website_name"

        docker run --rm -v "$(pwd)":/data $IMAGE_NAME \
            python copy.py "/data/$item" "/data/$CSV_DIR/${website_name}.csv"
    else
        echo "File $item not found, skipping..."
    fi
done

# Zip the directory with all CSVs
zip -r "$ZIP_FILE" "$CSV_DIR"

echo "All done! CSVs saved in $CSV_DIR and zipped into $ZIP_FILE"
