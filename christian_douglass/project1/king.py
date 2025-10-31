#!/usr/bin/env python3
"""
Scrape all HTML tables from a web page (URL or local file) and write them as CSVs.

- Standard library only (urllib, html.parser, csv, argparse).
- Basic support for <th>, <td>, <br>, and simple rowspan/colspan.
- Each table becomes table_1.csv, table_2.csv, ... in the output directory.

USAGE
=====
1) From a URL (default is Wikipedia "Comparison of programming languages"):
   python scrape_tables_to_csv.py \
       --url https://en.wikipedia.org/wiki/Comparison_of_programming_languages \
       --out ./out

2) From a local .html file you downloaded:
   python scrape_tables_to_csv.py --file ./page.html --out ./out

3) Use defaults (URL above, output to ./out):
   python scrape_tables_to_csv.py

Tip: Open the CSVs in Excel/Google Sheets/Numbers.

LIMITATIONS
===========
- HTML in the wild can be messy; this handles many tables, but not every exotic case.
- Row/col spans are supported in a pragmatic way: values are repeated across spanned cells.
- Styles/scripts are ignored. Nested tables are treated independently.
"""

import argparse
import csv
import sys
import os
import re
from html import unescape
from html.parser import HTMLParser
from urllib.parse import urlparse
from urllib.request import urlopen, Request

# ------------------------------------------------------------
# Small helper: strip tags inside a cell (keep text only)
TAG_RE = re.compile(r"<[^>]+>")

def clean_text(s: str) -> str:
    # Unescape HTML entities and collapse internal whitespace
    s = unescape(s)
    s = TAG_RE.sub("", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

# ------------------------------------------------------------
class TableHTMLParser(HTMLParser):
    """
    Parse HTML and extract <table>s as 2D arrays (lists of lists of strings).
    Handles basic rowspan/colspan by repeating cell values into spanned slots.
    """

    def __init__(self):
        super().__init__()
        self.tables = []         # list of tables; each table is list of rows
        self._in_table = False
        self._in_tr = False
        self._in_cell = False    # inside <td> or <th>
        self._cell_buffer = []   # text buffer for current cell
        self._current_table = []
        self._current_row = []
        self._pending_spans = []  # for the current table: list of (remaining_rows, col_idx, text)
        self._current_col_index = 0

    # ---------- tag handling ----------
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)

        if tag == "table":
            self._in_table = True
            self._current_table = []
            self._pending_spans = []

        elif tag == "tr" and self._in_table:
            self._in_tr = True
            self._current_row = []
            self._current_col_index = 0

        elif tag in ("td", "th") and self._in_tr:
            self._in_cell = True
            self._cell_buffer = []

            # BEFORE placing new cell(s), fill any column positions occupied by rowspans
            # Decrement remaining_rows for spans; if occupied, push the carried text into this row
            if self._pending_spans:
                # Build a map {col_idx: text} of cells carried into this row
                carry = {col: text for (rows_left, col, text) in self._pending_spans if rows_left > 0}
                while self._current_col_index in carry:
                    # fill carried cell
                    self._current_row.append(carry[self._current_col_index])
                    # Also decrease the rows_left counter for that span
                    self._pending_spans = [
                        (rows_left - 1 if (col == self._current_col_index and rows_left > 0) else rows_left, col, text)
                        for (rows_left, col, text) in self._pending_spans
                    ]
                    self._current_col_index += 1

            # store span info for this new cell
            self._current_cell_colspan = int(attrs.get("colspan", "1") or "1")
            self._current_cell_rowspan = int(attrs.get("rowspan", "1") or "1")

        elif tag == "br" and self._in_cell:
            # Treat <br> as newline to preserve multi-line content
            self._cell_buffer.append("\n")

    def handle_endtag(self, tag):
        if tag == "table" and self._in_table:
            # close any open row
            self._in_table = False
            self.tables.append(self._current_table)
            self._current_table = []

        elif tag == "tr" and self._in_tr:
            # Fill any remaining carried rowspans to the end of row
            if self._pending_spans:
                carry = {col: text for (rows_left, col, text) in self._pending_spans if rows_left > 0}
                while self._current_col_index in carry:
                    self._current_row.append(carry[self._current_col_index])
                    # decrement
                    self._pending_spans = [
                        (rows_left - 1 if (col == self._current_col_index and rows_left > 0) else rows_left, col, text)
                        for (rows_left, col, text) in self._pending_spans
                    ]
                    self._current_col_index += 1

            self._current_table.append(self._current_row)
            self._in_tr = False
            self._current_row = []

        elif tag in ("td", "th") and self._in_cell:
            # finalize current cell
            text = clean_text("".join(self._cell_buffer))
            colspan = getattr(self, "_current_cell_colspan", 1)
            rowspan = getattr(self, "_current_cell_rowspan", 1)

            # place text into the row for 'colspan' columns
            for j in range(colspan):
                self._current_row.append(text)
                self._current_col_index += 1

            # remember to carry text downward for 'rowspan-1' future rows
            if rowspan > 1:
                for j in range(colspan):
                    col_index_for_span = self._current_col_index - colspan + j
                    self._pending_spans.append((rowspan - 1, col_index_for_span, text))

            self._in_cell = False
            self._cell_buffer = []

    def handle_data(self, data):
        if self._in_cell:
            self._cell_buffer.append(data)

# ------------------------------------------------------------
def fetch_html(url: str) -> str:
    # polite user-agent to avoid some sites blocking urllib
    req = Request(url, headers={"User-Agent": "table-scraper/1.0 (stdlib)"})
    with urlopen(req) as resp:
        enc = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(enc, errors="replace")

def read_local(path: str) -> str:
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        return f.read()

def write_csvs(tables, out_dir):
    os.makedirs(out_dir, exist_ok=True)
    files = []
    for i, table in enumerate(tables, start=1):
        # Normalize rows to the same length
        width = max((len(r) for r in table), default=0)
        norm = [r + [""] * (width - len(r)) for r in table]

        path = os.path.join(out_dir, f"table_{i}.csv")
        with open(path, "w", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerows(norm)
        files.append(path)
    return files

def main():
    parser = argparse.ArgumentParser(description="Extract all HTML tables to CSV (stdlib only).")
    parser.add_argument("--url", help="Page URL to scrape",
                        default="https://en.wikipedia.org/wiki/Comparison_of_programming_languages")
    parser.add_argument("--file", help="Read from local HTML file instead of URL")
    parser.add_argument("--out", help="Output directory", default="./out")
    args = parser.parse_args()

    if args.file:
        html = read_local(args.file)
        source = args.file
    else:
        html = fetch_html(args.url)
        source = args.url

    parser_ = TableHTMLParser()
    parser_.feed(html)

    if not parser_.tables:
        print("No <table> elements found in:", source, file=sys.stderr)
        sys.exit(2)

    out_files = write_csvs(parser_.tables, args.out)
    print(f"Found {len(out_files)} table(s) in {source}")
    for p in out_files:
        print("  wrote:", p)

if __name__ == "__main__":
    main()
