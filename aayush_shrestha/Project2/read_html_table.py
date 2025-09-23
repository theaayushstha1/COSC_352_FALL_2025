#!/usr/bin/env python3
"""
read_html_table.py
Read HTML tables from a URL or file and save them as CSV.
"""

import sys
import csv
import html
from html.parser import HTMLParser
from urllib.parse import urlparse
from urllib.request import urlopen

# read bytes
def read_bytes(src):
    u = urlparse(src)
    if u.scheme in ("http", "https"):
        with urlopen(src) as r:
            return r.read()
    with open(src, "rb") as f:
        return f.read()

# table parser
class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables = []
        self.in_table = False
        self.depth = 0
        self.in_row = False
        self.in_cell = False
        self.cur_table = None
        self.cur_row = None
        self.cur_cell = []
        self.skip = 0  # script/style

    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag in ("script", "style"):
            self.skip += 1
            return
        if tag == "table":
            self.depth += 1
            if self.depth == 1:
                self.in_table = True
                self.cur_table = []
        if not self.in_table or self.depth != 1:
            return
        if tag == "tr":
            self.in_row = True
            self.cur_row = []
        elif tag in ("td", "th"):
            self.in_cell = True
            self.cur_cell = []
        elif tag == "br":
            if self.in_cell:
                self.cur_cell.append("\n")

    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag in ("script", "style"):
            if self.skip:
                self.skip -= 1
            return
        if tag == "table":
            if self.depth == 1 and self.in_table:
                self.tables.append(self.cur_table)
                self.cur_table = None
                self.in_table = False
            if self.depth:
                self.depth -= 1
        if not self.in_table or self.depth != 1:
            return
        if tag == "tr":
            if self.in_row and self.cur_row and any(c.strip() for c in self.cur_row):
                self.cur_table.append(self.cur_row)
            self.in_row = False
        elif tag in ("td", "th"):
            if self.in_cell:
                txt = "".join(self.cur_cell)
                txt = html.unescape(txt)
                txt = " ".join(txt.split())
                self.cur_row.append(txt)
                self.in_cell = False

    def handle_data(self, data):
        if self.skip:
            return
        if self.in_cell:
            self.cur_cell.append(data)

# write csvs
def write_csv(tables):
    out = []
    for i, t in enumerate(tables, start=1):
        if not t:
            continue
        cols = max(len(r) for r in t)
        rows = [r + [""] * (cols - len(r)) for r in t]
        name = f"table_{i}.csv"
        with open(name, "w", newline="", encoding="utf-8") as f:
            csv.writer(f).writerows(rows)
        out.append(name)
    return out

def main():
    if len(sys.argv) != 2:
        print("Usage: python read_html_table.py <URL_or_file>")
        return
    src = sys.argv[1]
    try:
        raw = read_bytes(src)
    except Exception as e:
        print("Error:", e)
        return
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("latin-1", errors="replace")
    parser = TableParser()
    parser.feed(text)
    if not parser.tables:
        print("No tables found")
        return
    files = write_csv(parser.tables)
    for fn in files:
        print("Saved:", fn)

if __name__ == "__main__":
    main()
