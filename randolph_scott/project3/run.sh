FROM python:3.10-slim

RUN pip install pandas beautifulsoup4 lxml

WORKDIR /app

COPY extract_tables.py .

ENTRYPOINT ["python", "extract_tables.py"]

import sys
import os
import pandas as pd
from bs4 import BeautifulSoup

def extract_tables(html_path, output_dir):
    with open(html_path, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'lxml')

    tables = soup.find_all('table')

    if not tables:
        print(f"No tables found in {html_path}")
        return

    os.makedirs(output_dir, exist_ok=True)

    for i, table in enumerate(tables):
        try:
            df = pd.read_html(str(table))[0]
            out_path = os.path.join(output_dir, f'table{i+1}.csv')
            df.to_csv(out_path, index=False)
            print(f"Saved: {out_path}")
        except Exception as e:
            print(f"Skipping table {i+1}: {e}")

if __name__ == '__main__':
    html_file = sys.argv[1]
    output_dir = sys.argv[2]
    extract_tables(html_file, output_dir)

    #!/bin/bash

# === Config ===
OUTPUT_DIR="csv_output"
ZIP_FILE="tables_output.zip"

# Create output folder
rm -rf "$OUTPUT_DIR" "$ZIP_FILE"
mkdir -p "$OUTPUT_DIR"

# Get URLs (comma-separated)
IFS=',' read -ra URLS <<< "$1"

for URL in "${URLS[@]}"; do
  echo "Processing: $URL"

  # Generate safe filename
  NAME=$(echo "$URL" | sed 's_https\?://__' | sed 's/[^a-zA-Z0-9]/_/g')
  HTML_FILE="${NAME}.html"

  # Download the HTML
  curl -sL "$URL" -o "$HTML_FILE"

  # Output folder for this site
  SITE_DIR="${OUTPUT_DIR}/${NAME}"
  mkdir -p "$SITE_DIR"

  # Run Docker to extract tables
  docker run --rm -v "$PWD:/data" table-extractor "/data/$HTML_FILE" 
"/data/$SITE_DIR"
done

# Create a zip file
zip -r "$ZIP_FILE" "$OUTPUT_DIR"

echo "✅ Done! All tables are saved in $ZIP_FILE"
