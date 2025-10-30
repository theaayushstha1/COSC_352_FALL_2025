#!/bin/bash

echo "======================================"
echo "  Baltimore Homicide Analysis"
echo "======================================"
echo ""

# Parse command line argument
OUTPUT_FORMAT=""
if [ "$1" = "--output=csv" ]; then
    OUTPUT_FORMAT="csv"
elif [ "$1" = "--output=json" ]; then
    OUTPUT_FORMAT="json"
fi

DOCKER_IMAGE="rohan_homicide_project5"

# Check if Docker image exists, build if not
if ! docker images | grep -q "$DOCKER_IMAGE"; then
    echo "Building Docker image..."
    docker build -t "$DOCKER_IMAGE" .
    echo ""
fi

# Run the analysis
if [ -z "$OUTPUT_FORMAT" ]; then
    # Default: stdout
    echo "Running analysis (stdout format)..."
    docker run --rm "$DOCKER_IMAGE"
else
    # CSV or JSON: need to mount volume to get output files
    echo "Running analysis ($OUTPUT_FORMAT format)..."
    docker run --rm -v "$(pwd):/app" -w /app "$DOCKER_IMAGE" sh -c "scalac HomicideAnalysis.scala && scala HomicideAnalysis $OUTPUT_FORMAT"
    
    # Check if output file was created
    if [ -f "output.$OUTPUT_FORMAT" ]; then
        echo ""
        echo "✓ Output file created: output.$OUTPUT_FORMAT"
        echo ""
        echo "File contents:"
        cat "output.$OUTPUT_FORMAT"
    else
        echo "Warning: output.$OUTPUT_FORMAT was not created"
    fi
fi
