#!/bin/bash

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Baltimore Homicide Analysis - Project 5 ===${NC}"

# Parse command line arguments
OUTPUT_FORMAT="stdout"

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

# Validate output format
if [[ "$OUTPUT_FORMAT" != "stdout" && "$OUTPUT_FORMAT" != "csv" && "$OUTPUT_FORMAT" != "json" ]]; then
  echo "Error: Invalid output format '$OUTPUT_FORMAT'"
  echo "Valid formats: stdout, csv, json"
  exit 1
fi

if ! docker ps > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

IMAGE_NAME="homicide-analysis"
TAG="latest"

if ! docker image inspect "${IMAGE_NAME}:${TAG}" > /dev/null 2>&1; then
    echo -e "${BLUE}Building Docker image...${NC}"
    docker build -t "${IMAGE_NAME}:${TAG}" .
    echo -e "${GREEN}Docker image built successfully!${NC}"
else
    echo -e "${GREEN}Docker image found.${NC}"
fi

echo -e "${BLUE}Executing analysis with output format: $OUTPUT_FORMAT${NC}\n"

# Run with volume mount to save output files
docker run --rm \
  -v "$(pwd)/output:/app/output" \
  "${IMAGE_NAME}:${TAG}" \
  sbt "run $OUTPUT_FORMAT"

# If CSV or JSON, show the generated file
if [ "$OUTPUT_FORMAT" = "csv" ]; then
  echo -e "\n${GREEN}CSV file generated: output/homicide_analysis.csv${NC}"
  if [ -f "output/homicide_analysis.csv" ]; then
    echo "First 10 lines:"
    head -n 10 output/homicide_analysis.csv
  fi
elif [ "$OUTPUT_FORMAT" = "json" ]; then
  echo -e "\n${GREEN}JSON file generated: output/homicide_analysis.json${NC}"
  if [ -f "output/homicide_analysis.json" ]; then
    echo "File size: $(wc -c < output/homicide_analysis.json) bytes"
  fi
fi

echo -e "\n${GREEN}Analysis complete!${NC}"
