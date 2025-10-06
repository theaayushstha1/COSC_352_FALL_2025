#!/bin/bash

# Usage: ./process_webpages.sh "https://www.contextures.com/xlSampleData01.html,https://www.w3schools.com/html/html_tables.asp,https://people.sc.fsu.edu/~jburkardt/data/csv/csv.html"

set -e

INPUT_URLS="$1"
CSV_DIR="output_csvs"
ZIP_FILE="output_csvs.zip"
DOCKER_IMAGE="project2_html_table_extractor"
PROJECT2_PATH="../project2" # Adjust if needed

# Create output directory
mkdir -p "$CSV_DIR"

# Check if Docker image exists, build if not
if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
    echo "Docker image not found. Building..."
    docker build -t "$DOCKER_IMAGE" "$PROJECT2_PATH"
fi

IFS=',' read -ra URLS <<< "$INPUT_URLS"
for URL in "${URLS[@]}"; do
    # Get a safe name for the website
    SITE_NAME=$(echo "$URL" | sed 's|https\?://||; s|/|_|g; s|\.|_|g')
    HTML_FILE="$CSV_DIR/${SITE_NAME}.html"
    
    echo "Downloading $URL..."
    curl -sL "$URL" -o "$HTML_FILE"
    
    echo "Processing $HTML_FILE with Docker..."
    docker run --rm -v "$(pwd)/$CSV_DIR:/app/data" "$DOCKER_IMAGE" python king.py "/app/data/${SITE_NAME}.html" --out /app/data
    # The container runs king.py, which expects the HTML file and --out directory

done

# Zip the output directory
zip -r "$ZIP_FILE" "$CSV_DIR"

echo "All done! CSVs are in $CSV_DIR and zipped as $ZIP_FILE."
