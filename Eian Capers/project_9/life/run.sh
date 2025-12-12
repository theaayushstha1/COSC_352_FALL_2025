#!/bin/bash
set -e

echo "========================================="
echo "   PDF Search Tool - Mojo + Python      "
echo "========================================="

# Function to extract passages
extract_passages() {
    echo "Extracting passages from PDF..."
    pixi run pip install PyPDF2 > /dev/null 2>&1 || true
    pixi run python src/extract_pdf.py \
        data/Morgan_2030.pdf \
        data/passages.json \
        data/passages.txt
    echo "✓ Extraction complete"
}

# Function to run search (Python fallback)
run_search() {
    local query="$1"
    local top_n="${2:-5}"

    echo "Running search (Python fallback)..."
    echo "Query: \"$query\""
    pixi run python src/search_fallback.py data/passages.txt "$query" "$top_n"
}

# Main command handling
case "${1:-help}" in
    extract)
        extract_passages
        ;;

    search)
        if [ -z "$2" ]; then
            echo "Error: Query required"
            echo "Usage: ./run.sh search \"your query\" [top_n]"
            exit 1
        fi

        if [ ! -f "data/passages.txt" ]; then
            echo "Passages not found. Extracting first..."
            extract_passages
        fi

        run_search "$2" "${3:-5}"
        ;;

    full)
        extract_passages
        query="${2:-research university}"
        top_n="${3:-5}"
        run_search "$query" "$top_n"
        ;;

    test)
        echo "Running tests..."
        pixi run mojo tests/test_mini_tfidf.mojo
        ;;

    clean)
        echo "Cleaning generated files..."
        rm -f data/passages.json data/passages.txt
        echo "✓ Clean complete"
        ;;

    help|*)
        echo "Usage: ./run.sh <command>"
        echo ""
        echo "Commands:"
        echo "  extract                  - Extract passages from PDF"
        echo "  search \"query\" [N]      - Search for query (top N results)"
        echo "  full [\"query\"] [N]      - Run full pipeline"
        echo "  test                     - Run tests"
        echo "  clean                    - Remove generated files"
        echo "  help                     - Show this help"
        ;;
esac