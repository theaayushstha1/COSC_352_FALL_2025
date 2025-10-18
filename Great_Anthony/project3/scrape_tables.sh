#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <url1>,<url2>,<url3>,..."
    exit 1
fi

IFS=',' read -ra URLS <<< "$1"

if [ ${#URLS[@]} -lt 3 ]; then
    echo "Error: Please provide at least 3 URLs separated by commas"
    exit 1
fi

OUTPUT_DIR="csv_outputs"
mkdir -p "$OUTPUT_DIR"

DOCKER_IMAGE="project2-scraper"

if ! docker image inspect "$DOCKER_IMAGE" &> /dev/null; then
    echo "Building Docker image..."
    docker build -t "$DOCKER_IMAGE" ./project2/
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image"
        exit 1
    fi
fi

echo "Processing ${#URLS[@]} websites..."

for url in "${URLS[@]}"; do
    website_name=$(echo "$url" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|[^a-zA-Z0-9._-]|_|g')
    output_file="$OUTPUT_DIR/${website_name}.csv"
    
    echo "Processing: $url"
    
    docker run --rm \
        -v "$(pwd)/$OUTPUT_DIR:/output" \
        "$DOCKER_IMAGE" \
        "$url" \
        "/output/${website_name}.csv"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully processed $url"
    else
        echo "✗ Failed to process $url"
    fi
    echo "---"
done

ZIP_FILE="table_data_$(date +%Y%m%d_%H%M%S).zip"
echo "Creating zip file: $ZIP_FILE"

cd "$OUTPUT_DIR"
zip -r "../$ZIP_FILE" *.csv
cd ..

echo "✓ Successfully created $ZIP_FILE"
echo "Done! All CSV files are in $OUTPUT_DIR/ and archived in $ZIP_FILE"
