#!/usr/bin/env python3
"""
Extract HTML <table> elements from a URL and save them as CSV files.
Each table is written as: table_1.csv, table_2.csv, ...

Stdlib only: sys, argparse, csv, html, html.parser, urllib

Usage:
  python extract_tables.py "https://example.com/page"
  python extract_tables.py "https://example.com/page" --table 0
"""

import sys
import argparse
import csv
import html
from html.parser import HTMLParser
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables = []
        self._in_table = False
        self._in_row = False
        self._in_cell = False
        self._curr_table = None
        self._curr_row = None
        self._curr_cell_fragments = None
        self._cell_tag_stack = []
        self._pending_colspan = 1

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag == "table":
            if not self._in_table:
                self._in_table = True
                self._curr_table = []
        elif tag == "tr" and self._in_table:
            self._in_row = True
            self._curr_row = []
        elif tag in ("td", "th") and self._in_row:
            self._in_cell = True
            self._curr_cell_fragments = []
            self._cell_tag_stack.append(tag)
            attr_dict = {k.lower(): v for k, v in attrs}
            try:
                self._pending_colspan = max(1, int(attr_dict.get("colspan", "1")))
            except ValueError:
                self._pending_colspan = 1
        elif tag == "br" and self._in_cell:
            self._curr_cell_fragments.append("\n")
        elif tag in ("p", "div", "li") and self._in_cell:
            if self._curr_cell_fragments and not self._curr_cell_fragments[-1].endswith("\n"):
                self._curr_cell_fragments.append("\n")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag == "table" and self._in_table:
            if self._in_cell:
                self._finish_cell()
            if self._in_row:
                self._finish_row()
            self.tables.append(self._curr_table or [])
            self._curr_table = None
            self._in_table = False
        elif tag == "tr" and self._in_row:
            if self._in_cell:
                self._finish_cell()
            self._finish_row()
        elif tag in ("td", "th") and self._in_cell:
            if self._cell_tag_stack:
                self._cell_tag_stack.pop()
            if not self._cell_tag_stack:
                self._finish_cell()
        elif tag in ("p", "div", "li") and self._in_cell:
            if self._curr_cell_fragments and not "".join(self._curr_cell_fragments).endswith("\n"):
                self._curr_cell_fragments.append("\n")

    def handle_data(self, data):
        if self._in_cell and data:
            self._curr_cell_fragments.append(data)

    def handle_entityref(self, name):
        if self._in_cell:
            self._curr_cell_fragments.append(html.unescape(f"&{name};"))

    def handle_charref(self, name):
        if self._in_cell:
            self._curr_cell_fragments.append(html.unescape(f"&#{name};"))

    def _finish_cell(self):
        text = "".join(self._curr_cell_fragments).strip()
        lines = [ln.strip() for ln in text.splitlines()]
        cell_value = "\n".join([ln for ln in lines if ln != ""])
        for _ in range(self._pending_colspan):
            self._curr_row.append(cell_value)
        self._curr_cell_fragments = None
        self._in_cell = False
        self._pending_colspan = 1

    def _finish_row(self):
        if any((c or "").strip() for c in self._curr_row):
            self._curr_table.append(self._curr_row)
        self._curr_row = None
        self._in_row = False


def fetch_html(url: str) -> str:
    req = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urlopen(req, timeout=30) as resp:
            data = resp.read()
            charset = resp.headers.get_content_charset()
            for enc in (charset, "utf-8", "windows-1252", "latin-1"):
                if not enc:
                    continue
                try:
                    return data.decode(enc, errors="replace")
                except LookupError:
                    continue
            return data.decode("utf-8", errors="replace")
    except HTTPError as e:
        sys.stderr.write(f"HTTP error: {e.code} {e.reason}\n")
        sys.exit(1)
    except URLError as e:
        sys.stderr.write(f"URL error: {e.reason}\n")
        sys.exit(1)


def save_tables_as_csv(tables, which=None):
    if which is not None:
        if which < 0 or which >= len(tables):
            sys.stderr.write(f"No table at index {which}. Found {len(tables)} tables.\n")
            sys.exit(2)
        filename = f"table_{which+1}.csv"
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            for row in tables[which]:
                writer.writerow(row)
        print(f"Saved {filename}")
        return

    for i, tbl in enumerate(tables, start=1):
        filename = f"table_{i}.csv"
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            for row in tbl:
                writer.writerow(row)
        print(f"Saved {filename}")


def main():
    ap = argparse.ArgumentParser(description="Extract HTML tables from a URL and save as table_#.csv files.")
    ap.add_argument("url", help="The web page URL containing HTML tables")
    ap.add_argument("--table", type=int, default=None, help="Only save the Nth table (0-based index)")
    args = ap.parse_args()

    html_text = fetch_html(args.url)
    parser = TableParser()
    parser.feed(html_text)
    tables = parser.tables

    if not tables:
        sys.stderr.write("No tables found.\n")
        sys.exit(3)

    save_tables_as_csv(tables, which=args.table)


if __name__ == "__main__":
    main()
