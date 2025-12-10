#!/bin/bash

# Project 9 - PDF Search Tool Runner
# Usage: ./run.sh <pdf_file> <query> <num_results>

# Check if required arguments are provided
if [ $# -lt 3 ]; then
    echo "Usage: ./run.sh <pdf_file> <query> <num_results>"
    echo "Example: ./run.sh document.pdf \"gradient descent\" 3"
    exit 1
fi

PDF_FILE=$1
QUERY=$2
NUM_RESULTS=$3

# Check if Mojo is installed
if ! command -v mojo &> /dev/null; then
    echo "Error: Mojo is not installed or not in PATH"
    echo "Please install Mojo from: https://docs.modular.com/mojo/"
    exit 1
fi

# Check if pypdf is installed
if ! python3 -c "import pypdf" 2>/dev/null; then
    echo "Error: pypdf is not installed"
    echo "Installing pypdf..."
    pip3 install pypdf
fi

# Check if PDF file exists
if [ ! -f "$PDF_FILE" ]; then
    echo "Error: PDF file '$PDF_FILE' not found"
    exit 1
fi

# Run the Mojo program
echo "Running PDF search..."
mojo pdfsearch.mojo "$PDF_FILE" "$QUERY" "$NUM_RESULTS"