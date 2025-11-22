#!/bin/bash

IMAGE_NAME="baltimore-homicide-fp"
CONTAINER_NAME="baltimore-fp-analysis"

echo "========================================================"
echo "Baltimore Homicide Functional Analysis (Clojure)"
echo "========================================================"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon not running"
    exit 1
fi

# Check CSV
if [ ! -f "baltimore_homicides_combined.csv" ]; then
    echo "ERROR: baltimore_homicides_combined.csv not found"
    echo ""
    echo "Please download from:"
    echo "https://github.com/professor-jon-white/COSC_352_FALL_2025/blob/main/professor_jon_white/func_prog/baltimore_homicides_combined.csv"
    echo ""
    echo "Or generate sample data:"
    echo "./generate_sample_data.sh"
    exit 1
fi

# Build if needed
if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
    echo "Building Docker image..."
    docker build -t $IMAGE_NAME .
    if [ $? -ne 0 ]; then
        echo "ERROR: Build failed"
        exit 1
    fi
    echo "Build successful!"
    echo ""
fi

# Run
echo "Running analysis..."
echo ""
docker run --rm \
    -v "$(pwd)/baltimore_homicides_combined.csv:/app/baltimore_homicides_combined.csv:ro" \
    $IMAGE_NAME

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================================"
    echo "Analysis complete!"
    echo "========================================================"
else
    echo "ERROR: Analysis failed"
    exit 1
fi
