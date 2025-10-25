#!/bin/bash

# Script to run Baltimore Crime Analysis with optional output format
# Usage: 
#   ./run.sh              (outputs to stdout)
#   ./run.sh --output=csv (outputs to CSV file)
#   ./run.sh --output=json (outputs to JSON file)

# Default output format is stdout
OUTPUT_ARG=""

# Parse command line arguments
for arg in "$@"
do
    case $arg in
        --output=*)
            OUTPUT_ARG="$arg"
            shift
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: ./run.sh [--output=csv|json]"
            exit 1
            ;;
    esac
done

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t baltimore-analysis .

if [ $? -ne 0 ]; then
    echo "Error: Docker build failed"
    exit 1
fi

# Run the Docker container with the appropriate argument
echo "Running analysis..."
if [ -z "$OUTPUT_ARG" ]; then
    # No output argument, run with default (stdout)
    docker run --rm baltimore-analysis
else
    # Output argument provided, pass it to Spark and copy output files back
    OUTPUT_FORMAT="${OUTPUT_ARG#*=}"
    
    # Run container and copy output file
    CONTAINER_ID=$(docker run -d baltimore-analysis $OUTPUT_ARG)
    
    # Wait for container to finish
    docker wait $CONTAINER_ID > /dev/null
    
    # Copy the output file from container to host
    if [ "$OUTPUT_FORMAT" = "csv" ]; then
        docker cp $CONTAINER_ID:/app/baltimore_crime_stats.csv .
        echo "Output file created: baltimore_crime_stats.csv"
    elif [ "$OUTPUT_FORMAT" = "json" ]; then
        docker cp $CONTAINER_ID:/app/baltimore_crime_stats.json .
        echo "Output file created: baltimore_crime_stats.json"
    fi
    
    # Show logs
    docker logs $CONTAINER_ID
    
    # Clean up container
    docker rm $CONTAINER_ID > /dev/null
fi

echo "Analysis complete!"
