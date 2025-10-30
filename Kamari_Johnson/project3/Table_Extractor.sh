#!/bin/bash
set -x

# HTML Table Extractor — Batch Mode
# Usage: ./Table_Extractor.sh "url1,url2,url3"

INPUT="$1"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ROOT_DIR="tables_$TIMESTAMP"
ZIP_NAME="${ROOT_DIR}.zip"
DOCKER_IMAGE="html-table-parser"
DOCKERFILE_PATH="../project2/Dockerfile"

echo "Creating output folder: $ROOT_DIR"
mkdir -p "$ROOT_DIR"

# Build Docker image if missing
if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
    echo "Building Docker image: $DOCKER_IMAGE"
    docker build -t "$DOCKER_IMAGE" -f "$DOCKERFILE_PATH" "$(dirname "$DOCKERFILE_PATH")"
fi

# Get current user ID for Docker
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Parse URLs
IFS=',' read -ra URLS <<< "$INPUT"
for URL in "${URLS[@]}"; do
    echo "Fetching: $URL"

    # Normalize domain for filenames
    DOMAIN=$(echo "$URL" | awk -F/ '{print $3}' | sed 's/www\.//g' | tr -cd '[:alnum:]')
    HTML_PATH="${ROOT_DIR}/${DOMAIN}.html"
    OUT_DIR="${ROOT_DIR}/${DOMAIN}_csv"

    mkdir -p "$OUT_DIR"

    # Download HTML
    curl -sL "$URL" -o "$HTML_PATH"
    if [ ! -s "$HTML_PATH" ]; then
        echo "Warning: Failed to download HTML from $URL"
        continue
    fi

    # Run parser inside Docker
    echo "Running Docker container for $DOMAIN"
    docker run --rm \
      -u $USER_ID:$GROUP_ID \
      -v "$(pwd)/$ROOT_DIR:/data" \
      "$DOCKER_IMAGE" \
      python3 /app/parse_tables.py "/data/${DOMAIN}.html" "/data/${DOMAIN}_csv"

    # Count extracted tables
    CSV_COUNT=$(find "$OUT_DIR" -type f -name "*.csv" | wc -l)
    if [ "$CSV_COUNT" -eq 0 ]; then
        echo "No tables extracted for $DOMAIN"
    else
        echo "Extracted $CSV_COUNT tables for $DOMAIN"
    fi
done

# Zip results
echo "Zipping output folder: $ROOT_DIR"
zip -r "$ZIP_NAME" "$ROOT_DIR"
echo "Archive created: $ZIP_NAME"