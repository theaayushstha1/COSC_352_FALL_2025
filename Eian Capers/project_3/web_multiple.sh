#!/bin/bash

# Simple Docker Web Scraper
# Simple Docker Web Scraper using existing Dockerfil
websites=(
    "https://pypl.github.io/PYPL.html"
    "https://github.com/quambene/pl-comparison"
    "https://www.reddit.com/r/rust/comments/uq6j2q/programming_language_comparison_cheat_sheet/"
)

echo "Building Docker image..."
docker build -t web-scraper .

mkdir -p scraped_output

site_num=1
for url in "${websites[@]}"
do
    echo "Processing $url"
    mkdir -p "scraped_output/site_${site_num}"
    docker run --rm \
        -v "$(pwd)/scraped_output/site_${site_num}:/app/output" \
        -e TARGET_URL="$url" \
        web-scraper
    site_num=$((site_num+1))
done

echo "Done! Check scraped_output/ folder"
