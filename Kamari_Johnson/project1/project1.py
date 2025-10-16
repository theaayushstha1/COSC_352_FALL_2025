import urllib.request
import urllib.parse
import html.parser
import csv
import sys
import os

# Imports the base HTMLParser class
from html.parser import HTMLParser

# Creates a subclass of HTMLParser to extract tables
class TableSpelunker(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False       # Flag to track if we're inside a <table>
        self.in_row = False         # Flag to track if we're inside a <tr>
        self.in_cell = False        # Flag to track if we're inside a <td> or <th>
        self.current_cell = ''      # Storage for cell content
        self.current_row = []       # List to hold all cells in the current row
        self.current_table = []     # List to hold all rows in the current table
        self.tables = []            # List to hold all tables found

    # Detects when a tag starts
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

    # Detects when a tag ends and saves its content
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

    # Collects text inside a cell
    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

# Retrieves the URL from the command line
url = sys.argv[1]

# Creates a request with a user-agent header to avoid being blocked
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read().decode('utf-8')

# Check if the HTML contains <table> tags
print('Checking for <table> tags in raw HTML...')
print("<table" in html)

# Extract a base name from the URL for saving files
base_name = urllib.parse.urlparse(url).path.split('/')[-1] or 'page'

# Save the raw HTML to a file
with open(f'{base_name}.html', 'w', encoding='utf-8') as f:
    f.write(html)
print(f'Saved: {base_name}.html')

# Create an instance of your custom parser
parser = TableSpelunker()

# Feed the HTML content to the parser
parser.feed(html)
parser.close()  # Ensures parser finishes processing

# Print total tables found
print(f"Total tables found: {len(parser.tables)}")

# Loop through each extracted table and save it as a CSV
for i, table in enumerate(parser.tables, 1):
    filename = f'{base_name}_{i}.csv'
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        for row in table:
            writer.writerow(row)
    print(f'Saved: {filename} ({len(table)} rows x {len(table[0]) if table else 0} cols)')