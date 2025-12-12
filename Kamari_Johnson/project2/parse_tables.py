import urllib.request
import urllib.parse
import html.parser
import csv
import sys
import os

from html.parser import HTMLParser

class TableSpelunker(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_cell = ''
        self.current_row = []
        self.current_table = []
        self.tables = []

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.in_table = True
            self.current_table = []
        elif tag == 'tr' and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ('td', 'th') and self.in_row:
            self.in_cell = True
            self.current_cell = ''

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())
        elif tag == 'tr' and self.in_row:
            self.in_row = False
            self.current_table.append(self.current_row)
        elif tag == 'table' and self.in_table:
            self.in_table = False
            self.tables.append(self.current_table)
            print(f"Table captured with {len(self.current_table)} rows")

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

def is_url(path):
    return path.startswith("http://") or path.startswith("https://")

# Get input path or URL and output folder
input_path = sys.argv[1]
output_dir = sys.argv[2]

# Load HTML content
if is_url(input_path):
    req = urllib.request.Request(input_path, headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(req).read().decode('utf-8')
    base_name = urllib.parse.urlparse(input_path).path.split('/')[-1] or 'page'
else:
    with open(input_path, 'r', encoding='utf-8') as f:
        html = f.read()
    base_name = os.path.splitext(os.path.basename(input_path))[0]

# Check for <table> tags
print('Checking for <table> tags in raw HTML...')
print("<table" in html)

# Save raw HTML (optional)
with open(os.path.join(output_dir, f'{base_name}.html'), 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Saved: {base_name}.html')

# Parse tables
parser = TableSpelunker()
parser.feed(html)
parser.close()

print(f"Total tables found: {len(parser.tables)}")

# Save each table as CSV
for i, table in enumerate(parser.tables, 1):
    filename = os.path.join(output_dir, f'{base_name}_{i}.csv')
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        for row in table:
            writer.writerow(row)
    print(f'Saved: {filename} ({len(table)} rows x {len(table[0]) if table else 0} cols)')