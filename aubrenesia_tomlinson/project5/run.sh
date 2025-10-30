#!/bin/bash

OUTPUT_FORMAT=""

# Parse output flag
if [ "$1" = "--output=csv" ]; then
    OUTPUT_FORMAT="csv"
elif [ "$1" = "--output=json" ]; then
    OUTPUT_FORMAT="json"
fi

# Check for image 
IMAGE_NAME="bmore-homicide-stats"
docker images | grep -q "$IMAGE_NAME"

# Build image if it doesn't exist
if [ $? -ne 0 ]; then
  echo "Building image..."
  docker build -t "$IMAGE_NAME" .
fi

# Prepare argument to pass to Scala
RUN_ARGS=""
if [ -n "$OUTPUT_FORMAT" ]; then
    RUN_ARGS="--output=$OUTPUT_FORMAT"
fi

# Run the analysis
if [ -z "$OUTPUT_FORMAT" ]; then
    echo "Running analysis (stdout format)..."
    docker run --rm -v "$(pwd)":/app -w /app "$IMAGE_NAME" \
        sbt -batch -Dsbt.supershell=false -Dsbt.log.noformat=true \
        "runMain BmoreHomicideStats"
else
    echo "Running analysis ($OUTPUT_FORMAT format)..."
    docker run --rm -v "$(pwd)":/app -w /app "$IMAGE_NAME" \
        sbt -batch -Dsbt.supershell=false -Dsbt.log.noformat=true \
        "runMain BmoreHomicideStats $RUN_ARGS"
fi

# Optionally show file contents if output format was specified
if [ -n "$OUTPUT_FORMAT" ]; then
    OUTPUT_FILE="BmoreHomicideStats.$OUTPUT_FORMAT"
    echo "File contents ($OUTPUT_FILE):"
    cat "$OUTPUT_FILE"
fi
