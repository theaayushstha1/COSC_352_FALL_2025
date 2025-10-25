set -euo pipefail

IMG="bmore-homicides-scala:latest"


if ! docker image inspect "$IMG" >/dev/null 2>&1; then
  echo "Docker image not found. Building..."
  docker build -t "$IMG" .
fi


docker run --rm "$IMG"