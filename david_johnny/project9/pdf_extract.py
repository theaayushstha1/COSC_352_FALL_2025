
from pathlib import Path
from typing import List
import sys

try:
    import pypdf
except ImportError:  # pragma: no cover
    print("Missing dependency: pypdf. Install with: pip install pypdf", file=sys.stderr)
    sys.exit(1)


def extract_pages(pdf_path: str) -> List[str]:
    """Return list of page texts from a PDF file with progress indicator."""
    path = Path(pdf_path)
    if not path.is_file():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    try:
        reader = pypdf.PdfReader(str(path))
        total_pages = len(reader.pages)
        
        print(f"Extracting text from {total_pages} pages...", file=sys.stderr)
        
        pages: List[str] = []
        for i, page in enumerate(reader.pages, 1):
            text = page.extract_text() or ""
            pages.append(text)
            
            # Progress indicator every 10 pages or on last page
            if i % 10 == 0 or i == total_pages:
                progress = (i / total_pages) * 100
                print(f"Progress: {i}/{total_pages} pages ({progress:.1f}%)", file=sys.stderr)
        
        print("Extraction complete!", file=sys.stderr)
        return pages
        
    except pypdf.errors.PdfReadError as e:
        print(f"Error reading PDF: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python pdf_extract.py <pdf_path> <output_pages_txt>", file=sys.stderr)
        sys.exit(1)

    pdf_path = sys.argv[1]
    out_path = Path(sys.argv[2])

    pages = extract_pages(pdf_path)
    
    print(f"Writing pages to {out_path}...", file=sys.stderr)
    
    # Write one cleaned page per line so Mojo can treat each line as a passage.
    with out_path.open("w", encoding="utf-8") as f:
        for page in pages:
            clean = " ".join(page.split())  # collapse internal newlines/whitespace
            f.write(clean + "\n")
    
    print(f"Successfully wrote {len(pages)} pages to {out_path}", file=sys.stderr)