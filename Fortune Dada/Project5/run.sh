set -euo pipefail
IMG="bmore-homicides-scala:latest"
FORMAT="${1:-}"

if ! docker image inspect "$IMG" >/dev/null 2>&1; then
  echo "Docker image not found. Building..."
  docker build -t "$IMG" .
fi

mkdir -p out

# --- convert Git Bash path to Windows style for Docker ---
WIN_OUT=$(pwd -W)/out

if [ -n "$FORMAT" ]; then
  docker run --rm -v "${WIN_OUT}:/out" "$IMG" "$FORMAT"
else
  docker run --rm -v "${WIN_OUT}:/out" "$IMG"
fi
