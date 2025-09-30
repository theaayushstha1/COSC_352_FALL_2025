#!/bin/bash

# Project 3: Multi-Website Table Scraper
# Author: Rohan Sainju
# This script processes multiple websites and extracts HTML tables using Docker

echo "======================================"
echo "  Multi-Website Table Scraper"
echo "======================================"
echo ""

# Check if URLs are provided
if [ $# -eq 0 ]; then
    echo "Error: No URLs provided"
    echo "Usage: $0 'url1,url2,url3'"
    echo ""
    echo "Example:"
    echo "  $0 'https://pypl.github.io/PYPL.html,https://en.wikipedia.org/wiki/Comparison_of_programming_languages,https://www.tiobe.com/tiobe-index/'"
    exit 1
fi

# Configuration
DOCKER_IMAGE="rohan_project2"
OUTPUT_DIR="csv_output"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ZIP_FILE="tables_${TIMESTAMP}.zip"

# Create output directory
echo "Creating output directory: $OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
echo ""

# Check if Docker image exists, if not try to build it
if ! docker images | grep -q "$DOCKER_IMAGE"; then
    echo "Docker image '$DOCKER_IMAGE' not found."
    echo "Attempting to build from ../project2..."
    
    if [ -d "../project2" ]; then
        cd ../project2
        docker build -t "$DOCKER_IMAGE" .
        cd - > /dev/null
        echo "Docker image built successfully!"
    else
        echo "Error: project2 directory not found. Please build your Docker image first:"
        echo "  cd ../project2"
        echo "  docker build -t $DOCKER_IMAGE ."
        exit 1
    fi
fi

echo "Using Docker image: $DOCKER_IMAGE"
echo ""

# Split comma-separated URLs and process each one
IFS=',' read -ra URLS <<< "$1"

echo "Found ${#URLS[@]} URL(s) to process"
echo "======================================"
echo ""

# Counter for processed sites
site_count=0

# Process each URL
for url in "${URLS[@]}"; do
    # Trim whitespace
    url=$(echo "$url" | xargs)
    
    if [ -z "$url" ]; then
        continue
    fi
    
    site_count=$((site_count + 1))
    
    echo "[$site_count] Processing: $url"
    
    # Extract site name from URL
    # Remove protocol (http:// or https://)
    site_name=$(echo "$url" | sed 's|https\?://||')
    # Remove www.
    site_name=$(echo "$site_name" | sed 's|^www\.||')
    # Take only the domain part (before first /)
    site_name=$(echo "$site_name" | cut -d'/' -f1)
    # Replace dots with underscores
    site_name=$(echo "$site_name" | sed 's|\.|-|g')
    
    echo "    Site name: $site_name"
    
    # Create a temporary directory for this site's output
    temp_dir="${OUTPUT_DIR}/temp_${site_name}"
    mkdir -p "$temp_dir"
    
    # Run Docker container
    echo "    Running Docker container..."
    docker run --rm -v "$(pwd)/${temp_dir}:/app" "$DOCKER_IMAGE" "$url" > "${temp_dir}/docker_output.log" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "    ✓ Docker container completed successfully"
        
        # Find all CSV files generated
        csv_files=$(find "$temp_dir" -name "*.csv" -type f)
        csv_count=$(echo "$csv_files" | grep -c "csv" 2>/dev/null || echo "0")
        
        if [ "$csv_count" -gt 0 ]; then
            echo "    Found $csv_count CSV file(s)"
            
            # Move and rename CSV files
            counter=1
            for csv_file in $csv_files; do
                if [ "$csv_count" -eq 1 ]; then
                    # Single CSV: name it after the site
                    new_name="${OUTPUT_DIR}/${site_name}.csv"
                else
                    # Multiple CSVs: name them with table numbers
                    new_name="${OUTPUT_DIR}/${site_name}_table${counter}.csv"
                    counter=$((counter + 1))
                fi
                
                mv "$csv_file" "$new_name"
                echo "    ✓ Saved: $(basename $new_name)"
            done
        else
            echo "    ⚠ Warning: No CSV files generated (no tables found?)"
        fi
        
        # Clean up temp directory
        rm -rf "$temp_dir"
    else
        echo "    ✗ Error: Docker container failed"
        echo "    Check ${temp_dir}/docker_output.log for details"
    fi
    
    echo ""
done

# Create zip file of all CSVs
echo "======================================"
echo "Creating zip archive..."

csv_files_count=$(find "$OUTPUT_DIR" -name "*.csv" -type f | wc -l)

if [ "$csv_files_count" -gt 0 ]; then
    cd "$OUTPUT_DIR"
    zip -q "../$ZIP_FILE" *.csv
    cd ..
    
    echo "✓ Created: $ZIP_FILE"
    echo "  Contains $csv_files_count CSV file(s)"
    echo ""
    echo "CSV files are also available in: $OUTPUT_DIR/"
else
    echo "⚠ No CSV files to zip"
fi

echo ""
echo "======================================"
echo "Processing complete!"
echo "======================================"
