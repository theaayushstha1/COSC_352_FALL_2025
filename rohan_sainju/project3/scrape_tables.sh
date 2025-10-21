#!/bin/bash

echo "======================================"
echo "  Multi-Website Table Scraper"
echo "======================================"

if [ $# -eq 0 ]; then
    echo "Usage: $0 'url1,url2,url3'"
    exit 1
fi

DOCKER_IMAGE="rohan_project2"
OUTPUT_DIR="csv_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$OUTPUT_DIR"
echo "Output directory: $OUTPUT_DIR"
echo ""

IFS=',' read -ra URLS <<< "$1"
echo "Found ${#URLS[@]} URL(s) to process"
echo ""

site_count=0

for url in "${URLS[@]}"; do
    url=$(echo "$url" | xargs)
    [ -z "$url" ] && continue
    
    site_count=$((site_count + 1))
    echo "[$site_count] Processing: $url"
    
    # Extract site name
    site_name=$(echo "$url" | sed 's|https\?://||' | sed 's|^www\.||' | cut -d'/' -f1 | sed 's|\.|-|g')
    echo "    Site name: $site_name"
    
    # Run container and get container ID
    container_id=$(docker create "$DOCKER_IMAGE" "$url")
    
    if [ $? -ne 0 ]; then
        echo "    ✗ Failed to create container"
        continue
    fi
    
    # Start and wait for container to finish
    docker start -a "$container_id" > /dev/null 2>&1
    
    # Copy CSV files from container
    docker cp "$container_id:/app/." "$OUTPUT_DIR/temp_$site_name/" 2>/dev/null
    
    # Find and rename CSV files
    csv_count=$(find "$OUTPUT_DIR/temp_$site_name/" -name "table_*.csv" 2>/dev/null | wc -l)
    
    if [ "$csv_count" -gt 0 ]; then
        echo "    ✓ Found $csv_count table(s)"
        counter=1
        for csv in "$OUTPUT_DIR/temp_$site_name"/table_*.csv; do
            if [ "$csv_count" -eq 1 ]; then
                mv "$csv" "$OUTPUT_DIR/${site_name}.csv"
                echo "    ✓ Saved: ${site_name}.csv"
            else
                mv "$csv" "$OUTPUT_DIR/${site_name}_table${counter}.csv"
                echo "    ✓ Saved: ${site_name}_table${counter}.csv"
                counter=$((counter + 1))
            fi
        done
        rm -rf "$OUTPUT_DIR/temp_$site_name"
    else
        echo "    ⚠ No tables found"
    fi
    
    # Clean up container
    docker rm "$container_id" > /dev/null 2>&1
    echo ""
done

# Create zip
echo "======================================"
csv_files=$(find "$OUTPUT_DIR" -name "*.csv" 2>/dev/null | wc -l)

if [ "$csv_files" -gt 0 ]; then
    ZIP_FILE="tables_${TIMESTAMP}.zip"
    cd "$OUTPUT_DIR"
    zip -q "../$ZIP_FILE" *.csv
    cd ..
    echo "✓ Created: $ZIP_FILE ($csv_files CSV files)"
    echo ""
    echo "CSV files also available in: $OUTPUT_DIR/"
else
    echo "⚠ No CSV files to zip"
fi

echo ""
echo "Processing complete!"
