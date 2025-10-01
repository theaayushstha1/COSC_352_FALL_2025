#!/usr/bin/env bash
set -euo pipefail

# Usage: ./batch_tables.sh "URL1,URL2,URL3" [output_dir]
# Example:
#   ./batch_tables.sh "https://pypl.github.io/PYPL.html,https://www.tiobe.com/tiobe-index/,https://en.wikipedia.org/wiki/Comparison_of_programming_languages"

INPUT_CSV_LIST="${1:-}"
OUT_PARENT="${2:-run_$(date +%Y%m%d_%H%M%S)}"

if [[ -z "${INPUT_CSV_LIST}" ]]; then
  echo "ERROR: Provide a comma-separated list of webpages as the first argument."
  echo "Example:"
  echo "  $0 \"https://pypl.github.io/PYPL.html,https://www.tiobe.com/tiobe-index/,https://en.wikipedia.org/wiki/Comparison_of_programming_languages\""
  exit 1
fi

IMAGE_NAME="project2-scraper"
DOCKERFILE_PATH="Dockerfile"       # or "Dockerfile.txt" if you kept that name

# 1) Ensure Docker is available
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed or not on PATH."
  exit 1
fi

# 2) Check if the image exists; if not, build it
if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  echo "Docker image '${IMAGE_NAME}' not found; building..."
  docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" .
fi

# 3) Prepare output directory on the host
mkdir -p "${OUT_PARENT}"

# Helper: turn a URL into a safe folder name
slugify() {
  local s="$1"
  # Strip scheme
  s="${s#http://}"; s="${s#https://}"
  # Trim trailing slashes
  s="${s%%/}"
  # Replace non-alnum (and .) with underscores
  s="$(printf '%s' "$s" | tr -c '[:alnum:].' '_')"
  echo "$s"
}

# 4) Iterate all URLs in the input list
IFS=',' read -r -a URLS <<< "${INPUT_CSV_LIST}"
for url in "${URLS[@]}"; do
  url="$(echo "$url" | xargs)" # trim
  if [[ -z "${url}" ]]; then continue; fi

  slug="$(slugify "${url}")"
  out_dir_host="${OUT_PARENT}/${slug}"
  mkdir -p "${out_dir_host}"

  echo "Processing: ${url}"
  # We mount host output parent to /app/output in the container,
  # then tell the script to write into /app/output/<slug>
  docker run --rm \
    -v "$(pwd)/${OUT_PARENT}:/app/output" \
    "${IMAGE_NAME}" \
    "${url}" --out "/app/output/${slug}"
done

# 5) Zip the whole output directory
zip_name="${OUT_PARENT}.zip"
echo "Creating zip: ${zip_name}"
# -r recursive, -q quiet
zip -r -q "${zip_name}" "${OUT_PARENT}"

echo "Done."
echo "Output directory: ${OUT_PARENT}"
echo "Zip archive:      ${zip_name}"
