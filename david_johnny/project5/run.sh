#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="project5-scala-homicide:latest"

# Get the directory of the script
if [ -n "${BASH_SOURCE:-}" ]; then
  DIRNAME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
else
  DIRNAME=$(cd "$(dirname "$0")" && pwd)
fi

# Parse command line arguments
OUTPUT_FORMAT=""
for arg in "$@"; do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running. Please start Docker Desktop and try again."
  exit 1
fi

# Check if Docker image exists; if not, build it
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
  echo "Docker image $IMAGE_NAME not found. Building..."
  docker build -t "$IMAGE_NAME" "$DIRNAME"
else
  echo "Docker image $IMAGE_NAME found. Skipping build."
fi

# Run the container with output format parameter
# Mount the current directory so files can be written to the host
echo "Running Scala program inside Docker..."

# Convert Windows path for Docker on Windows (Git Bash compatibility)
WIN_DIRNAME=$(echo "$DIRNAME" | sed 's|^/\([a-z]\)/|\1:/|')

if [ -n "$OUTPUT_FORMAT" ]; then
  echo "Output format: $OUTPUT_FORMAT"
  docker run --rm -v "${WIN_DIRNAME}:/output" "$IMAGE_NAME" scala Main "$OUTPUT_FORMAT"
  
  # Inform user where to find the file
  if [ "$OUTPUT_FORMAT" = "csv" ] && [ -f "$DIRNAME/homicide_analysis.csv" ]; then
    echo "CSV file created successfully: $DIRNAME/homicide_analysis.csv"
  elif [ "$OUTPUT_FORMAT" = "json" ] && [ -f "$DIRNAME/homicide_analysis.json" ]; then
    echo "JSON file created successfully: $DIRNAME/homicide_analysis.json"
  fi
else
  docker run --rm "$IMAGE_NAME"
fi