#!/bin/bash
# HTML Table Extractor - Extracts tables from URLs and saves as CSV files
# Usage: ./extract_tables.sh "url1,url2,url3"
# Usage with external files: SOURCE_DIR="/path" ./extract_tables.sh "url1,url2,url3"

set -e

# Configuration
DOCKER_IMAGE="html-table-extractor"
OUTPUT_DIR="extracted_tables"
ZIP_FILE="html_tables_$(date +%Y%m%d_%H%M%S).zip"
SOURCE_DIR="${SOURCE_DIR:-.}"
TEMP_FILES=false

# Validate input
[ $# -eq 0 ] || [ -z "$1" ] && {
    echo "Usage: $0 \"url1,url2,url3\""
    echo "Example: $0 \"https://en.wikipedia.org/wiki/List_of_countries_by_population,https://en.wikipedia.org/wiki/List_of_largest_cities,https://www.w3schools.com/html/html_tables.asp\""
    exit 1
}

# Check Docker availability
docker info &>/dev/null || { echo "Error: Docker is not running"; exit 1; }

# Copy file if needed
copy_if_needed() {
    local file=$1
    [ -f "$file" ] && return
    [ -f "$SOURCE_DIR/$file" ] || { echo "Error: $file not found"; exit 1; }
    echo "Copying $file from $SOURCE_DIR"
    cp "$SOURCE_DIR/$file" .
    TEMP_FILES=true
}

# Build Docker image if needed
docker images | grep -q "$DOCKER_IMAGE" || {
    echo "Building Docker image: $DOCKER_IMAGE"
    copy_if_needed "test.py"
    copy_if_needed "Dockerfile"
    docker build -t "$DOCKER_IMAGE" . &>/dev/null
    echo "Docker image built successfully"
}

# Process URL
process_url() {
    echo "Processing: $1"
    docker run --rm -v "$(pwd)/$OUTPUT_DIR:/app/output" "$DOCKER_IMAGE" sh -c "cd /app/output && python /app/test.py '$1'"
    echo "---"
}

# Main execution
echo "=== HTML Table Extractor ==="
IFS=',' read -ra URLS <<< "$1"
echo "Processing ${#URLS[@]} URLs"

mkdir -p "$OUTPUT_DIR"

for url in "${URLS[@]}"; do
    url=$(echo "$url" | xargs)
    [ -n "$url" ] && process_url "$url"
done

# Summary
file_count=$(ls -1 "$OUTPUT_DIR"/*.csv 2>/dev/null | wc -l)
echo -e "\n=== Complete ==="
echo "CSV files created: $file_count"

if [ $file_count -gt 0 ]; then
    ls -lh "$OUTPUT_DIR"/*.csv 2>/dev/null
    echo -e "\nCreating archive: $ZIP_FILE"
    zip -rq "$ZIP_FILE" "$OUTPUT_DIR"/
    echo "Archive: $ZIP_FILE ($(ls -lh "$ZIP_FILE" | awk '{print $5}'))"
fi

# Cleanup
[ "$TEMP_FILES" = true ] && {
    echo -e "\nCleaning up temporary files..."
    rm -f test.py Dockerfile
}

echo "Complete: $(date)"