set -euo pipefail

IMAGE_NAME="project4-scala"
OUTPUT_DIR_HOST="$(pwd)/output"
args=("$@")
arg_count=${#args[@]}
OUTPUT_FORMAT="stdout"

index=0
while [ $index -lt $arg_count ]; do
  arg="${args[$index]}"
  case "$arg" in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      ;;
    --output)
      next_index=$((index + 1))
      if [ $next_index -ge $arg_count ]; then
        echo "Error: --output requires a value (csv, json, or stdout)." >&2
        exit 1
      fi
      OUTPUT_FORMAT="${args[$next_index]}"
      ;;
  esac
  index=$((index + 1))
done

if [ -z "$OUTPUT_FORMAT" ]; then
  OUTPUT_FORMAT="stdout"
fi

OUTPUT_FORMAT=$(printf '%s' "$OUTPUT_FORMAT" | tr '[:upper:]' '[:lower:]')

docker build -t "$IMAGE_NAME" .

if [ "$OUTPUT_FORMAT" = "csv" ] || [ "$OUTPUT_FORMAT" = "json" ]; then
  mkdir -p "$OUTPUT_DIR_HOST"
  docker run --rm \
    -e OUTPUT_DIR=/output \
    -v "$OUTPUT_DIR_HOST":/output \
    "$IMAGE_NAME" "${args[@]}"
else
  docker run --rm "$IMAGE_NAME" "${args[@]}"
fi
