#!/bin/bash

# Parse command line arguments
OUTPUT_FORMAT="stdout"

for arg in "$@"; do
  case $arg in
    --output=*)
      OUTPUT_FORMAT="${arg#*=}"
      shift
      ;;
    *)
      OUTPUT_FORMAT="$arg"
      ;;
  esac
done

# Run the Docker container
echo "Running Baltimore Homicide Analysis with output format: $OUTPUT_FORMAT"

if [ "$OUTPUT_FORMAT" == "csv" ] || [ "$OUTPUT_FORMAT" == "json" ]; then
    # Run container, copy output file, then clean up
    CONTAINER_NAME="homicide-analysis-$$"
    docker run --name "$CONTAINER_NAME" homicide-analysis "$OUTPUT_FORMAT"
    
    if [ "$OUTPUT_FORMAT" == "csv" ]; then
        docker cp "$CONTAINER_NAME:/app/output.csv" .
        echo "Output file copied to: output.csv"
    else
        docker cp "$CONTAINER_NAME:/app/output.json" .
        echo "Output file copied to: output.json"
    fi
    
    docker rm "$CONTAINER_NAME" > /dev/null
else
    # Just run and show output
    docker run --rm homicide-analysis "$OUTPUT_FORMAT"
fi
