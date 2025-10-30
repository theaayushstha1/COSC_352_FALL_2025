#!/bin/bash

# run.sh - Crime Data Analysis Runner
# Supports output formats: stdout (default), csv, json
# Usage: 
#   ./run.sh                  # Default stdout output
#   ./run.sh --output=csv     # Output to CSV file
#   ./run.sh --output=json    # Output to JSON file

set -e

echo "================================"
echo "Crime Data Analysis Tool"
echo "================================"
echo ""

# Parse command line arguments
OUTPUT_FORMAT="stdout"
for arg in "$@"; do
  if [[ $arg == --output=* ]]; then
    OUTPUT_FORMAT="${arg#*=}"
  fi
done

echo "Output format: $OUTPUT_FORMAT"
echo ""

# Create output directory if needed
if [ "$OUTPUT_FORMAT" != "stdout" ]; then
  mkdir -p output
fi

# Check if compiled classes exist
if [ ! -d "target/scala-2.13/classes" ]; then
  echo "Compiled classes not found. Please run build.sh first."
  exit 1
fi

# Check if data file exists
if [ ! -f "data/crimes.csv" ]; then
  echo "Error: data/crimes.csv not found"
  echo "Please ensure your crime data CSV is in the data/ directory"
  exit 1
fi

# Run the application with output format parameter
echo "Running analysis..."
echo ""

scala -cp "target/scala-2.13/classes" CrimeDataApp "$@"

echo ""
echo "================================"
echo "Analysis Complete"
echo "================================"
