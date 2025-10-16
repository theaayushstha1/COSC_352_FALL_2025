nano process_tables.sh
#!/bin/bash

# HTML Table to CSV Processor Script
# Usage: ./process_tables.sh "url1,url2,url3"

set -e  # Exit on error

# Configuration
DOCKER_IMAGE_NAME="html-table-parser"
DOCKER_CONTAINER_NAME="table-parser-container"
OUTPUT_DIR="csv_output_$(date +%Y%m%d_%H%M%S)"
ZIP_FILE="${OUTPUT_DIR}.zip"
TEMP_HTML_DIR="temp_html"

# Check if URLs were provided
if [ -z "$1" ]; then
    echo "Error: No URLs provided"
    echo "Usage: $0 \"url1,url2,url3\""
    exit 1
fi

# Create directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$TEMP_HTML_DIR"

echo "=== HTML Table to CSV Processor ==="
echo "Output directory: $OUTPUT_DIR"
echo ""

# Function to sanitize website name for filename
sanitize_name() {
    local url="$1"
    # Extract domain and path, remove protocol and special characters
    echo "$url" | sed -e 's|https\?://||g' -e 's|[^a-zA-Z0-9]|_|g' -e 's|_*$||g'
}

# Function to check if Docker image exists
check_docker_image() {
    if docker images | grep -q "$DOCKER_IMAGE_NAME"; then
        echo "✓ Docker image '$DOCKER_IMAGE_NAME' found"
        return 0
    else
        echo "✗ Docker image '$DOCKER_IMAGE_NAME' not found"
        return 1
    fi
}

# Function to build Docker image
build_docker_image() {
    echo ""
    echo "=== Building Docker Image ==="
    
    # Check if Dockerfile exists
    if [ ! -f "Dockerfile" ]; then
        echo "Creating Dockerfile..."
        cat > Dockerfile << 'EOF'
FROM python:3.9-slim

WORKDIR /app

# Install required packages
RUN pip install --no-cache-dir pandas beautifulsoup4 lxml html5lib requests

# Copy the parser script
COPY table_parser.py /app/

# Set entrypoint
ENTRYPOINT ["python", "/app/table_parser.py"]
EOF
    fi
    
    # Check if parser script exists
    if [ ! -f "table_parser.py" ]; then
        echo "Creating table_parser.py..."
        cat > table_parser.py << 'EOF'
import sys
import pandas as pd
from bs4 import BeautifulSoup
import os

def parse_html_tables(html_file, output_prefix):
    """Parse HTML tables and save as CSV files"""
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        soup = BeautifulSoup(html_content, 'html.parser')
        tables = soup.find_all('table')
        
        if not tables:
            print(f"No tables found in {html_file}")
            return 0
        
        csv_files = []
        for idx, table in enumerate(tables):
            # Parse table with pandas
            df = pd.read_html(str(table))[0]
            
            # Generate output filename
            csv_filename = f"{output_prefix}_table_{idx+1}.csv"
            df.to_csv(csv_filename, index=False)
            csv_files.append(csv_filename)
            print(f"Created: {csv_filename} ({len(df)} rows)")
        
        return len(csv_files)
    
    except Exception as e:
        print(f"Error processing {html_file}: {str(e)}")
        return 0

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python table_parser.py <html_file> <output_prefix>")
        sys.exit(1)
    
    html_file = sys.argv[1]
    output_prefix = sys.argv[2]
    
    count = parse_html_tables(html_file, output_prefix)
    print(f"Total tables processed: {count}")
EOF
    fi
    
    echo "Building Docker image..."
    docker build -t "$DOCKER_IMAGE_NAME" .
    
    if [ $? -eq 0 ]; then
        echo "✓ Docker image built successfully"
    else
        echo "✗ Failed to build Docker image"
        exit 1
    fi
}

# Check for Docker image, build if necessary
if ! check_docker_image; then
    build_docker_image
fi

# Split URLs by comma and process each
IFS=',' read -ra URLS <<< "$1"

echo ""
echo "=== Processing ${#URLS[@]} websites ==="
echo ""

for url in "${URLS[@]}"; do
    # Trim whitespace
    url=$(echo "$url" | xargs)
    
    echo "Processing: $url"
    
    # Sanitize URL for filename
    site_name=$(sanitize_name "$url")
    html_file="${TEMP_HTML_DIR}/${site_name}.html"
    
    # Download HTML
    echo "  Downloading HTML..."
    curl -s -L "$url" -o "$html_file"
    
    if [ ! -s "$html_file" ]; then
        echo "  ✗ Failed to download or empty file"
        continue
    fi
    
    # Process with Docker
    echo "  Parsing tables with Docker..."
    docker run --rm \
        -v "$(pwd)/${TEMP_HTML_DIR}:/input" \
        -v "$(pwd)/${OUTPUT_DIR}:/output" \
        "$DOCKER_IMAGE_NAME" \
        "/input/$(basename $html_file)" \
        "/output/${site_name}"
    
    echo "  ✓ Completed"
    echo ""
done

# Create ZIP file
echo "=== Creating ZIP Archive ==="
zip -r "$ZIP_FILE" "$OUTPUT_DIR"
echo "✓ Created: $ZIP_FILE"

# Cleanup
echo ""
echo "=== Cleanup ==="
rm -rf "$TEMP_HTML_DIR"
echo "✓ Removed temporary HTML files"

# Summary
echo ""
echo "=== Summary ==="
echo "CSV files created in: $OUTPUT_DIR"
echo "ZIP archive: $ZIP_FILE"
echo "Total CSV files: $(find "$OUTPUT_DIR" -name "*.csv" | wc -l)"
echo ""
echo "Done!"
