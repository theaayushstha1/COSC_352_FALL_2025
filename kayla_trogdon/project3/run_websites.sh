#!/bin/bash 

mkdir -p website_tables
#List of wesbites
websites=(
    "https://en.wikipedia.org/wiki/Programming_languages_used_in_most_popular_websites"
    "https://www.tiobe.com/tiobe-index/"
    "https://github.com/quambene/pl-comparison"
)
for url in "${websites[@]}"
do
    echo "Processing $url" 
    docker run -v "$(pwd)/website_tables:/app/website_tables" project3_docker python project_3.py "$url"
done

echo ""
echo "ALL URLS processed! Check the website_tables"