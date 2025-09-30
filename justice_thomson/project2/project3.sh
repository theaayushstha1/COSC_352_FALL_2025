#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 \"url1,url2,url3,...\""
  exit 1
fi

IMAGE_NAME="table-extractor"
OUTPUT_DIR="csv_outputs"

# Step 1. Build the Project 2 image if missing
if [[ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]]; then
  echo "Docker image '$IMAGE_NAME' not found. Building..."
  docker build -t "$IMAGE_NAME" -f Dockerfile .
fi

# Step 2. Reset output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Step 3. Split comma-separated list into array
IFS=',' read -r -a URLS <<< "$1"

for raw in "${URLS[@]}"; do
  URL="$(echo "$raw" | xargs)"   # trim spaces
  [[ -z "$URL" ]] && continue
  echo "Processing: $URL"

  # Step 4. Sanitize site name into folder
  SAFE_DIR=$(echo "$URL" | sed -E 's#^https?://##; s#[^A-Za-z0-9._-]+#_#g')
  TARGET_DIR="$OUTPUT_DIR/$SAFE_DIR"
  mkdir -p "$TARGET_DIR"

  # Step 5. Run Project 2 container with output mounted
  docker run --rm -v "$(pwd)/$TARGET_DIR:/app/output" "$IMAGE_NAME" "$URL"
done

# Step 6. Zip everything
ZIP_NAME="csv_outputs.zip"
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$OUTPUT_DIR" >/dev/null

echo "Done! Results in $OUTPUT_DIR and $ZIP_NAME"
