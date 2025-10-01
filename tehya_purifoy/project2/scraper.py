import sys
import pandas as pd
import urllib.request
from urllib.parse import urlparse
import os

# Check if URL was provided
if len(sys.argv) != 2:
    print("Usage: docker run <image_name> <URL>")
    sys.exit(1)

# Get URL from command line
url = sys.argv[1]

try:
    # Get the page
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
    html = urllib.request.urlopen(req).read().decode('utf-8')

    # Get base filename from URL
    base_name = urlparse(url).path.split('/')[-1].replace('.html', '').replace('.htm', '') or 'page'
    
    # Ensure output directory exists
    output_dir = '/app/output'
    os.makedirs(output_dir, exist_ok=True)

    # Save HTML
    html_path = os.path.join(output_dir, f'{base_name}.html')
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f'Saved: {base_name}.html')

    # Extract and save tables
    try:
        tables = pd.read_html(html)
        for i, table in enumerate(tables, 1):
            filename = f'{base_name}_table_{i}.csv'
            csv_path = os.path.join(output_dir, filename)
            table.to_csv(csv_path, index=False)
            print(f'Saved: {filename} ({table.shape[0]} rows x {table.shape[1]} cols)')
        
        if not tables:
            print("No tables found on the page")
    except ValueError as e:
        print(f"No tables could be parsed: {e}")

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
