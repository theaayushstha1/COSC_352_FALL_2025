#!/bin/bash
set -e

OUTPUT_FLAG=""

for arg in "$@"; do
  case $arg in
    --output=csv)
      OUTPUT_FLAG="csv"
      ;;
    --output=json)
      OUTPUT_FLAG="json"
      ;;
  esac
done

docker build -t project6 .
docker run --rm project6 $OUTPUT_FLAG