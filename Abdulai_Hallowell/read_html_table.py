#!/usr/bin/env python3
"""
read_html_table.py

Extract ALL HTML tables from a web page (URL) or a local HTML file and write each
table to its own CSV file (table_1.csv, table_2.csv, ...). Uses ONLY the Python
standard library (no BeautifulSoup, no pandas).

Why this design?
- Reliability: html.parser is lenient and available everywhere in stdlib.
- Portability: no third-party deps; works on school lab machines.
- Practicality: handles <th>, <td>, thead/tbody/tfoot, and best-effort rowspan/colspan.

USAGE:
    python read_html_table.py <URL_OR_FILENAME> [--out OUTDIR]

EXAMPLES:
    python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages
    python read_html_table.py page.html --out csv_out

OUTPUT:
    OUTDIR/table_1.csv, OUTDIR/table_2.csv, ...

Notes:
- Row/col spans are approximated: the same text is duplicated across covered cells.
- Inline footnote markers like `[1]`, `[a]` are stripped.
- Whitespace is normalized.

Author: <your name>
"""

from __future__ import annotations

import argparse
import csv
import html
import io
import os
import re
import sys
import urllib.request
from html.parser import HTMLParser
from typing import List, Optional, Tuple
from urllib.parse import urlparse


# ----------------------------- I/O Helpers --------------------------------- #

def fetch_input(source: str) -> str:
    """
    Load HTML from a URL (http/https) or from a local file path.

    Args:
        source: URL (http/https) or path to local .html file

    Returns:
        The HTML text decoded as UTF-8 (fallback) or as declared by the server.

    Raises:
        URLError / FileNotFoundError / OSError if retrieval fails.
    """
    parsed = urlparse(source)
    if parsed.scheme in ("http", "https"):
        with urllib.request.urlopen(source) as resp:
            charset = resp.headers.get_content_charset() or "utf-8"
            return resp.read().decode(charset, errors="replace")
    # Local file
    with open(source, "r", encoding="utf-8", errors="replace") as f:
        return f.read()


def ensure_outdir(path: str) -> None:
    """Create output directory if missing."""
    os.makedirs(path, exist_ok=True)


# ----------------------------- Text Cleaning -------------------------------- #

_FOOTNOTE_RE = re.compile(r"\[\s*[0-9a-zA-Z]+\s*\]")  # matches [1], [a], [note] styles
_WS_RE = re.compile(r"\s+")


def clean_text(s: str) -> str:
    """
    Normalize and sanitize inner text extracted from HTML.

    Steps:
      - HTML-unescape entities (&amp;, &nbsp;, etc.)
      - Remove footnote-like markers [1], [a], etc.
      - Collapse all whitespace to single spaces
      - Strip leading/trailing spaces

    Args:
        s: raw text fragment

    Returns:
        cleaned string
    """
    s = html.unescape(s)
    s = _FOOTNOTE_RE.sub("", s)
    s = _WS_RE.sub(" ", s)
    return s.strip()


# ----------------------------- Table Parser --------------------------------- #

class TableHTMLParser(HTMLParser):
    """
    Minimal, table-focused HTML parser. It supports:
      - Multiple <table> elements per page
      - thead/tbody/tfoot, tr/th/td
      - Best-effort handling of colspan/rowspan

    Implementation notes:
      - We accumulate each table as a list of row lists (List[List[str]]).
      - For rowspans, we keep a carry-over array mapping column index -> (text, remaining_rows).
      - For colspans, we duplicate the text horizontally.
      - We do not attempt full CSS/DOM computation; this is intentionally pragmatic.
    """

    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.tables: List[List[List[str]]] = []

        # State flags / buffers
        self._in_table: bool = False
        self._cur_table: Optional[List[List[str]]] = None

        self._cur_row: Optional[List[str]] = None

        self._in_cell: bool = False
        self._cell_text_buf: Optional[io.StringIO] = None
        self._cell_colspan: int = 1
        self._cell_rowspan: int = 1

        # Rowspan carry: list where index = column; value = (text, remaining_rows) or None
        self._rowspan_carry: Optional[List[Optional[Tuple[str, int]]]] = None

        # Minor quality-of-life: ignore content inside <script> and <style> while in table.
        self._skip_tag_stack: List[str] = []

    # ---- HTMLParser event handlers ---- #

    def handle_starttag(self, tag: str, attrs) -> None:
        attrs = dict(attrs)

        # Ignore scripts/styles within tables (so we don't pollute cell text)
        if self._in_table and tag in ("script", "style"):
            self._skip_tag_stack.append(tag)
            return

        if tag == "table":
            self._in_table = True
            self._cur_table = []
            self._rowspan_carry = []
        elif self._in_table and tag == "tr":
            self._start_row()
        elif self._in_table and tag in ("td", "th"):
            # Begin a cell
            self._in_cell = True
            self._cell_text_buf = io.StringIO()
            self._cell_colspan = int(attrs.get("colspan", "1") or "1")
            self._cell_rowspan = int(attrs.get("rowspan", "1") or "1")

    def handle_endtag(self, tag: str) -> None:
        # Close skip blocks
        if self._skip_tag_stack and tag == self._skip_tag_stack[-1]:
            self._skip_tag_stack.pop()
            return

        if tag == "table" and self._in_table:
            # Close any dangling row, finalize table
            if self._cur_row is not None:
                self._finish_row()
            self.tables.append(self._cur_table or [])
            self._in_table = False
            self._cur_table = None
            self._rowspan_carry = None

        elif self._in_table and tag == "tr":
            self._finish_row()

        elif self._in_table and tag in ("td", "th"):
            self._finish_cell()

    def handle_data(self, data: str) -> None:
        if self._in_table and self._in_cell and not self._skip_tag_stack:
            assert self._cell_text_buf is not None
            self._cell_text_buf.write(data)

    def handle_entityref(self, name: str) -> None:
        if self._in_table and self._in_cell and not self._skip_tag_stack:
            assert self._cell_text_buf is not None
            self._cell_text_buf.write(f"&{name};")

    def handle_charref(self, name: str) -> None:
        if self._in_table and self._in_cell and not self._skip_tag_stack:
            assert self._cell_text_buf is not None
            self._cell_text_buf.write(f"&#{name};")

    # ---- Internal helpers ---- #

    def _start_row(self) -> None:
        self._cur_row = []

        # Pre-append any carried rowspans at the start of a new row
        if self._rowspan_carry:
            for carry in self._rowspan_carry:
                if carry is None:
                    # Placeholder; will be filled by cells if needed
                    self._cur_row.append("")
                else:
                    text, _remaining = carry
                    self._cur_row.append(text)

    def _finish_cell(self) -> None:
        """Close a cell, place its text honoring colspan/rowspan."""
        if not self._in_cell:
            return
        self._in_cell = False

        raw = self._cell_text_buf.getvalue() if self._cell_text_buf else ""
        text = clean_text(raw)
        self._cell_text_buf.close() if self._cell_text_buf else None
        self._cell_text_buf = None

        colspan = max(1, self._cell_colspan)
        rowspan = max(1, self._cell_rowspan)

        # Ensure current row exists
        if self._cur_row is None:
            self._cur_row = []

        # Find first truly empty slot (accounting for prefilled rowspans)
        col = 0
        while col < len(self._cur_row) and self._cur_row[col] != "":
            col += 1

        # Make sure row is long enough to place this cell + colspan
        needed_len = col + colspan
        if len(self._cur_row) < needed_len:
            self._cur_row.extend([""] * (needed_len - len(self._cur_row)))

        # Place horizontally (colspan)
        for i in range(colspan):
            self._cur_row[col + i] = text

        # Prepare rowspan carry structure
        if self._rowspan_carry is None:
            self._rowspan_carry = []
        if len(self._rowspan_carry) < len(self._cur_row):
            self._rowspan_carry.extend([None] * (len(self._cur_row) - len(self._rowspan_carry)))

        # Record vertical carry (rowspan) for columns we just wrote
        if rowspan > 1:
            for i in range(colspan):
                self._rowspan_carry[col + i] = (text, rowspan - 1)

    def _finish_row(self) -> None:
        """Finalize the current row and decrement rowspan counters."""
        if self._cur_row is None:
            return

        # Trim trailing empties that are just padding
        while self._cur_row and self._cur_row[-1] == "":
            self._cur_row.pop()

        # Commit row
        assert self._cur_table is not None
        self._cur_table.append(self._cur_row)

        # Decrement carries for the next row
        if self._rowspan_carry:
            new_carry: List[Optional[Tuple[str, int]]] = []
            for slot in self._rowspan_carry:
                if slot is None:
                    new_carry.append(None)
                else:
                    text, remaining = slot
                    new_carry.append((text, remaining - 1) if remaining - 1 > 0 else None)
            self._rowspan_carry = new_carry

        self._cur_row = None


# ----------------------------- CSV Writer ----------------------------------- #

def write_csvs(tables: List[List[List[str]]], outdir: str) -> int:
    """
    Write each parsed table to a CSV file. Non-rectangular rows are padded.

    Args:
        tables: list of tables (each a list of row lists)
        outdir: output directory

    Returns:
        number of CSV files written
    """
    ensure_outdir(outdir)
    written = 0

    for idx, rows in enumerate(tables, start=1):
        if not rows:
            continue

        # Normalize to a rectangle by padding short rows
        width = max((len(r) for r in rows), default=0)
        normalized = [r + [""] * (width - len(r)) for r in rows]

        path = os.path.join(outdir, f"table_{idx}.csv")
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(normalized)
        print(f"Wrote {path}  ({len(rows)} rows)")
        written += 1

    if written == 0:
        print("No <table> elements found.")
    return written


# ----------------------------- CLI Entrypoint -------------------------------- #

def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Extract all HTML <table> elements from a URL or local file to CSV (stdlib only)."
    )
    p.add_argument("source", help="URL (http/https) or path to local HTML file")
    p.add_argument("--out", default="out_csv", help="Output directory (default: out_csv)")
    return p.parse_args(argv)


def main(argv: Optional[List[str]] = None) -> int:
    args = parse_args(argv)

    # 1) Fetch HTML
    try:
        html_text = fetch_input(args.source)
    except Exception as e:
        print(f"[ERROR] Could not read source '{args.source}': {e}", file=sys.stderr)
        return 2

    # 2) Parse tables
    parser = TableHTMLParser()
    parser.feed(html_text)
    parser.close()

    # 3) Write CSVs
    try:
        write_csvs(parser.tables, args.out)
    except Exception as e:
        print(f"[ERROR] Failed to write CSVs: {e}", file=sys.stderr)
        return 3

    return 0


if __name__ == "__main__":
    sys.exit(main())

