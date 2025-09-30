#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 \"url1,url2,url3,...\""
  exit 1
fi

IMAGE_NAME="table-extractor"
OUTPUT_DIR="csv_outputs"

# Build Docker image if not present
if [[ -z "$(docker images -q "$IMAGE_NAME" 2>/dev/null)" ]]; then
  echo "Building Docker image '$IMAGE_NAME'..."
  docker build -t "$IMAGE_NAME" .
fi

# Reset output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Split URLs
IFS=',' read -r -a URLS <<< "$1"

for raw in "${URLS[@]}"; do
  URL="$(echo "$raw" | xargs)"
  [[ -z "$URL" ]] && continue
  echo "Processing: $URL"

  SAFE_DIR=$(echo "$URL" | sed -E 's#^https?://##; s#[^A-Za-z0-9._-]+#_#g')
  TARGET_DIR="$OUTPUT_DIR/$SAFE_DIR"
  mkdir -p "$TARGET_DIR"

  docker run --rm -v "$(pwd)/$TARGET_DIR:/app/output" "$IMAGE_NAME" "$URL"
done

# Create zip
ZIP_NAME="csv_outputs.zip"
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$OUTPUT_DIR" >/dev/null
echo "Done. Results in: $ZIP_NAME"
