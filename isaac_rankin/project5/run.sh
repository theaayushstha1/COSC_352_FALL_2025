#!/bin/bash

OUTPUT_FORMAT=""

for arg in "$@"; do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
    *)
      echo "Unknown argument: $arg"
      echo "Usage: ./run.sh [--output=stdout|csv|json]"
      exit 1
      ;;
  esac
done

echo "Building Docker image..."
docker build -t baltimore-scraper .

if [ $? -ne 0 ]; then
  echo "Docker build failed"
  exit 1
fi

echo "Docker build successful"

echo "Running Baltimore Scraper in Docker..."
if [ -z "$OUTPUT_FORMAT" ]; then
  docker run baltimore-scraper
else
  mkdir -p output
  docker run -v $(pwd)/output:/app/output baltimore-scraper --output=$OUTPUT_FORMAT
fi
