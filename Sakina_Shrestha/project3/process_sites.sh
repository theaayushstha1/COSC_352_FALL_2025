#!/usr/bin/env bash
set -euo pipefail

# Usage: ./process_sites.sh "url1,url2,url3"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"url1,url2,url3\""
  exit 1
fi

URLS_CSV="$1"
OUTDIR="output_csvs"
IMAGE_NAME="html-table-parser"

# Convert current path to Windows-style for Docker Desktop
if pwd -W >/dev/null 2>&1; then
  HOST_PWD="$(pwd -W)"
else
  HOST_PWD="$(pwd)"
fi

# Build Docker image if missing
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image '$IMAGE_NAME' not found. Building..."
  docker build -t "$IMAGE_NAME" .
fi

mkdir -p "$OUTDIR"

IFS=',' read -r -a URLS <<< "$URLS_CSV"

for URL in "${URLS[@]}"; do
  echo "Processing: $URL"

  # Sanitize URL into a filename prefix
  PREFIX="$(echo "$URL" | tr -cs 'A-Za-z0-9' '_' | cut -c1-40)"

  # ✅ Run script already inside the container
  docker run --rm \
  -v "${HOST_PWD}/${OUTDIR}:/app/output" \
  "$IMAGE_NAME" \
  sh -c "python3 /app/read_html_table.py '$URL' '/app/output/${PREFIX}'"

done

# Zip results using PowerShell
powershell.exe -NoProfile -Command "Compress-Archive -Path '${OUTDIR}' -DestinationPath '${OUTDIR}.zip' -Force"

echo "✅ Done! CSVs are in '$OUTDIR' and zipped into '${OUTDIR}.zip'."
