"""Simple PDF text extraction helper.

Python is used **only** for PDF text extraction, as permitted.
Core search logic will be implemented in Mojo.
"""

from pathlib import Path
from typing import List

import sys

try:
    import pypdf
except ImportError:  # pragma: no cover
    print("Missing dependency: pypdf. Install with: pip install pypdf", file=sys.stderr)
    sys.exit(1)


def extract_pages(pdf_path: str) -> List[str]:
    """Return list of page texts from a PDF file."""
    path = Path(pdf_path)
    if not path.is_file():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    reader = pypdf.PdfReader(str(path))
    pages: List[str] = []
    for page in reader.pages:
        text = page.extract_text() or ""
        pages.append(text)
    return pages


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python pdf_extract.py <pdf_path> <output_pages_txt>", file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]
    out_path = Path(sys.argv[2])

    pages = extract_pages(pdf_path)
    # Write one cleaned page per line so Mojo can treat each line as a passage.
    with out_path.open("w", encoding="utf-8") as f:
        for page in pages:
            clean = " ".join(page.split())  # collapse internal newlines/whitespace
            f.write(clean + "\n")
