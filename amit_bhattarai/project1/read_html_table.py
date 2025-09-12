#!/usr/bin/env python3
"""
read_html_table.py

Reads tables from a given HTML page (local file or URL) and writes them
to CSV files that can be opened in any spreadsheet program.

Usage:
    python3 read_html_table.py <URL|FILENAME>

Examples:
    python3 read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages
    python3 read_html_table.py wikipedia_page.html
"""

import sys
import csv
import urllib.request
from html.parser import HTMLParser

class TableParser(HTMLParser):
    """
    A custom parser that extracts HTML tables into Python lists.
    - self.tables will contain all tables found.
    - Each table is a list of rows, each row is a list of cells.
    """
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_cell = ""
        self.current_row = []
        self.current_table = []
        self.tables = []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            self.in_table = True
            self.current_table = []
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ("td", "th") and self.in_row:
            self.in_cell = True
            self.current_cell = ""

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data.strip() + " "

    def handle_endtag(self, tag):
        if tag in ("td", "th") and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())
        elif tag == "tr" and self.in_row:
            self.in_row = False
            if self.current_row:
                self.current_table.append(self.current_row)
        elif tag == "table" and self.in_table:
            self.in_table = False
            if self.current_table:
                self.tables.append(self.current_table)

def read_html(source):
    """Read HTML from a URL or a local file."""
    if source.startswith("http://") or source.startswith("https://"):
        # Pretend to be a real browser so Wikipedia doesn't block us
        req = urllib.request.Request(source, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req) as response:
            return response.read().decode("utf-8", errors="ignore")
    else:
        with open(source, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()

def save_tables(tables):
    for i, table in enumerate(tables, start=1):
        filename = f"table_{i}.csv"
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            for row in table:
                writer.writerow(row)
        print(f"✅ Saved {filename}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 read_html_table.py <URL|FILENAME>")
        sys.exit(1)

    source = sys.argv[1]
    html_content = read_html(source)

    parser = TableParser()
    parser.feed(html_content)

    if parser.tables:
        save_tables(parser.tables)
    else:
        print("⚠️ No tables found.")

if __name__ == "__main__":
    main()
