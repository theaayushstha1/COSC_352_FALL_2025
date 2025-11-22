#!/bin/bash
set -e

IMAGE_NAME="homicide_inves_go"
DEFAULT_INPUT="homicides.csv"
DEFAULT_OUTPUT="stdout"

# Parse output format
OUTPUT="$DEFAULT_OUTPUT"
case "${1:-}" in
  --output=*) OUTPUT="${1#--output=}" ;;
  csv|json|stdout) OUTPUT="$1" ;;
esac

# Optional second arg: input file
INPUT_FILE="${2:-$DEFAULT_INPUT}"
INPUT_PATH="$(realpath "$INPUT_FILE")"

echo "Building Docker image '$IMAGE_NAME'..."
docker build -t "$IMAGE_NAME" .

echo "Running container (format=$OUTPUT, input=$(basename "$INPUT_PATH"))..."
docker run --rm \
  -v "$(dirname "$INPUT_PATH")":/app \
  -w /app \
  "$IMAGE_NAME" \
  go run main.go -format="$OUTPUT" -input="/app/$(basename "$INPUT_PATH")"
