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

# Resolve script directory so paths are reliable regardless of CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configurable variables
IMAGE_NAME="project2_table_extractor:latest"
# project2 dir is sibling of project3
PROJECT2_DIR="$SCRIPT_DIR/../project2"
# place outputs inside the project3 directory so they are easy to find
OUT_ROOT="$SCRIPT_DIR/extracted_csvs"
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
  # Create a temporary output directory for Docker under the script dir so mounts
  # are consistent and easy to inspect.
  HOST_TMP_BASE="$SCRIPT_DIR/.tmp"
  mkdir -p "$HOST_TMP_BASE"
  HOST_TMP_DIR="$HOST_TMP_BASE/${TS}_${prefix}"
  mkdir -p "$HOST_TMP_DIR"

    # Use --mount with a host path under the repo so Docker will write CSVs directly
    # into the host folder (mounted at /output). Run the bundled script from /app.
    DOCKER_ENV_ARGS=( )
    if [ "${TABLE_CLASS+set}" = set ]; then
      DOCKER_ENV_ARGS+=( -e "TABLE_CLASS=$TABLE_CLASS" )
    fi
    # Force the container to write CSVs into /output (the mounted host folder)
    DOCKER_ENV_ARGS+=( -e "OUTPUT_DIR=/output" )
    # Use --mount with the host path directly to avoid -v quoting issues on Windows
    # Capture container stdout/stderr into the host temp dir so we can debug if it fails
  # Run with a shell that cds into /output to avoid using -w which can be rewritten
  # by MSYS/Git Bash into an unintended Windows path (e.g. C:/Program Files/Git/output).
  docker run --rm "${DOCKER_ENV_ARGS[@]}" --mount type=bind,source="$HOST_TMP_DIR",target=/output "$IMAGE_NAME" --entrypoint sh -c "cd /output && python /app/project1.py '$url'" >"$HOST_TMP_DIR/container_stdout.log" 2>"$HOST_TMP_DIR/container_stderr.log"
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "Docker run failed for $url (rc=$rc). Dumping logs:"
      echo "--- container stdout ---"
      sed -n '1,200p' "$HOST_TMP_DIR/container_stdout.log" || true
      echo "--- container stderr ---"
      sed -n '1,200p' "$HOST_TMP_DIR/container_stderr.log" || true
      exit $rc
    fi
    # Move CSV files to final output directory
    shopt -s nullglob
    found=false
    for f in "$HOST_TMP_DIR"/table_*.csv; do
        if [ -f "$f" ]; then
            base=$(basename "$f")
            mv "$f" "$OUT_DIR/${prefix}_$base"
            if [ "${QUIET:-0}" != "1" ]; then
              echo "Saved $OUT_DIR/${prefix}_$base"
            fi
            found=true
        fi
    done
  if [ "$found" = false ]; then
    if [ "${QUIET:-0}" != "1" ]; then
      echo "No table_*.csv files produced for $url"
    fi
  fi

    # Clean up temp dir
    rm -rf "$HOST_TMP_DIR"
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
if command -v zip >/dev/null 2>&1; then
  pushd "$OUT_ROOT" >/dev/null
  zip -r "$(basename "$ZIP_FILE")" "$TS" >/dev/null
  popd >/dev/null
else
  # Fallback: use Python stdlib to create the zip if `zip` is unavailable
  python - <<PY
import os,zipfile
out_root = os.path.abspath("$OUT_ROOT")
ts = "$TS"
zip_path = os.path.join(out_root, os.path.basename("$ZIP_FILE"))
with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as z:
    base_dir = os.path.join(out_root, ts)
    for root, dirs, files in os.walk(base_dir):
        for f in files:
            full = os.path.join(root, f)
            arcname = os.path.join(ts, os.path.relpath(full, base_dir))
            z.write(full, arcname)
print(zip_path)
PY
fi

echo "All done. CSV files are in $OUT_DIR and archive is $ZIP_FILE"

