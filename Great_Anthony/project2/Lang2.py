#!/usr/bin/env python3
"""
tables_to_csv_split.py

Usage:
  # Print all tables as CSV to stdout (blank line between tables)
  python tables_to_csv_split.py <URL>

  # Also write each table to its own file: DIR/PREFIX_table_01.csv, ...
  python tables_to_csv_split.py <URL> --out PREFIX --outdir extracted_tables

Notes:
  - Stdlib only; no csv module or third-party packages.
  - Handles <br> as newlines inside cells; ignores rowspan/colspan.
  - Uses a browser-like User-Agent to avoid common 403s.
"""

from __future__ import annotations

import argparse
import html
import sys
import os
import urllib.request
import urllib.error
from html.parser import HTMLParser
from typing import List


def fetch_html(url: str) -> str:
    if "://" not in url:
        url = "https://" + url  # convenience
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
                "(KHTML, like Gecko) Chrome/122 Safari/537.36"
            )
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
            return raw.decode(enc, errors="replace")
        except LookupError:
            return raw.decode("utf-8", errors="replace")


class TableParser(HTMLParser):
    """Extract all <table> elements into list[list[list[str]]]."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tables: List[List[List[str]]] = []
        self._in_table = False
        self._in_row = False
        self._in_cell = False
        self._current_table: List[List[str]] = []
        self._current_row: List[str] = []
        self._cell_buf: List[str] = []

    def handle_starttag(self, tag, attrs):
        t = tag.lower()
        if t == "table":
            self._in_table = True
            self._current_table = []
        elif self._in_table and t == "tr":
            self._in_row = True
            self._current_row = []
        elif self._in_row and t in ("td", "th"):
            self._in_cell = True
            self._cell_buf = []
        elif self._in_cell and t == "br":
            self._cell_buf.append("\n")

    def handle_endtag(self, tag):
        t = tag.lower()
        if t == "table" and self._in_table:
            if self._in_cell:
                self._push_cell()
            if self._in_row:
                self._push_row()
            self.tables.append(self._current_table)
            self._current_table = []
            self._in_table = False
        elif t == "tr" and self._in_row:
            if self._in_cell:
                self._push_cell()
            self._push_row()
        elif t in ("td", "th") and self._in_cell:
            self._push_cell()

    def handle_data(self, data):
        if self._in_cell and data:
            self._cell_buf.append(data)

    def handle_entityref(self, name):
        if self._in_cell:
            self._cell_buf.append(html.unescape(f"&{name};"))

    def handle_charref(self, name):
        if self._in_cell:
            self._cell_buf.append(html.unescape(f"&#{name};"))

    def _push_cell(self):
        text = "".join(self._cell_buf).replace("\r", "")
        # Preserve newlines (from <br>), normalize intra-line spaces
        lines = [ln.strip() for ln in text.splitlines()]
        normalized = "\n".join(" ".join(ln.split()) for ln in lines)
        self._current_row.append(normalized)
        self._cell_buf = []
        self._in_cell = False

    def _push_row(self):
        self._current_table.append(self._current_row)
        self._current_row = []
        self._in_row = False


def csv_escape(field: str) -> str:
    """Return a CSV-safe version of field (RFC 4180-ish)."""
    if field is None:
        field = ""
    needs_quotes = (
        "," in field
        or '"' in field
        or "\n" in field
        or "\r" in field
        or field.startswith(" ")
        or field.endswith(" ")
    )
    if '"' in field:
        field = field.replace('"', '""')
    return f'"{field}"' if needs_quotes else field


def table_to_csv_lines(table: List[List[str]]) -> List[str]:
    return [",".join(csv_escape(cell) for cell in row) for row in table]


def print_csv_table(table: List[List[str]]) -> None:
    lines = table_to_csv_lines(table)
    if lines:
        sys.stdout.write("\n".join(lines) + "\n")


def write_csv_file(table: List[List[str]], filepath: str) -> None:
    lines = table_to_csv_lines(table)
    with open(filepath, "w", encoding="utf-8", newline="\n") as f:
        if lines:
            f.write("\n".join(lines) + "\n")


def main(argv: List[str]) -> int:
    ap = argparse.ArgumentParser(
        description="Extract HTML tables and print CSV; optionally write each table to its own CSV file."
    )
    ap.add_argument("url", help="Web page URL (http/https)")
    ap.add_argument("--out", "-o", metavar="PREFIX",
                    help="If set, write each table to PREFIX_table_XX.csv")
    ap.add_argument("--outdir", metavar="DIR", default=".",
                    help="Directory to place CSV files (default: current directory)")
    args = ap.parse_args(argv[1:])

    # Ensure output directory exists if we're writing files
    if args.out:
        try:
            os.makedirs(args.outdir, exist_ok=True)
        except Exception as e:
            print(f"Error creating outdir '{args.outdir}': {e}", file=sys.stderr)
            return 1

    try:
        html_text = fetch_html(args.url)
    except urllib.error.HTTPError as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        return 1
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1

    parser = TableParser()
    parser.feed(html_text)

    # Print all tables to stdout (blank line between them)
    first = True
    for t in parser.tables:
        if not t:
            continue
        if not first:
            sys.stdout.write("\n")
        first = False
        print_csv_table(t)

    # Optionally write each table to its own file
    if args.out:
        written = 0
        for idx, t in enumerate(parser.tables, start=1):
            if not t:
                continue
            written += 1
            filename = f"{args.out}_table_{idx:02d}.csv"
            path = os.path.join(args.outdir, filename)
            write_csv_file(t, path)
            # Tell the user exactly where the file went
            print(f"Wrote: {os.path.abspath(path)}", file=sys.stderr)

        if written == 0:
            print("No <table> elements found — nothing written.", file=sys.stderr)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
