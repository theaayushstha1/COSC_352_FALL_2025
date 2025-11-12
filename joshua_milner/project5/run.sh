#!/bin/bash

# builds docker, if needed, and runs Baltimore Homicide Analysis

set -e  # Exit on any error

# color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# configuration
IMAGE_NAME="baltimore-homicide-analysis"
OUTPUT_FORMAT="stdout"

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Baltimore Homicide Analysis System${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

while [[ $# -gt 0 ]]; do
    case $1 in
        --output=*)
            OUTPUT_FORMAT="${1#*=}"
            shift
            ;;
        --help|-h)
            echo "Usage: ./run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --output=FORMAT    Specify output format (stdout, csv, json)"
            echo "                     Default: stdout"
            echo ""
            echo "Examples:"
            echo "  ./run.sh                    # Output to terminal"
            echo "  ./run.sh --output=csv       # Save as CSV file"
            echo "  ./run.sh --output=json      # Save as JSON file"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(stdout|csv|json)$ ]]; then
    echo -e "${RED}ERROR: Invalid output format '$OUTPUT_FORMAT'${NC}"
    echo "Valid formats: stdout, csv, json"
    exit 1
fi

echo -e "${YELLOW}Output format: $OUTPUT_FORMAT${NC}"
echo ""

# check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: Docker is not installed${NC}"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}ERROR: Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# check if image exists
echo -e "${YELLOW}Checking for Docker image...${NC}"
if docker images | grep -q "$IMAGE_NAME"; then
    echo -e "${GREEN}Docker image '$IMAGE_NAME' found${NC}"
else
    echo -e "${YELLOW}Docker image '$IMAGE_NAME' not found. Building now...${NC}"
    
    # build the Docker image
    if docker build -t "$IMAGE_NAME" .; then
        echo -e "${GREEN}Docker image built successfully!${NC}"
    else
        echo -e "${RED}ERROR: Failed to build Docker image${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}Running analysis...${NC}"
echo ""

# Create output directory
mkdir -p output

# Run container with output format parameter
if [ "$OUTPUT_FORMAT" = "stdout" ]; then
    # Standard output to terminal
    docker run --rm "$IMAGE_NAME" "$OUTPUT_FORMAT"
else
    # Write to file in mounted volume
    docker run --rm \
        -v "$(pwd)/output:/app/output" \
        "$IMAGE_NAME" "$OUTPUT_FORMAT"
    
    # Check if file was created
    if [ "$OUTPUT_FORMAT" = "csv" ] && [ -f "output/analysis_results.csv" ]; then
        echo ""
        echo -e "${GREEN}=====================================${NC}"
        echo -e "${GREEN}✓ CSV file created successfully${NC}"
        echo -e "${GREEN}=====================================${NC}"
        echo "Location: $(pwd)/output/analysis_results.csv"
        echo "Size: $(du -h output/analysis_results.csv | cut -f1)"
        echo ""
        echo "Preview (first 5 lines):"
        head -5 output/analysis_results.csv
    elif [ "$OUTPUT_FORMAT" = "json" ] && [ -f "output/analysis_results.json" ]; then
        echo ""
        echo -e "${GREEN}=====================================${NC}"
        echo -e "${GREEN}✓ JSON file created successfully${NC}"
        echo -e "${GREEN}=====================================${NC}"
        echo "Location: $(pwd)/output/analysis_results.json"
        echo "Size: $(du -h output/analysis_results.json | cut -f1)"
        echo ""
        echo "Preview:"
        head -20 output/analysis_results.json
    else
        echo -e "${RED}ERROR: Output file was not created${NC}"
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Analysis Complete!${NC}"
echo -e "${GREEN}=====================================${NC}" 