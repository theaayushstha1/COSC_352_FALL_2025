#!/usr/bin/env python3
import sys
import urllib.request
import csv
import re
from html.parser import HTMLParser

# HTML parser class to extract tables from HTML content
class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        # Initialize state variables
        self.tables = []        # List to store all tables
        self.current_table = [] # Current table being parsed
        self.current_row = []   # Current row being parsed
        self.current_cell = []  # Current cell being parsed
        self.in_table = False   # Flag to track if inside a table
        self.in_row = False     # Flag to track if inside a row
        self.in_cell = False    # Flag to track if inside a cell
        self.skip_tags = {'style', 'script', 'meta', 'link'} # Tags to ignore
        self.current_tag = None # Track current tag for data handling

    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        if tag == 'table':
            self.in_table = True
            self.current_table = []
        elif tag == 'tr' and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ('td', 'th') and self.in_row:
            self.in_cell = True
            self.current_cell = []

    def handle_endtag(self, tag):
        if tag == 'table' and self.in_table:
            if self.current_table:  # Only append non-empty tables
                self.tables.append(self.current_table)
            self.in_table = False
        elif tag == 'tr' and self.in_row:
            if self.current_row:  # Only append non-empty rows
                self.current_table.append(self.current_row)
            self.in_row = False
        elif tag in ('td', 'th') and self.in_cell:
            # Clean and normalize cell data
            cell_content = re.sub(r'\s+', ' ', ''.join(self.current_cell)).strip()
            self.current_row.append(cell_content)
            self.in_cell = False
        self.current_tag = None

    def handle_data(self, data):
        # Only process data if inside a cell and not in a skipped tag
        if self.in_cell and self.current_tag not in self.skip_tags:
            self.current_cell.append(data.strip())

def main():
    """
    Main function to parse HTML tables from a URL or file and save them as CSV files.
    Usage: python read_html_table.py <URL|FILENAME> [output_prefix]
    This script extracts ALL tables (up to 5 for this project) to ensure at least 5 CSVs are generated.
    """
    # Check command-line arguments
    if len(sys.argv) < 2:
        print("Usage: python read_html_table.py <URL|FILENAME> [output_prefix]")
        sys.exit(1)

    source = sys.argv[1]
    output_prefix = sys.argv[2] if len(sys.argv) > 2 else "table"

    # Fetch HTML content
    try:
        if source.startswith(('http://', 'https://')):
            # Fetch from URL with a user-agent to avoid blocking
            req = urllib.request.Request(source, headers={'User-Agent': 'Mozilla/5.0'})
            html = urllib.request.urlopen(req).read().decode('utf-8', errors='ignore')
        else:
            # Read from local file
            with open(source, 'r', encoding='utf-8', errors='ignore') as f:
                html = f.read()
    except Exception as e:
        print(f"Error fetching {source}: {e}")
        sys.exit(1)

    # Parse HTML to extract tables
    parser = TableParser()
    parser.feed(html)

    # Save each table to a CSV file - relaxed filter to include more tables for 5 CSVs
    table_count = 0
    max_tables = 5  # Limit to 5 tables as per user request
    for idx, table in enumerate(parser.tables, 1):
        # Relaxed filter: Save tables with at least 1 row (includes small tables)
        if len(table) >= 1 and table_count < max_tables:
            table_count += 1
            filename = f"{output_prefix}_{table_count}.csv"
            try:
                with open(filename, 'w', newline='', encoding='utf-8') as f:
                    writer = csv.writer(f)
                    writer.writerows(table)
                print(f"Saved {filename} ({len(table)} rows)")
            except Exception as e:
                print(f"Error saving {filename}: {e}")

    print(f"Extracted {table_count} tables from {source} (limited to {max_tables} for project)")


if __name__ == "__main__":
    main()
