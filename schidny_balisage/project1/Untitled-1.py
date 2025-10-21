#!/usr/bin/env python3
import sys
import urllib.request
import csv
import re
import os
from html.parser import HTMLParser

class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables = []          # list of tables (each: list of rows)
        self.table_depth = 0      # track nesting; parse only top-level tables
        self.in_row = False
        self.in_cell = False
        self.current_table = []
        self.current_row = []
        self.current_cell = []

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.table_depth += 1
            if self.table_depth == 1:
                self.current_table = []
        elif self.table_depth == 1:
            if tag == 'tr':
                self.in_row = True
                self.current_row = []
            elif tag in ('td', 'th') and self.in_row:
                self.in_cell = True
                self.current_cell = []
            elif tag == 'br' and self.in_cell:
                self.current_cell.append(' ')  # treat <br> as space

    def handle_endtag(self, tag):
        if tag == 'table':
            if self.table_depth == 1:
                # finish any open row
                if self.in_row and self.current_row:
                    self.current_table.append(self.current_row)
                if self.current_table:
                    self.tables.append(self.current_table)
            self.table_depth = max(0, self.table_depth - 1)

        elif self.table_depth == 1:
            if tag == 'tr' and self.in_row:
                if self.current_row:
                    self.current_table.append(self.current_row)
                self.in_row = False
            elif tag in ('td', 'th') and self.in_cell:
                # join with spaces so inline tags don't concatenate words
                cell = ' '.join(self.current_cell)
                cell = re.sub(r'\s+', ' ', cell).strip()
                self.current_row.append(cell)
                self.in_cell = False

    def handle_data(self, data):
        if self.table_depth == 1 and self.in_cell:
            # keep raw data; normalize later
            self.current_cell.append(data)

def fetch_html(source: str) -> tuple[str, str]:
    """Return (html_text, base_prefix)."""
    if os.path.exists(source):
        with open(source, 'r', encoding='utf-8', errors='replace') as f:
            return f.read(), os.path.splitext(os.path.basename(source))[0]
    if not source.startswith(('http://', 'https://')):
        raise ValueError("Provide an http(s) URL or an existing HTML file path.")
    req = urllib.request.Request(source, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=30) as resp:
        html = resp.read().decode('utf-8', errors='replace')
    # derive a simple base name from URL path
    last = source.rsplit('/', 1)[-1] or 'page'
    base = re.sub(r'[^\w\-]+', '_', last) or 'page'
    return html, base

def main():
    if len(sys.argv) < 2:
        print("Usage: python read_html_table.py <URL|FILENAME> [output_prefix]")
        sys.exit(1)

    source = sys.argv[1]
    output_prefix = sys.argv[2] if len(sys.argv) > 2 else None

    try:
        html, base = fetch_html(source)
    except Exception as e:
        print(f"Error fetching {source}: {e}")
        sys.exit(1)

    parser = TableParser()
    parser.feed(html)

    tables = parser.tables
    print(f"Found {len(tables)} table(s).")

    # write each table; pad rows to same width for spreadsheets
    saved = 0
    for idx, table in enumerate(tables, 1):
        if not table:
            continue
        max_cols = max(len(r) for r in table)
        rows = [r + [''] * (max_cols - len(r)) for r in table]

        prefix = output_prefix or base or "table"
        filename = f"{prefix}_{idx:02d}.csv"
        try:
            with open(filename, 'w', newline='', encoding='utf-8') as f:
                writer = csv.writer(f)
                writer.writerows(rows)
            saved += 1
            print(f"Saved {filename} ({len(rows)} rows × {max_cols} cols)")
        except Exception as e:
            print(f"Error saving {filename}: {e}")

    if saved == 0:
        print("No tables written.")
    else:
        print(f"Extracted {saved} table(s) from {source}")

if __name__ == "__main__":
    main()
