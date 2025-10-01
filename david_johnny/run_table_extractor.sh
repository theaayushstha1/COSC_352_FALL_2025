#!/usr/bin/env bash

# run_table_extractor.sh
# Usage: ./run_table_extractor.sh "url1,url2,..."
# The script will: 
# - Ensure Docker image 'project2_table_extractor:latest' exists, build from project2 if missing
# - Create an output directory ./extracted_csvs/<timestamp>
# - For each URL in the comma-separated list, run the Docker container with the URL as argument
#   and copy the produced CSVs from the container to the output directory, prefixed by a safe name
# - Zip the output directory into a timestamped archive

set -euo pipefail
IFS=','

# Configurable variables
IMAGE_NAME="project2_table_extractor:latest"
PROJECT2_DIR="project2"
OUT_ROOT="extracted_csvs"
TS=$(date +"%Y%m%d_%H%M%S")
OUT_DIR="$OUT_ROOT/$TS"
ZIP_FILE="$OUT_ROOT/extracted_csvs_${TS}.zip"

mkdir -p "$OUT_DIR"

# Check if docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found in PATH. Please install Docker and ensure it's available." >&2
  exit 1
fi

# Build image if it doesn't exist
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image $IMAGE_NAME not found. Building from $PROJECT2_DIR..."
  if [ ! -f "$PROJECT2_DIR/Dockerfile" ]; then
    echo "Dockerfile not found in $PROJECT2_DIR. Aborting." >&2
    exit 1
  fi
  docker build -t "$IMAGE_NAME" "$PROJECT2_DIR"
else
  echo "Docker image $IMAGE_NAME found locally." 
fi

# Helper: sanitize a URL into a filename-friendly prefix
sanitize() {
  local url="$1"
  # remove protocol
  url=${url#http://}
  url=${url#https://}
  # take up to first slash
  url=${url%%/*}
  # replace non-alphanumeric with _
  echo "$url" | sed -E 's/[^A-Za-z0-9]+/_/g' | sed -E 's/^_+|_+$//g'
}

# Run container for each URL
for raw in "$@"; do
  # Support either a single argument that's comma-separated or multiple args
  IFS=',' read -ra URLS <<< "$raw"
  for url in "${URLS[@]}"; do
    url=$(echo "$url" | sed -E 's/^ +| +$//g')
    if [ -z "$url" ]; then
      continue
    fi
    prefix=$(sanitize "$url")
    echo "Processing $url -> prefix $prefix"

    # Create a temporary container-specific output directory
    TMP_OUT="/tmp/output"
    HOST_TMP_DIR=$(mktemp -d)

    # Run the docker container, mounting the host tmp dir as CWD so files are written there
    # The Dockerfile's CMD runs project1.py with a default URL, but we will override it with our URL
    docker run --rm -v "$HOST_TMP_DIR":/app -w /app "$IMAGE_NAME" bash -c "python project1.py '$url'"

    # Move any generated table_*.csv files to final location with prefix
    shopt -s nullglob || true
    found=false
    for f in "$HOST_TMP_DIR"/table_*.csv; do
      if [ -f "$f" ]; then
        base=$(basename "$f")
        mv "$f" "$OUT_DIR/${prefix}_$base"
        echo "Saved $OUT_DIR/${prefix}_$base"
        found=true
      fi
    done
    if [ "$found" = false ]; then
      echo "No table_*.csv files produced for $url"
    fi

    # Clean up host tmp dir
    rm -rf "$HOST_TMP_DIR"
  done
done

# Create zip
pushd "$OUT_ROOT" >/dev/null 2>&1
zip -r "extracted_csvs_${TS}.zip" "$TS" >/dev/null
popd >/dev/null 2>&1

echo "All done. CSV files are in $OUT_DIR and archive is $ZIP_FILE"
