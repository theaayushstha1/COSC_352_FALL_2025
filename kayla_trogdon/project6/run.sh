#!/bin/bash

echo "==============================="
echo "Project 6: Scripting with GoLang"
echo "==============================="

IMAGE_NAME="go_baltimore_homicide_analysis"
CSV_FILE="chamspage_table1.csv"

#Parsing command line arguments
OUTPUT_FLAG=""
for arg in "$@"; do
    if [[ $arg == --output=* ]]; then
        OUTPUT_FLAG="$arg"
    fi
done

#Fetch CSV if it doesn't exist
if [ ! -f "$CSV_FILE" ]; then
    echo "Fetching data from website to generate CSV file ..."
    python3 fetch_csv.py
fi

#Verify CSV was created
if [ ! -f "$CSV_FILE" ]; then
    echo "❌ Error: CSV file was NOT created!"
    exit 1
fi 

echo "✅ CSV file found!" 

#Build Docker image if it doesn't exist
if [ "$FORCE_REBUILD" = true ]; then
    echo "🔨 Force rebuilding Docker image (no cache)..."
    docker build --no-cache -t "$IMAGE_NAME" .
elif ! docker image inspect "$IMAGE_NAME" > /dev/null 2>&1; then
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME" .
else
    echo "✅ Docker image exists (use --rebuild to force rebuild)"
fi

#Run Go analysis in Docker with output flags
echo "Running Go analysis in Docker ..." 

if [ -z "$OUTPUT_FLAG" ]; then
    # No output flag - default stdout behavior
    echo "Output: stdout (default)"
    docker run --rm "$IMAGE_NAME"
else
    # With output flag - mount volume to get output files
    echo "Output: $OUTPUT_FLAG"
    docker run --rm -v "$(pwd):/output" "$IMAGE_NAME" sh -c "/app/homicide_analysis $OUTPUT_FLAG && cp /app/*.csv /app/*.json /output 2>/dev/null || true"
fi

echo "" 
echo "=============================="
echo "✅ DONE!"
echo "=============================="