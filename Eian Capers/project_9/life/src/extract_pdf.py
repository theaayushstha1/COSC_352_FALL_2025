#!/usr/bin/env python3
# src/extract_pdf.py
import sys
import json
import re
from pathlib import Path

try:
    import PyPDF2
except ImportError:
    print("Error: PyPDF2 not installed. Run: pip install PyPDF2")
    sys.exit(1)

# Tunable parameters
MIN_WORDS = 8
MAX_WORDS = 500
SLIDING_WINDOW_WORDS = 120
SLIDING_WINDOW_STEP = 60

_RE_MULTI_WS = re.compile(r'\s+')
_RE_PARAGRAPH_SPLIT = re.compile(r'\n\s*\n')
_RE_INLINE_NEWLINE = re.compile(r'(?<!\n)\n(?!\n)')  # single newlines inside paragraph


def _clean_text(s: str) -> str:
    if s is None:
        return ""
    # Normalize carriage returns and whitespace
    s = s.replace('\r', '\n')
    # merge single-line breaks inside paragraphs into spaces
    s = _RE_INLINE_NEWLINE.sub(' ', s)
    # collapse multiple whitespace to single space
    s = _RE_MULTI_WS.sub(' ', s)
    return s.strip()


class PDFExtractor:
    """Extract and preprocess text from PDF files"""

    def __init__(self, pdf_path):
        self.pdf_path = Path(pdf_path)
        self.pages = {}
        self.passages = []

    def extract_text(self):
        """Extract text from all pages"""
        with open(self.pdf_path, 'rb') as f:
            reader = PyPDF2.PdfReader(f)
            num_pages = len(reader.pages)

            print(f"Extracting text from {num_pages} pages...")

            for i in range(num_pages):
                page = reader.pages[i]
                try:
                    text = page.extract_text()
                except Exception:
                    # Be robust to PyPDF2 oddities
                    text = ""
                text = _clean_text(text)
                self.pages[i + 1] = text

        print(f"Extracted text from {len(self.pages)} pages")
        return self.pages

    def _paragraph_to_passages(self, page_num, para, passage_id, min_words, max_words):
        """Return list of passage dicts from a paragraph string"""
        para = para.strip()
        if not para:
            return [], passage_id

        words = para.split()
        wc = len(words)
        out = []

        if min_words <= wc <= max_words:
            out.append({
                'id': passage_id,
                'page': page_num,
                'text': para,
                'word_count': wc
            })
            passage_id += 1
            return out, passage_id

        # If paragraph too long, split with sliding window
        if wc > max_words:
            start = 0
            while start < wc:
                end = min(start + SLIDING_WINDOW_WORDS, wc)
                chunk_words = words[start:end]
                chunk_text = " ".join(chunk_words)
                chunk_wc = len(chunk_words)
                if chunk_wc >= min_words:
                    out.append({
                        'id': passage_id,
                        'page': page_num,
                        'text': chunk_text,
                        'word_count': chunk_wc
                    })
                    passage_id += 1
                if end == wc:
                    break
                start += SLIDING_WINDOW_STEP
            return out, passage_id

        # If too short -> ignore (keeps passages meaningful)
        return [], passage_id

    def split_into_passages(self, min_words=MIN_WORDS, max_words=MAX_WORDS):
        """
        Split text into passages based on paragraphs and sliding-window fallback
        """
        passage_id = 0
        for page_num, text in self.pages.items():
            if not text:
                continue
            paragraphs = _RE_PARAGRAPH_SPLIT.split(text)
            for para in paragraphs:
                para = para.strip()
                if not para:
                    continue
                new_passages, passage_id = self._paragraph_to_passages(
                    page_num, para, passage_id, min_words, max_words
                )
                if new_passages:
                    self.passages.extend(new_passages)

        print(f"Created {len(self.passages)} passages")
        return self.passages

    def save_passages(self, output_path):
        """Save passages to JSON file"""
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump({
                'pdf_file': str(self.pdf_path),
                'total_pages': len(self.pages),
                'total_passages': len(self.passages),
                'passages': self.passages
            }, f, indent=2, ensure_ascii=False)

        print(f"Saved passages to {output_path}")

    def save_passages_txt(self, output_path):
        """Save passages to plain text file (one per line): page|id|text"""
        output_path = Path(output_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(output_path, 'w', encoding='utf-8') as f:
            for passage in self.passages:
                # Format: page|id|text
                line = f"{passage['page']}|{passage['id']}|{passage['text'].replace(chr(10), ' ')}\n"
                f.write(line)

        print(f"Saved {len(self.passages)} passages to {output_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python src/extract_pdf.py <pdf_file> [output_json] [output_txt]")
        print("\nExample:")
        print("  python src/extract_pdf.py data/Morgan_2030.pdf data/passages.json data/passages.txt")
        sys.exit(1)

    pdf_path = sys.argv[1]
    output_json = sys.argv[2] if len(sys.argv) > 2 else 'data/passages.json'
    output_txt = sys.argv[3] if len(sys.argv) > 3 else 'data/passages.txt'

    # Validate PDF exists
    if not Path(pdf_path).exists():
        print(f"Error: PDF file not found: {pdf_path}")
        sys.exit(1)

    # Extract and process
    extractor = PDFExtractor(pdf_path)
    extractor.extract_text()
    extractor.split_into_passages()

    # Save outputs
    extractor.save_passages(output_json)
    extractor.save_passages_txt(output_txt)

    # Print statistics
    print("\n" + "=" * 60)
    print("EXTRACTION COMPLETE")
    print("=" * 60)
    print(f"Total pages: {len(extractor.pages)}")
    print(f"Total passages: {len(extractor.passages)}")
    if extractor.passages:
        avg_words = sum(p['word_count'] for p in extractor.passages) / len(extractor.passages)
        print(f"Average words per passage: {avg_words:.1f}")


if __name__ == "__main__":
    main()
