#!/bin/bash

# === Config ===
IMAGE_NAME="html_table_to_csv"
OUTPUT_DIR="output_csv"

# === Step 1: Ensure image exists, build if not ===
if ! docker images --format '{{.Repository}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "Docker image not found. Building..."
    docker build -t $IMAGE_NAME .
fi

# === Step 2: Prepare output directory ===
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# === Step 3: Process each URL ===
IFS=',' read -ra URLS <<< "$1"

for url in "${URLS[@]}"; do
    echo "Processing $url"

    # Extract hostname (e.g., en.wikipedia.org)
    hostname=$(echo $url | awk -F/ '{print $3}' | sed 's/[^a-zA-Z0-9.-]/_/g')

    # Run docker container for this URL
    docker run --rm -v $(pwd)/$OUTPUT_DIR:/app/output $IMAGE_NAME python html_table_to_csv.py "$url"

    # Move and rename results
    for file in $(ls $OUTPUT_DIR/table_*.csv 2>/dev/null); do
        base=$(basename $file)
        mv "$file" "$OUTPUT_DIR/${hostname}_${base}"
    done
done

# === Step 4: Zip results ===
zip -r tables_output.zip $OUTPUT_DIR

echo " CSVs are in $OUTPUT_DIR and zipped into tables_output.zip"
