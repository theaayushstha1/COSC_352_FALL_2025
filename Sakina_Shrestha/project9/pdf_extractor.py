# pdf_extractor.py
import sys
from pathlib import Path
from typing import List, Dict
from PyPDF2 import PdfReader
import json
import re

WINDOW_SIZE = 300   # words per passage
STEP_SIZE = 100     # overlap

def pdf_to_passages(pdf_path: str) -> List[Dict]:
    reader = PdfReader(pdf_path)
    passages: List[Dict] = []

    for page_idx, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        # Normalize whitespace
        text = re.sub(r"\s+", " ", text).strip()
        if not text:
            continue

        words = text.split()
        n = len(words)
        start = 0
        while start < n:
            end = min(start + WINDOW_SIZE, n)
            chunk_words = words[start:end]
            chunk_text = " ".join(chunk_words)
            passages.append({
                "page": page_idx,
                "text": chunk_text
            })
            if end == n:
                break
            start += STEP_SIZE

    return passages

def main():
    if len(sys.argv) != 3:
        print("Usage: python pdf_extractor.py <pdf_file> <output_json>")
        sys.exit(1)

    pdf_file = sys.argv[1]
    out_file = sys.argv[2]
    passages = pdf_to_passages(pdf_file)

    with open(out_file, "w", encoding="utf-8") as f:
        json.dump(passages, f, ensure_ascii=False, indent=2)

    print(f"Extracted {len(passages)} passages from {pdf_file}")

if __name__ == "__main__":
    main()
