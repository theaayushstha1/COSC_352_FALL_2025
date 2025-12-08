#!/bin/bash
# TF-IDF PDF Search Engine for Project 9
# Similar to Project 8's run.sh - orchestrates the workflow
# Usage: ./run.sh "<query>" <top_n>
# Example: ./run.sh "research excellence" 5

echo ""
echo "============================================================"
echo "Project 9: TF-IDF PDF Search Engine"
echo "============================================================"
echo ""

# Check if passages.json exists
if [ ! -f "data/passages.json" ]; then
    echo "⚠️  data/passages.json not found. Running PDF extraction first..."
    echo ""
    pixi run python src/extract_pdf.py
    echo ""
    echo "============================================================"
    echo ""
fi

# Check arguments
if [ $# -eq 0 ]; then
    echo "Usage: ./run.sh \"<query>\" <top_n>"
    echo ""
    echo "Examples:"
    echo "  ./run.sh \"research excellence\" 5"
    echo "  ./run.sh \"student leadership\" 10"
    echo ""
    exit 1
fi

# Get arguments
QUERY="$1"
TOP_N="${2:-5}"  # Default to 5 if not provided

# Run search using Python backend
pixi run python src/extract_pdf.py search "$QUERY" "$TOP_N"