# project1.py
# This program reads HTML from a URL or local file, parses all tables found,
# saves the HTML to disk (if from URL), and saves each table's contents as separate
# CSV files named <base>_<i>.csv, where <base> is derived from the URL or filename.
#
# It uses only standard Python libraries: sys, urllib.request, html.parser, csv, os, urllib.parse.
# The parser is basic and handles simple tables with <tr>, <td>, <th>. It treats <th>
# similarly to <td> and includes them in rows. It does not handle colspan, rowspan,
# nested tables (nested content may appear in cells), or complex formatting like <br>
# (data may concatenate without spaces).
#
# It is general and works on any HTML with tables, extracting all of them.
#
# Instructions to run:
# 1. Save this file as project1.py
# 2. Run: python project1.py <URL or FILENAME>
#    - If URL (starts with http/https), fetches from web and saves <base>.html.
#    - If FILENAME, reads from local disk (does not save a copy of HTML).
# 3. Output: Saves <base>_<i>.csv for each table i, and <base>.html if from URL.
import sys
import urllib.request
from urllib.parse import urlparse
from html.parser import HTMLParser
import csv
import os

class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.tables = []  # List of tables, each a list of rows
        self.current_table = None
        self.in_tr = False
        self.in_cell = False
        self.current_row = []
        self.cell_data = ''

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag == 'table':
            if self.current_table is None:
                self.current_table = []
        elif tag == 'tr' and self.current_table is not None:
            self.in_tr = True
            self.current_row = []
        elif tag in ('td', 'th') and self.in_tr:
            self.in_cell = True
            self.cell_data = ''

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag == 'table':
            if self.current_table is not None:
                # Only add if it has rows
                if self.current_table:
                    self.tables.append(self.current_table)
                self.current_table = None
        elif tag == 'tr' and self.in_tr:
            self.in_tr = False
            if self.current_row:  # Skip empty rows
                self.current_table.append(self.current_row)
        elif tag in ('td', 'th') and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.cell_data.strip())

    def handle_data(self, data):
        if self.in_cell:
            self.cell_data += data

def get_base_name(source, is_url):
    if is_url:
        parsed = urlparse(source)
        path = parsed.path.strip('/')
        if not path:
            return parsed.netloc.replace('.', '_') or 'page'
        base = path.split('/')[-1]
        base = base.rsplit('.', 1)[0] if '.' in base else base
        return base or 'page'
    else:
        return os.path.splitext(os.path.basename(source))[0]

def main():
    if len(sys.argv) != 2:
        print("Usage: python project1.py <URL or FILENAME>", file=sys.stderr)
        sys.exit(1)

    source = sys.argv[1]
    is_url = source.startswith('http://') or source.startswith('https://')
    
    try:
        if is_url:
            req = urllib.request.Request(source, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'})
            with urllib.request.urlopen(req) as response:
                html = response.read().decode('utf-8')
        else:
            with open(source, 'r', encoding='utf-8') as f:
                html = f.read()
    except Exception as e:
        print(f"Error reading source: {e}", file=sys.stderr)
        sys.exit(1)

    base = get_base_name(source, is_url)
    
    # Save HTML if from URL
    if is_url:
        html_file = f"{base}.html"
        with open(html_file, 'w', encoding='utf-8') as f:
            f.write(html)
        print(f"Saved HTML: {html_file}")

    parser = TableParser()
    parser.feed(html)

    if not parser.tables:
        print("No tables found in the HTML.", file=sys.stderr)
        sys.exit(1)

    for i, table_rows in enumerate(parser.tables, 1):
        csv_file = f"{base}_{i}.csv"
        with open(csv_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerows(table_rows)
        print(f"Saved CSV: {csv_file} ({len(table_rows)} rows)")

if __name__ == "__main__":
    main()