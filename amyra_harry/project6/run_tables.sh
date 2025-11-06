#!/bin/bash

IMAGE_NAME="baltimore-homicide-analysis"
CONTAINER_NAME="baltimore-analysis-container"

# Default output format
OUTPUT_FORMAT="stdout"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output=*)
            OUTPUT_FORMAT="${1#*=}"
            shift
            ;;
        --output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --rebuild)
            echo "Forcing image rebuild..."
            docker rmi -f $IMAGE_NAME 2>/dev/null
            shift
            ;;
        --help|-h)
            echo "Usage: ./run.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --output=<format>    Output format: stdout, csv, json (default: stdout)"
            echo "  --rebuild            Force rebuild of Docker image"
            echo "  --help, -h           Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./run.sh [--output=<stdout|csv|json>] [--rebuild] [--help]"
            exit 1
            ;;
    esac
done

# Validate output format
if [[ ! "$OUTPUT_FORMAT" =~ ^(stdout|csv|json)$ ]]; then
    echo "Error: Invalid output format '$OUTPUT_FORMAT'"
    echo "Valid formats: stdout, csv, json"
    exit 1
fi

# Check if the Docker image exists
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Docker image not found. Building image..."
    docker build -t $IMAGE_NAME .
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to build Docker image"
        exit 1
    fi
    echo "✓ Image built successfully!"
else
    echo "✓ Docker image found. Using existing image..."
fi

# Remove any existing container with the same name
docker rm -f $CONTAINER_NAME 2>/dev/null

# Create output directory if needed
if [ "$OUTPUT_FORMAT" != "stdout" ]; then
    mkdir -p output
    echo "✓ Output directory ready: ./output"
fi

# Run the container with output format argument
echo ""
echo "Running analysis with output format: $OUTPUT_FORMAT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$OUTPUT_FORMAT" == "stdout" ]; then
    # For stdout, just run normally
    docker run --name $CONTAINER_NAME $IMAGE_NAME $OUTPUT_FORMAT
else
    # For csv/json, mount current directory and write output files
    docker run --name $CONTAINER_NAME \
        -v "$(pwd)/output:/app/output" \
        $IMAGE_NAME $OUTPUT_FORMAT
    
    # Check if files were created
    if [ $? -eq 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✓ Analysis complete! Files created in ./output directory:"
        ls -lh output/ | grep -E '\.(csv|json)$'
    else
        echo "✗ Error: Analysis failed"
        exit 1
    fi
fi

# Clean up the container after execution
docker rm $CONTAINER_NAME > /dev/null 2>&1

echo ""
echo "✓ Done!"