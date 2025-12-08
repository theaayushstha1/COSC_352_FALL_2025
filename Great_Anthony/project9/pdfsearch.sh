#!/bin/bash

# pdfsearch - Command-line PDF search tool
# Usage: ./pdfsearch.sh document.pdf "search query" N

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <pdf_file> <query> <num_results>"
    exit 1
fi

PDF_FILE="$1"
QUERY="$2"
NUM_RESULTS="$3"

# Validate inputs
if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file '$PDF_FILE' not found"
    exit 1
fi

if ! [[ "$NUM_RESULTS" =~ ^[0-9]+$ ]]; then
    echo "Error: num_results must be a positive integer"
    exit 1
fi

# Check dependencies
if ! command -v pdftotext &> /dev/null; then
    echo "Error: pdftotext not found. Install poppler-utils:"
    echo "  Ubuntu/Debian: sudo apt-get install poppler-utils"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Extract text from PDF with page information
echo "Extracting text from PDF..."
pdftotext -layout "$PDF_FILE" "$TEMP_DIR/extracted_text.txt"

# Check if extraction was successful
if [ ! -s "$TEMP_DIR/extracted_text.txt" ]; then
    echo "Error: Failed to extract text from PDF or PDF is empty"
    exit 1
fi

# Call Python search engine with extracted text
python3 search_engine.py "$TEMP_DIR/extracted_text.txt" "$QUERY" "$NUM_RESULTS"
