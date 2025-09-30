#!/bin/bash

set -e  # Exit on any error

# Configuration
DOCKER_IMAGE="html-table-to-csv"
INPUT_PAGES=""
OUTPUT_DIR="csv_output"
ZIP_FILE="csv_files.zip"

# Function to display usage
usage() {
    echo "Usage: $0 -p \"url1,url2,url3\""
    echo "Example: $0 -p \"https://en.wikipedia.org/wiki/Comparison_of_programming_languages,https://en.wikipedia.org/wiki/Programming_languages_used_in_most_popular_websites,https://pypi.github.io/PYPI.html\""
    exit 1
}

# Parse command line arguments
while getopts "p:" opt; do
    case $opt in
        p)
            INPUT_PAGES="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
    esac
done

# Validate input
if [ -z "$INPUT_PAGES" ]; then
    echo "Error: No webpages provided"
    usage
fi

# Check if required commands are available
for cmd in curl docker; do
    if ! command -v $cmd > /dev/null 2>&1; then
        echo "Error: $cmd is not installed. Please install it first."
        exit 1
    fi
done

# Create output directory
mkdir -p "$OUTPUT_DIR"
echo "Created output directory: $OUTPUT_DIR"

# Function to extract domain name from URL for filename
get_filename_from_url() {
    local url="$1"
    # Remove protocol and extract domain/path
    local clean_url="${url#*://}"
    # Replace non-alphanumeric characters with underscores
    echo "$clean_url" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

# Function to check if Docker image exists
docker_image_exists() {
    docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1
}

# Function to build Docker image if not found
build_docker_image() {
    echo "Docker image '$DOCKER_IMAGE' not found. Building..."
    
    # Create a simple Dockerfile for the table converter
    cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Install required packages
RUN pip install pandas beautifulsoup4 requests

# Create the table conversion script
COPY table_converter.py .

ENTRYPOINT ["python", "table_converter.py"]
EOF

    # Create the Python table converter script
    cat > table_converter.py << 'EOF'
import sys
import pandas as pd
from bs4 import BeautifulSoup
import requests
import os

def html_to_csv(input_file, output_file):
    """Convert HTML tables to CSV"""
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        soup = BeautifulSoup(html_content, 'html.parser')
        tables = soup.find_all('table')
        
        if not tables:
            print(f"No tables found in {input_file}")
            return False
        
        # Process all tables
        for i, table in enumerate(tables):
            # Handle multiple tables by appending index to filename
            if i == 0:
                current_output = output_file
            else:
                base, ext = os.path.splitext(output_file)
                current_output = f"{base}_table{i+1}{ext}"
            
            # Extract table data
            data = []
            headers = []
            
            # Get header row if exists
            header_row = table.find('tr')
            if header_row:
                headers = [th.get_text(strip=True) for th in header_row.find_all(['th', 'td'])]
            
            # Get data rows
            rows = table.find_all('tr')
            start_row = 1 if headers else 0  # Skip header row if we have headers
            
            for row in rows[start_row:]:
                cells = row.find_all(['td', 'th'])
                row_data = [cell.get_text(strip=True) for cell in cells]
                if row_data:  # Only add non-empty rows
                    data.append(row_data)
            
            # Create DataFrame
            if headers:
                df = pd.DataFrame(data, columns=headers)
            else:
                df = pd.DataFrame(data)
            
            # Save to CSV
            df.to_csv(current_output, index=False)
            print(f"Converted table {i+1} to {current_output}")
        
        return True
        
    except Exception as e:
        print(f"Error converting {input_file}: {str(e)}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python table_converter.py <input_html> <output_csv>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    success = html_to_csv(input_file, output_file)
    sys.exit(0 if success else 1)
EOF

    # Build the Docker image
    docker build -t "$DOCKER_IMAGE" .
    
    # Clean up temporary files
    rm -f Dockerfile table_converter.py
    
    echo "Docker image '$DOCKER_IMAGE' built successfully"
}

# Main processing function
process_webpages() {
    local IFS=','  # Set comma as delimiter
    local urls=($INPUT_PAGES)  # Split comma-separated string into array
    local processed_count=0
    
    echo "Processing ${#urls[@]} webpages..."
    
    for url in "${urls[@]}"; do
        # Clean up URL
        url=$(echo "$url" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -z "$url" ]; then
            continue
        fi
        
        echo "Processing: $url"
        
        # Generate filenames
        local base_name=$(get_filename_from_url "$url")
        local html_file="${base_name}.html"
        local csv_file="${base_name}.csv"
        local output_path="$OUTPUT_DIR/$csv_file"
        
        # Download webpage
        echo "  Downloading HTML content..."
        if curl -s -L -o "$html_file" "$url"; then
            # Check if file was downloaded successfully and has content
            if [ -s "$html_file" ]; then
                echo "  Converting tables to CSV..."
                
                # Run Docker container to convert tables
                if docker run --rm \
                    -v "$(pwd):/app" \
                    -w /app \
                    "$DOCKER_IMAGE" \
                    "$html_file" \
                    "$output_path"; then
                    
                    echo "  Successfully created: $output_path"
                    ((processed_count++))
                else
                    echo "  Warning: Failed to convert tables for $url"
                fi
            else
                echo "  Warning: Downloaded file is empty for $url"
            fi
            
            # Clean up temporary HTML file
            rm -f "$html_file"
        else
            echo "  Error: Failed to download $url"
        fi
        
        echo "  ---"
    done
    
    echo "Successfully processed $processed_count out of ${#urls[@]} webpages"
}

# Main execution
main() {
    echo "=== Project 3: HTML Table to CSV Converter ==="
    echo "Input pages: $INPUT_PAGES"
    echo "Output directory: $OUTPUT_DIR"
    echo "=============================================="
    
    # Check and build Docker image if needed
    if ! docker_image_exists; then
        build_docker_image
    else
        echo "Docker image '$DOCKER_IMAGE' found"
    fi
    
    # Process all webpages
    process_webpages
    
    # Create zip file
    echo "Creating zip file: $ZIP_FILE"
    if zip -r "$ZIP_FILE" "$OUTPUT_DIR" > /dev/null 2>&1; then
        echo "Successfully created: $ZIP_FILE"
        
        # Display summary
        echo ""
        echo "=== Processing Complete ==="
        echo "CSV files location: $OUTPUT_DIR/"
        echo "Zip file: $ZIP_FILE"
        echo "Files created:"
        ls -la "$OUTPUT_DIR"/
    else
        echo "Error: Failed to create zip file"
        exit 1
    fi
}

# Run main function
main