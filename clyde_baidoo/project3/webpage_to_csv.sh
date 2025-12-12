#!/bin/bash

#Run ./webpage_to_csv.sh "https://pypl.github.io/PYPL.html,https://github.com/quambene/pl-comparison,https://www.reddit.com/r/rust/comments/uq6j2q/programming_language_comparison_cheat_sheet/"

#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="webpage-to-csv-app:latest"
OUT_DIR="webpage_to_csv_outputs"
ZIP_NAME="${OUT_DIR}.zip"
DOCKERFILE_PATH="project2/Dockerfile"

# Input validation
if [ $# -lt 1 ]; then
  echo "ERROR: You must supply a comma-separated list of webpages as the first argument."
  echo "Example: $0 \"https://example.com/page,https://example.org/table\""
  exit 2
fi

URL_LIST_RAW="$1"

# output directory
mkdir -p "${OUT_DIR}"
# absolute path for mounting
OUT_DIR_ABS="$(pwd)/${OUT_DIR}"

# Checking if docker image exists; if not, build it
if ! docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
  echo "Docker image '${IMAGE_NAME}' not found. Building from ${DOCKERFILE_PATH}..."
  if [ ! -f "${DOCKERFILE_PATH}" ]; then
    echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}. Aborting."
    exit 3
  fi
  docker build -t "${IMAGE_NAME}" -f "${DOCKERFILE_PATH}" .
  echo "Built docker image ${IMAGE_NAME}."
else
  echo "Docker image '${IMAGE_NAME}' exists. Using it."
fi

# using regex
sanitize_name() {
  local url="$1"
  # Remove protocol
  local after_proto
  after_proto="$(echo "$url" | sed -E 's#^https?://##I')"
  # strip query string and fragment
  after_proto="$(echo "$after_proto" | sed -E 's#[\?#].*$##')"
  # Replace / with _
  local replaced
  replaced="$(echo "$after_proto" | sed -E 's#/+#_#g')"
  # Replace any remaining non-alphanumeric or underscore or dot with underscore
  replaced="$(echo "$replaced" | sed -E 's/[^A-Za-z0-9_.-]/_/g')"
  # Trim leading/trailing underscores or dots
  replaced="$(echo "$replaced" | sed -E 's/^[_\.-]+//; s/[_\.-]+$//')"
  # Limit to 120 characters to avoid super long names
  echo "${replaced:0:120}"
}

# Split comma-separated list (allow spaces after commas)
IFS=',' read -ra URL_ARRAY <<< "$(echo "$URL_LIST_RAW" | sed 's/, */,/g')"

# Process each URL
processed=0
for raw_url in "${URL_ARRAY[@]}"; do
  # trim whitespace
  url="$(echo "$raw_url" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  if [ -z "$url" ]; then
    continue
  fi
  safe_name="$(sanitize_name "$url")"
  # fallback if sanitization leaves empty
  if [ -z "$safe_name" ]; then
    safe_name="site_${RANDOM}"
  fi

  host_csv="${safe_name}.csv"

  echo "Processing URL: $url"
  echo " -> will write to: ${OUT_DIR}/${host_csv}"

  # docker run --rm \
  #   -v "${OUT_DIR_ABS}:/app/output" \
  #   "${IMAGE_NAME}" \
  #   python3 webpage_to_csv.py "$url" "/app/output/${host_csv}"

  # docker run --rm \
  # -v "${OUT_DIR_ABS}:/app" \
  # "${IMAGE_NAME}" \
  # python3 webpage_to_csv.py "$url"

  docker run --rm \
    -v "${OUT_DIR_ABS}:/app/output" \
    -w /app/output \
    "${IMAGE_NAME}" \
    python3 ../webpage_to_csv.py "$url"


  echo "Done: ${OUT_DIR}/${host_csv}"
  processed=$((processed + 1))
done

if [ "$processed" -eq 0 ]; then
  echo "No valid URLs processed. Exiting."
  exit 4
fi

# archive of the csv output directory (overwrite if exists)
if command -v zip >/dev/null 2>&1; then
  echo "Creating zip archive ${ZIP_NAME}..."
  [ -f "${ZIP_NAME}" ] && rm -f "${ZIP_NAME}"
  zip -r "${ZIP_NAME}" "${OUT_DIR}"
  echo "Created ${ZIP_NAME}."
elif command -v tar >/dev/null 2>&1; then
  TAR_NAME="${OUT_DIR}.tar.gz"
  echo "zip not found. Falling back to tar.gz archive: ${TAR_NAME}"
  [ -f "${TAR_NAME}" ] && rm -f "${TAR_NAME}"
  tar -czf "${TAR_NAME}" "${OUT_DIR}"
  echo "Created ${TAR_NAME}."
else
  echo "Warning: neither 'zip' nor 'tar' found; skipping archive creation."
fi

# if command -v zip >/dev/null 2>&1; then
#   echo "Creating zip archive ${ZIP_NAME}..."
#   # remove existing zip if present to ensure fresh archive
#   [ -f "${ZIP_NAME}" ] && rm -f "${ZIP_NAME}"
#   zip -r "${ZIP_NAME}" "${OUT_DIR}"
#   echo "Created ${ZIP_NAME}."
# else
#   echo "Warning: 'zip' not found; skipping archive creation."
# fi

echo "All done. CSV files are in ${OUT_DIR}/ (and ${ZIP_NAME} if created)."

