#!/bin/bash

# Bash script to process a comma-separated list of webpages, download their HTML,
# run the Docker container from Project 2 to extract tables to CSVs, build the image if not found,
# name CSVs uniquely by site, save them in a directory, and zip the directory.

# Usage: ./script.sh "url1,url2,url3"

# Check if at least one argument (comma-separated URLs) is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 \"url1,url2,url3\""
  exit 1
fi

# Docker image name from Project 2
IMAGE_NAME="mhtml-to-csv-converter"

# Output directory for CSVs
OUTPUT_DIR="csv_outputs"

# Create output directory if not exists
mkdir -p "$OUTPUT_DIR"

# Function to build Docker image if not found
build_image_if_needed() {
  if ! docker images | grep -q "$IMAGE_NAME"; then
    echo "Docker image $IMAGE_NAME not found. Building it..."
    docker build -t "$IMAGE_NAME" .
    if [ $? -ne 0 ]; then
      echo "Failed to build Docker image."
      exit 1
    fi
  fi
}

# Build image if needed
build_image_if_needed

# Split comma-separated URLs
IFS=',' read -r -a urls <<< "$1"

# Process each URL
for url in "${urls[@]}"; do
  # Extract site name for unique CSV naming (e.g., wikipedia.org from URL)
  site_name=$(echo "$url" | awk -F/ '{print $3}' | sed 's/www\.//g' | sed 's/\./_/g')

  # Download HTML
  html_file="${site_name}.html"
  curl -L "$url" -o "$html_file"
  if [ $? -ne 0 ]; then
    echo "Failed to download $url"
    continue
  fi

  # Run Docker container with volume mount to process HTML and output CSVs to host
  docker run -v $(pwd):/app/output "$IMAGE_NAME" "/app/output/$html_file"

  # Rename generated CSVs with site prefix to avoid overwriting
  for csv in table_*.csv; do
    if [ -f "$csv" ]; then
      mv "$csv" "${OUTPUT_DIR}/${site_name}_${csv}"
    fi
  done

  # Clean up temporary HTML
  rm "$html_file"
done

# Zip the output directory
zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR"

echo "Processing complete. CSVs saved in $OUTPUT_DIR and zipped as ${OUTPUT_DIR}.zip"

