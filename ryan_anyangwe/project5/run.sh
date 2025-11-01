#!/bin/bash

# Project 5: Baltimore Homicide Analysis with Multiple Output Formats
# This script builds and runs the Scala application in a Docker container
# Usage: ./run.sh [--output=csv|json]

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-run"
OUTPUT_FORMAT=""

echo "=================================================="
echo "Baltimore City Homicide Analysis - Project 5"
echo "=================================================="
echo ""

# Parse command line arguments
for arg in "$@"; do
  case $arg in
    --output=csv)
      OUTPUT_FORMAT="csv"
      shift
      ;;
    --output=json)
      OUTPUT_FORMAT="json"
      shift
      ;;
    --output=*)
      echo "ERROR: Unknown output format. Valid options: csv, json"
      echo "Usage: ./run.sh [--output=csv|json]"
      exit 1
      ;;
    *)
      # Unknown option
      echo "ERROR: Unknown argument: $arg"
      echo "Usage: ./run.sh [--output=csv|json]"
      exit 1
      ;;
  esac
done

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    echo "Please install Docker and try again"
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    echo "Please start Docker and try again"
    exit 1
fi

echo "Checking for existing Docker image..."

# Check if image exists
if docker image inspect $IMAGE_NAME &> /dev/null; then
    echo "✓ Docker image '$IMAGE_NAME' found"
else
    echo "✗ Docker image '$IMAGE_NAME' not found"
    echo ""
    echo "Building Docker image (this may take a few minutes)..."
    
    # Build the Docker image
    if docker build -t $IMAGE_NAME .; then
        echo "✓ Docker image built successfully"
    else
        echo "ERROR: Failed to build Docker image"
        exit 1
    fi
fi

echo ""

# Display output mode
if [ -z "$OUTPUT_FORMAT" ]; then
    echo "Output mode: STDOUT (default)"
    echo "Use --output=csv or --output=json for file output"
else
    echo "Output mode: $OUTPUT_FORMAT"
fi

echo ""
echo "Running Baltimore Homicide Analysis..."
echo ""
echo "=================================================="
echo ""

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME &> /dev/null

# Run the container
if [ -z "$OUTPUT_FORMAT" ]; then
    # No output format specified - run without arguments (stdout)
    docker run --rm --name $CONTAINER_NAME $IMAGE_NAME
else
    # Output format specified - run with argument and mount volume to get output files
    docker run --rm --name $CONTAINER_NAME \
        -v "$(pwd)":/output \
        -w /output \
        $IMAGE_NAME \
        scala -cp /app BaltimoreHomicideAnalysis $OUTPUT_FORMAT
fi

echo ""
echo "=================================================="
echo "Analysis complete!"

# Show output files if they were created
if [ "$OUTPUT_FORMAT" = "csv" ]; then
    echo ""
    echo "CSV files created:"
    if [ -f "district_analysis.csv" ]; then
        echo "  ✓ district_analysis.csv ($(wc -l < district_analysis.csv) lines)"
    fi
    if [ -f "temporal_analysis.csv" ]; then
        echo "  ✓ temporal_analysis.csv ($(wc -l < temporal_analysis.csv) lines)"
    fi
elif [ "$OUTPUT_FORMAT" = "json" ]; then
    echo ""
    echo "JSON file created:"
    if [ -f "analysis_results.json" ]; then
        echo "  ✓ analysis_results.json ($(wc -l < analysis_results.json) lines)"
    fi
fi

echo "=================================================="
