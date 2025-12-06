#!/usr/bin/env python3
"""
pdf_extract.py
Extract per-page text and write newline-delimited JSON:
  {"page": 1, "text": "..."}
Usage:
  python3 pdf_extract.py document.pdf
Outputs: document.pdf.pages.jsonl
"""
import sys, json
try:
    import fitz  # PyMuPDF
except Exception as e:
    print("Install PyMuPDF: pip install PyMuPDF")
    raise

def extract(pdf_path, out_path=None):
    if out_path is None:
        out_path = pdf_path + ".pages.jsonl"
    doc = fitz.open(pdf_path)
    with open(out_path, "w", encoding="utf-8") as f:
        for i, page in enumerate(doc, start=1):
            text = page.get_text("text")
            if text is None:
                text = ""
            text = text.replace("\r\n", "\n").replace("\r", "\n")
            obj = {"page": i, "text": text}
            f.write(json.dumps(obj, ensure_ascii=False) + "\n")
    print(f"Wrote {out_path}")
    return out_path

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: pdf_extract.py document.pdf")
        sys.exit(1)
    extract(sys.argv[1])
