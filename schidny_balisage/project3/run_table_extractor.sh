#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 'url1,url2,url3'"
    exit 1
fi

OUTPUT_DIR="extracted_tables_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

if ! docker image inspect table-extractor &> /dev/null; then
    cd ../project2
    docker build -t table-extractor .
    cd ../project3
fi

IFS=',' read -ra URLS <<< "$1"

for url in "${URLS[@]}"; do
    url=$(echo "$url" | xargs)
    domain=$(echo "$url" | awk -F[/:] '{print $4}' | sed 's/www\.//g' | tr '.' '_')
    
    temp_dir="${OUTPUT_DIR}/${domain}_temp"
    mkdir -p "$temp_dir"
    
    docker run --rm -v "$(pwd)/${temp_dir}:/app/output" table-extractor "$url"
    
    for file in "${temp_dir}"/table_*.csv; do
        if [ -f "$file" ]; then
            mv "$file" "${OUTPUT_DIR}/${domain}_$(basename $file)"
        fi
    done
    
    rmdir "$temp_dir" 2>/dev/null
done

zip -r "${OUTPUT_DIR}.zip" "$OUTPUT_DIR"
echo "Done! Files: ${OUTPUT_DIR}.zip"
