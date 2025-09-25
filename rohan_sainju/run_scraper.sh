#!/bin/bash

# Check if a comma-separated list of URLs was provided
if [ -z "$1" ]; then
  echo "Usage: ./run_scraper.sh <url1,url2,url3>"
  exit 1
fi

# Set the Input Field Separator to a comma
IFS=','
read -r -a url_array <<< "$1"

# Loop through each URL in the array
for url in "${url_array[@]}"; do
  echo "Processing URL: $url"

  # Generate a clean filename from the URL
  filename=$(echo "$url" | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's/\./_/g')
  output_file="${filename}.csv"

  # Run the Docker container, passing the URL as an argument
  docker run your_username_project2 "$url" > "$output_file"

  echo "Saved data to: $output_file"
  echo "-------------------------------------"
done