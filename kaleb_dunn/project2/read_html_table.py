#!/usr/bin/env python3
"""
read_html_table.py

Reads all HTML <table> elements from a given webpage or local file,
and saves them into CSV files that can be loaded into a spreadsheet.

Usage:
    python read_html_table.py <URL|FILENAME>

Examples:
    python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages
    python read_html_table.py saved_page.html

Requirements:
    - Python 3
    - Standard library only (no external dependencies)

Output:
    - One CSV file per table found (table1.csv, table2.csv, ...)

Author: <your name>
"""

import sys
import os
import urllib.request
from html.parser import HTMLParser
import csv

class TableParser(HTMLParser):
    """Parses HTML tables into a list of tables (rows of cells)."""

    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.tables = []     # list of tables
        self.current_table = []
        self.current_row = []
        self.current_cell = []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.in_table = True
            self.current_table = []
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ("td", "th") and self.in_row:
            self.in_cell = True
            self.current_cell = []

    def handle_endtag(self, tag):
        if tag == "table" and self.in_table:
            self.in_table = False
            self.tables.append(self.current_table)
        elif tag == "tr" and self.in_row:
            self.in_row = False
            self.current_table.append(self.current_row)
        elif tag in ("td", "th") and self.in_cell:
            self.in_cell = False
            cell_text = "".join(self.current_cell).strip()
            self.current_row.append(cell_text)

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell.append(data)

def fetch_html(source):
    """Read HTML from URL or local file."""
    if source.startswith("http://") or source.startswith("https://"):
        req = urllib.request.Request(
            source,
            headers={"User-Agent": "Mozilla/5.0"}  # Pretend to be a browser
        )
        with urllib.request.urlopen(req) as response:
            return response.read().decode("utf-8", errors="ignore")
    else:
        with open(source, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()

def save_tables_to_csv(tables):
    """Save each table as tableN.csv."""
    for i, table in enumerate(tables, start=1):
        filename = f"table{i}.csv"
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(table)
        print(f"Saved {filename} ({len(table)} rows)")

def main():
    if len(sys.argv) != 2:
        print("Usage: python read_html_table.py <URL|FILENAME>")
        sys.exit(1)

    source = sys.argv[1]
    print(f"Reading from: {source}")

    html = fetch_html(source)
    parser = TableParser()
    parser.feed(html)

    if not parser.tables:
        print("No tables found.")
    else:
        print(f"Found {len(parser.tables)} tables.")
        save_tables_to_csv(parser.tables)

if __name__ == "__main__":
    main()

#RUN THE CODE BELOW!
#python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages

