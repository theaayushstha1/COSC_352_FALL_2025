x#!/usr/bin/env bash
set -euo pipefail

# ==== CONFIG: set to your actual image/tag and Dockerfile directory ====
IMAGE="cosc352-project2-mapea4"          # the Docker image tag for Project 2
DOCKERFILE_DIR="Marquise_Pearson/project2"   # path containing the Project 2 Dockerfile
# ======================================================================

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 'URL1,URL2,URL3,...'"
  exit 1
fi

URLS_CSV="$1"
OUTDIR="$(pwd)/scrape_output"
ZIPNAME="scrape_output.zip"

# Build the image if it's missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "[INFO] Docker image '$IMAGE' not found. Building from $DOCKERFILE_DIR ..."
  docker build -t "$IMAGE" "$DOCKERFILE_DIR"
  echo "[INFO] Build complete."
fi

mkdir -p "$OUTDIR"

# Split the comma-separated list into an array
IFS=',' read -r -a URLS <<< "$URLS_CSV"

# Make a filesystem-safe slug from a URL: host + sanitized path
slugify_url() {
  local url="$1" host rest path slug
  host="$(echo "$url" | awk -F'/' '{print $3}')"
  rest="$(echo "$url" | cut -d/ -f4-)"
  path="$(echo "$rest" | tr '/?&=:#' '_' | tr -cd '[:alnum:]_.-')"
  [[ -z "$host" ]] && host="unknown"
  if [[ -z "$path" ]]; then slug="$host"; else slug="${host}_${path}"; fi
  slug="$(echo "$slug" | sed -E 's/_+/_/g; s/^_+|_+$//g' | cut -c1-120)"
  echo "$slug"
}

for url in "${URLS[@]}"; do
  url="$(echo "$url" | xargs)"   # trim spaces
  [[ -z "$url" ]] && continue

  slug="$(slugify_url "$url")"
  site_dir="$OUTDIR/$slug"
  mkdir -p "$site_dir"

  echo "[INFO] Processing: $url"
  echo "[INFO] Output dir: $site_dir"

  # Run the Project 2 container; CSVs will appear in site_dir
  if ! docker run --rm -v "$site_dir:/work" "$IMAGE" "$url"; then
    echo "[WARN] Container run failed for '$url' — skipping"
    continue
  fi

  # Prefix CSV names with the slug so different sites never overwrite
  shopt -s nullglob
  any_csv=false
  for f in "$site_dir"/table_*.csv; do
    any_csv=true
    base="$(basename "$f")"
    [[ "$base" == "${slug}_"* ]] || mv "$f" "$site_dir/${slug}_$base"
  done
  shopt -u nullglob

  if ! $any_csv; then
    echo "[WARN] No tables found for: $url"
  else
    echo "[INFO] CSVs written under: $site_dir"
  fi
done

# Zip the whole output directory
if command -v zip >/dev/null 2>&1; then
  rm -f "$ZIPNAME"
  (cd "$(dirname "$OUTDIR")" && zip -r "$(basename "$ZIPNAME")" "$(basename "$OUTDIR")" >/dev/null)
  echo "[INFO] Created: $ZIPNAME"
else
  echo "[WARN] 'zip' not found — skipping archive creation."
fi

echo "[DONE] All URLs processed."

