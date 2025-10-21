#!/bin/bash

CSV_DIR="csv_output"
IMAGE_NAME="project2-html-table-extractor"

mkdir -p "$CSV_DIR"

IFS=',' read -ra URLS <<< "$1"
for url in "${URLS[@]}"; do
    echo "🌐 Processing $url..."

    # If it's a local file, use it directly
    if [[ "$url" == *.html && -f "$url" ]]; then
        html_file="$(pwd)/$url"
        SAFE_NAME=$(basename "$url" .html)
    else
        # Sanitize URL into a safe filename
        SAFE_NAME=$(echo "$url" | sed 's|https\?://||g' | sed 's|[/.]|_|g')
        html_file="${SAFE_NAME}.html"
        curl -s "$url" -o "$html_file"
        html_file="$(pwd)/$html_file"
    fi

    output_csv="${SAFE_NAME}_table1.csv"

    docker run --rm -v "$(pwd):/data" "$IMAGE_NAME" "/data/$(basename "$html_file")" "/data/$CSV_DIR/$output_csv"
done

echo "✅ All done! Tables saved to $CSV_DIR"
