#!/usr/bin/env bash
set -euo pipefail

APP="./main"

OUTPUT_FLAG=""

if [[ $# -gt 0 ]]; then
  case "$1" in
    -output=csv|-output=json)
      OUTPUT_FLAG="$1"
      ;;
    *)
      echo "Usage: $0 [-output=csv|-output=json]"
      exit 1
      ;;
  esac
fi


if [[ -z "$OUTPUT_FLAG" ]]; then
  echo "Running in stdout mode..."
  $APP
else
  echo "Running with flag: $OUTPUT_FLAG"
  $APP "$OUTPUT_FLAG"
fi
