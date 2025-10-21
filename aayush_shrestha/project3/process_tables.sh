#!/bin/bash

# Usage: ./process_tables.sh "url1,url2,url3"

URL_LIST=$1
DOCKER_IMAGE="project2-tables"
OUTPUT_DIR="output_csvs"
ZIP_FILE="tables_output.zip"

# Build image if missing
if ! docker image inspect "$DOCKER_IMAGE" >/dev/null 2>&1; then
    echo "[INFO] Building Docker image..."
    docker build -t "$DOCKER_IMAGE" .
else
    echo "[INFO] Using image: $DOCKER_IMAGE"
fi

# Reset output dir
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Process URLs
IFS=',' read -ra URL_ARRAY <<< "$URL_LIST"
for URL in "${URL_ARRAY[@]}"; do
    echo "[INFO] $URL"

    DOMAIN=$(echo "$URL" | sed -E 's~https?://([^/]+)/?.*~\1~; s/[^a-zA-Z0-9]/_/g')
    HTML_FILE="$OUTPUT_DIR/${DOMAIN}.html"

    # Download HTML
    curl -s "$URL" -o "$HTML_FILE"

    # Run container (ENTRYPOINT is already python read_html_table.py)
    docker run --rm -v "$(pwd)/$OUTPUT_DIR:/data" "$DOCKER_IMAGE" \
        "/data/${DOMAIN}.html" "/data/${DOMAIN}"

    echo "docker run --rm -v $(pwd)/$OUTPUT_DIR:/data $DOCKER_IMAGE /data/${DOMAIN}.html /data/${DOMAIN}"

    echo "[INFO] Finished: $DOMAIN"
done

# Zip results
zip -r "$ZIP_FILE" "$OUTPUT_DIR" >/dev/null
echo "[DONE] All CSVs in $ZIP_FILE"