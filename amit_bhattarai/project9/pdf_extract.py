#!/usr/bin/env python3
"""
pdf_extract.py

Extracts paragraph-level passages from a PDF and writes them to a TSV file:
    page_number <TAB> passage_text

Usage:
    python3 pdf_extract.py input.pdf output.tsv
"""

import sys
from pathlib import Path

try:
    from PyPDF2 import PdfReader  # allowed: Python only for PDF text extraction
except ImportError:
    print("Error: PyPDF2 is not installed. Please run 'pip install PyPDF2'.", file=sys.stderr)
    sys.exit(1)


def normalize_paragraph(text: str) -> str:
    # Collapse all whitespace into single spaces and trim ends
    tokens = text.split()
    return " ".join(tokens)


def extract_passages(pdf_path: Path):
    reader = PdfReader(str(pdf_path))
    for page_idx, page in enumerate(reader.pages, start=1):
        raw = page.extract_text() or ""
        if not raw.strip():
            continue

        # Split on blank lines into paragraph-like chunks
        blocks = raw.split("\n\n")
        for block in blocks:
            norm = normalize_paragraph(block)
            # Skip very short lines
            if len(norm) < 40:
                continue
            yield page_idx, norm


def main():
    if len(sys.argv) != 3:
        print("Usage: python3 pdf_extract.py input.pdf output.tsv", file=sys.stderr)
        sys.exit(1)

    pdf_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    if not pdf_path.exists():
        print(f"Error: PDF not found at {pdf_path}", file=sys.stderr)
        sys.exit(1)

    count = 0
    with out_path.open("w", encoding="utf-8") as f:
        for page_num, passage in extract_passages(pdf_path):
            # Ensure no tabs or newlines in passage
            passage_clean = passage.replace("\t", " ").replace("\r", " ").replace("\n", " ")
            f.write(f"{page_num}\t{passage_clean}\n")
            count += 1

    print(f"Wrote {count} passages to {out_path}")


if __name__ == "__main__":
    main()
