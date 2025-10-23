#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 \"url1,url2,url3\""
    exit 1
fi

IMAGE_NAME="table-extractor"
OUTPUT_DIR="csv_output_$(date +%Y%m%d_%H%M%S)"
DOCKERFILE_PATH="../project2"

mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    echo "Docker image '$IMAGE_NAME' not found. Building..."
    docker build --no-cache -t "$IMAGE_NAME" "$DOCKERFILE_PATH"
    echo "Docker image built successfully"
else
    echo "Docker image '$IMAGE_NAME' found"
fi

IFS=',' read -ra URLS <<< "$1"

for url in "${URLS[@]}"; do
    url=$(echo "$url" | xargs)
    echo ""
    echo "Processing: $url"
    
    website_name=$(echo "$url" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|\.|-|g')
    page_name=$(echo "$url" | sed -e 's|.*/||' -e 's|\?.*||')
    unique_prefix="${website_name}_${page_name}"
    
    temp_dir=$(mktemp -d)
    
    # Run container, but copy hello.py into temp dir first so volume mount doesn't overwrite
    docker run --rm -v "$temp_dir:/output" -e PYTHONUNBUFFERED=1 --entrypoint /bin/sh "$IMAGE_NAME" -c "cd /output && python /app/hello.py $url"
    
    csv_count=0
    for csv_file in "$temp_dir"/*.csv; do
        if [ -f "$csv_file" ]; then
            basename=$(basename "$csv_file")
            new_name="${unique_prefix}_${basename}"
            mv "$csv_file" "$OUTPUT_DIR/$new_name"
            csv_count=$((csv_count + 1))
        fi
    done
    
    rm -rf "$temp_dir"
    
    if [ $csv_count -gt 0 ]; then
        echo "Extracted $csv_count tables from $url"
    else
        echo "No tables found at $url"
    fi
done

ZIP_FILE="${OUTPUT_DIR}.zip"
echo ""
echo "Creating zip file: $ZIP_FILE"

if command -v zip >/dev/null 2>&1; then
    zip -r "$ZIP_FILE" "$OUTPUT_DIR"
else
    tar -czf "${OUTPUT_DIR}.tar.gz" "$OUTPUT_DIR"
    echo "Created: ${OUTPUT_DIR}.tar.gz"
fi

echo ""
echo "Process complete!"
echo "Output directory: $OUTPUT_DIR"
echo "Total CSV files: $(ls -1 "$OUTPUT_DIR"/*.csv 2>/dev/null | wc -l)"
ls -lh "$OUTPUT_DIR"
