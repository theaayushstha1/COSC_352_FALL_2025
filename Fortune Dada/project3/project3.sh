#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="projet1:latest"
PROJECT2_DIR="./Project2"
CONTAINER_CMD="/app/extract_tables.py"
OUTPUT_ROOT="csv_output_$(date +%Y%m%d_%H%M%S)"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari"

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"URL1,URL2,URL3\""
  exit 1
fi

if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Image $IMAGE_NAME not found. Please build your Project 2 image first."
  exit 1
fi


CONTAINER_CMD="python /app/project1.py"


mkdir -p "$OUTPUT_ROOT"

slugify_url() {
  printf "%s" "$1" | sed -E 's#^[a-zA-Z]+://##' | sed -E 's#[/?&=]+#_#g' | sed -E 's#[^A-Za-z0-9._-]#_#g'
}

download_html() {
  curl -fsSL -A "$UA" "$1" -o "$2"
}

extract_tables() {
  local abs; abs="$(cd "$1" && pwd)"
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" \
  docker run --rm -v "$abs":/data "$IMAGE_NAME" \
    sh -lc "$CONTAINER_CMD --in /data/$2 --out /data"
}


IFS=',' read -r -a URLS <<< "$1"

for u in "${URLS[@]}"; do
  url="$(echo "$u" | xargs)"
  [[ -z "$url" ]] && continue
  slug="$(slugify_url "$url")"
  page_dir="$OUTPUT_ROOT/$slug"
  mkdir -p "$page_dir"
  html_file="$page_dir/${slug}.html"
  download_html "$url" "$html_file"
  extract_tables "$page_dir" "$(basename "$html_file")"
  shopt -s nullglob
  i=1
  for csv in "$page_dir"/*.csv; do
    mv -f "$csv" "${page_dir}/${slug}_${i}.csv"
    ((i++))
  done
  shopt -u nullglob
done

if command -v zip >/dev/null 2>&1; then
  zip -qr "${OUTPUT_ROOT}.zip" "$OUTPUT_ROOT"
else
  powershell.exe -NoProfile -Command "Compress-Archive -Path '${OUTPUT_ROOT}' -DestinationPath '${OUTPUT_ROOT}.zip' -Force"
fi
echo "CSVs saved in $OUTPUT_ROOT and zipped as ${OUTPUT_ROOT}.zip"
