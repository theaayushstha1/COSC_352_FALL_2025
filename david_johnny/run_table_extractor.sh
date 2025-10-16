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
  url=${url#http://}
  url=${url#https://}
  url=${url%%/*}
  echo "$url" | sed -E 's/[^A-Za-z0-9]+/_/g' | sed -E 's/^_+|_+$//g' | cut -c1-40
}

# Run container for each URL
for raw in "$@"; do
  IFS=',' read -ra URLS <<< "$raw"
  for url in "${URLS[@]}"; do
    url=$(echo "$url" | sed -E 's/^ +| +$//g')
    if [ -z "$url" ]; then
        continue
    fi

    # Sanitize URL
    prefix=$(sanitize "$url")
    echo "Processing $url -> prefix $prefix"

    # Create a temporary output directory for Docker
    if [ "${DEBUG:-0}" = "1" ]; then
      HOST_TMP_DIR="$PWD/debug_tmp_${TS}_$prefix"
      mkdir -p "$HOST_TMP_DIR"
    else
      HOST_TMP_DIR=$(mktemp -d)
    fi

    # Convert to Docker-compatible path
    UNAME_OUT="$(uname -s)"
    # Helper: produce a Windows-style path when possible on MSYS/MinGW/Cygwin
    get_win_path() {
      local p="$1"
      # Prefer cygpath if available (reliable)
      if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "$p"
        return
      fi

      # If realpath exists, check if it supports -w/--windows
      if command -v realpath >/dev/null 2>&1; then
        if realpath --help 2>&1 | grep -Eq "(-w|--windows)"; then
          realpath -w "$p"
          return
        fi
        # Try pwd -W (available in some MSYS environments)
        if command -v pwd >/dev/null 2>&1; then
          # run in a subshell to avoid changing cwd
          (cd "$p" 2>/dev/null && pwd -W) && return
        fi
        # As a last resort use realpath without -w (POSIX path)
        realpath "$p" 2>/dev/null && return
      fi

      # Default: return the original path (POSIX style)
      printf '%s' "$p"
    }

    if [[ "$UNAME_OUT" == MINGW* || "$UNAME_OUT" == MSYS* || "$UNAME_OUT" == CYGWIN* ]]; then
      HOST_TMP_DIR_WIN=$(get_win_path "$HOST_TMP_DIR")
    else
      # Linux / macOS
      HOST_TMP_DIR_WIN="$HOST_TMP_DIR"
    fi

    # Debug logging: show resolved host paths used for the Docker mount
    echo "HOST_TMP_DIR (POSIX) = $HOST_TMP_DIR"
    echo "HOST_TMP_DIR_WIN (for docker mount) = $HOST_TMP_DIR_WIN"

  # Run Docker container: mount host temp dir at /output, run the image's python script
  # with working dir set to /output so it writes CSVs straight to the mounted folder.
  # Capture stdout/stderr to files inside the temp dir for debugging.
  docker run --rm -v "$HOST_TMP_DIR_WIN":/output -w /output "$IMAGE_NAME" sh -c "python /app/project1.py '$url'" > "$HOST_TMP_DIR/container_stdout.log" 2> "$HOST_TMP_DIR/container_stderr.log" || true

    # Print container logs (first 200 lines) if present to aid debugging
    if [ -s "$HOST_TMP_DIR/container_stdout.log" ]; then
      echo "--- container stdout ---"
      sed -n '1,200p' "$HOST_TMP_DIR/container_stdout.log" || true
      echo "--- end container stdout ---"
    fi
    if [ -s "$HOST_TMP_DIR/container_stderr.log" ]; then
      echo "--- container stderr ---"
      sed -n '1,200p' "$HOST_TMP_DIR/container_stderr.log" || true
      echo "--- end container stderr ---"
    fi


    # Move CSV files to final output directory
    shopt -s nullglob
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

    # Clean up temp dir
    if [ "${DEBUG:-0}" = "1" ]; then
      echo "DEBUG=1: preserving temp dir $HOST_TMP_DIR for inspection"
    else
      rm -rf "$HOST_TMP_DIR"
    fi
done
done
# Collect all sanitized site names for naming the zip
site_names=()
for raw in "$@"; do
  IFS=',' read -ra URLS <<< "$raw"
  for url in "${URLS[@]}"; do
    url=$(echo "$url" | sed -E 's/^ +| +$//g')
    if [ -n "$url" ]; then
      site_names+=("$(sanitize "$url")")
    fi
  done
done

# Join site names with underscores
site_prefix=$(IFS=_; echo "${site_names[*]}")

# Limit to 60 chars in case of many URLs
site_prefix=$(echo "$site_prefix" | cut -c1-60)

ZIP_FILE="$OUT_ROOT/${site_prefix}_${TS}.zip"
# Create zip archive
pushd "$OUT_ROOT" >/dev/null
zip -r "$(basename "$ZIP_FILE")" "$TS" >/dev/null
popd >/dev/null

echo "All done. CSV files are in $OUT_DIR and archive is $ZIP_FILE"

