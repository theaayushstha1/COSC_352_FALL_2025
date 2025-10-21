#!/usr/bin/env python3
# chinonso_egeolu_project1.py
"""
Usage:
  python chinonso_egeolu_project1.py <URL-or-HTML-file>

Behavior:
  - If given a URL (http/https), fetch it with a browser-like User-Agent,
    save a copy as 'input.html', then extract tables.
  - If given a local .html file, read it directly (does not overwrite input.html).
  - Writes table_1.csv, table_2.csv, ... to the current directory.
  - Uses only Python's standard library; does NOT use the csv module.
"""

from __future__ import annotations
import sys, os, html, urllib.request, urllib.error
from html.parser import HTMLParser
from typing import List

def fetch_html(source: str) -> str:
    # Local file?
    if "://" not in source and os.path.exists(source):
        with open(source, "rb") as f:
            raw = f.read()
        try:
            return raw.decode("utf-8")
        except UnicodeDecodeError:
            return raw.decode("latin-1", errors="replace")

    # Otherwise treat as URL; add https:// if user omitted scheme
    if "://" not in source:
        source = "https://" + source
    req = urllib.request.Request(
        source,
        headers={
            "User-Agent": ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                           "(KHTML, like Gecko) Chrome/122 Safari/537.36")
        },
    )
    with urllib.request.urlopen(req) as resp:
        ctype = resp.headers.get("Content-Type", "")
        enc = "utf-8"
        for part in ctype.split(";"):
            part = part.strip().lower()
            if part.startswith("charset="):
                enc = part.split("=", 1)[1]
                break
        raw = resp.read()
    try:
        text = raw.decode(enc, errors="replace")
    except LookupError:
        text = raw.decode("utf-8", errors="replace")

    # Save a copy like in your screenshot
    with open("input.html", "w", encoding="utf-8") as f:
        f.write(text)
    return text

class TableParser(HTMLParser):
    """Extract all <table> elements into list[list[list[str]]]."""
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tables: List[List[List[str]]] = []
        self._in_table = self._in_row = self._in_cell = False
        self._current_table: List[List[str]] = []
        self._current_row: List[str] = []
        self._cell_buf: List[str] = []

    def handle_starttag(self, tag, attrs):
        t = tag.lower()
        if t == "table":
            self._in_table = True; self._current_table = []
        elif self._in_table and t == "tr":
            self._in_row = True; self._current_row = []
        elif self._in_row and t in ("td", "th"):
            self._in_cell = True; self._cell_buf = []
        elif self._in_cell and t == "br":
            self._cell_buf.append("\n")

    def handle_endtag(self, tag):
        t = tag.lower()
        if t == "table" and self._in_table:
            if self._in_cell: self._push_cell()
            if self._in_row: self._push_row()
            self.tables.append(self._current_table)
            self._current_table = []; self._in_table = False
        elif t == "tr" and self._in_row:
            if self._in_cell: self._push_cell()
            self._push_row()
        elif t in ("td", "th") and self._in_cell:
            self._push_cell()

    def handle_data(self, data):
        if self._in_cell and data: self._cell_buf.append(data)

    def handle_entityref(self, name):
        if self._in_cell: self._cell_buf.append(html.unescape(f"&{name};"))

    def handle_charref(self, name):
        if self._in_cell: self._cell_buf.append(html.unescape(f"&#{name};"))

    def _push_cell(self):
        text = "".join(self._cell_buf).replace("\r", "")
        lines = [ln.strip() for ln in text.splitlines()]
        normalized = "\n".join(" ".join(ln.split()) for ln in lines)
        self._current_row.append(normalized)
        self._cell_buf = []; self._in_cell = False

    def _push_row(self):
        self._current_table.append(self._current_row)
        self._current_row = []; self._in_row = False

def csv_escape(field: str) -> str:
    if field is None: field = ""
    needs_quotes = ("," in field or '"' in field or "\n" in field or
                    "\r" in field or field.startswith(" ") or field.endswith(" "))
    if '"' in field: field = field.replace('"', '""')
    return f'"{field}"' if needs_quotes else field

def table_to_csv_lines(table: List[List[str]]) -> List[str]:
    return [",".join(csv_escape(cell) for cell in row) for row in table]

def write_csv_file(table: List[List[str]], filename: str) -> None:
    lines = table_to_csv_lines(table)
    with open(filename, "w", encoding="utf-8", newline="\n") as f:
        if lines: f.write("\n".join(lines) + "\n")

def main(argv: List[str]) -> int:
    if len(argv) != 2:
        print("Usage: python chinonso_egeolu_project1.py <URL-or-HTML-file>", file=sys.stderr)
        return 2
    source = argv[1]
    try:
        html_text = fetch_html(source)
    except urllib.error.HTTPError as e:
        print(f"Error fetching URL: {e}", file=sys.stderr); return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr); return 1

    parser = TableParser(); parser.feed(html_text)

    if not parser.tables:
        print("No <table> elements found.", file=sys.stderr)
        return 0

    # Write table_1.csv, table_2.csv, ...
    for i, tbl in enumerate(parser.tables, start=1):
        name = f"table_{i}.csv"
        write_csv_file(tbl, name)
        print(f"Wrote: {os.path.abspath(name)}", file=sys.stderr)
    return 0

if __name__ == "__main__":
    import sys
    raise SystemExit(main(sys.argv))
