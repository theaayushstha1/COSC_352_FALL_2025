#!/usr/bin/env python3

import sys
import pandas as pd
import urllib.request
from urllib.parse import urlparse

# Get URL from command line
url = sys.argv[1]

# Get the page
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
html = urllib.request.urlopen(req).read().decode('utf-8')

# Get base filename from URL
base_name = urlparse(url).path.split('/')[-1].replace('.html', '').replace('.htm', '') or 'page'

# Save HTML
with open(f'{base_name}.html', 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Saved: {base_name}.html')

# Extract and save tables
tables = pd.read_html(html)
for i, table in enumerate(tables, 1):
    filename = f'{base_name}_{i}.csv'
    table.to_csv(filename, index=False)
    print(f'Saved: {filename} ({table.shape[0]} rows x {table.shape[1]} cols)')