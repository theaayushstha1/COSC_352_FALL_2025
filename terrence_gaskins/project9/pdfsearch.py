"""
PDF Search Tool (Custom TF-IDF Ranking)
No external search libraries - implemented from scratch
"""

import math
import argparse
from typing import List, Dict
import pypdf

# -----------------------------
# Data structure for text chunks
# -----------------------------
class Chunk:
    def __init__(self, text: str, page: int):
        self.text = text
        self.page = page
        self.score: float = 0.0

    def __repr__(self):
        return f"<Chunk page={self.page} score={self.score:.2f}>"

# -----------------------------
# Stopword list
# -----------------------------
STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
    "be", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "must", "can", "this", "that",
    "these", "those", "it", "its", "they", "them", "their", "we", "our"
}

# -----------------------------
# Tokenization
# -----------------------------
def tokenize(text: str) -> List[str]:
    tokens = []
    word = []
    for ch in text:
        if ch.isalnum():
            word.append(ch.lower())
        else:
            if word:
                tokens.append("".join(word))
                word = []
    if word:
        tokens.append("".join(word))
    return tokens

# -----------------------------
# TF and IDF
# -----------------------------
def tf(term: str, tokens: List[str]) -> float:
    count = tokens.count(term)
    return math.log(1 + count) if count > 0 else 0.0

def idf(term: str, chunks: List[Chunk]) -> float:
    total = len(chunks)
    containing = sum(1 for c in chunks if term in tokenize(c.text))
    # Smooth IDF: log((N+1)/(df+1)) + 1
    return math.log((total + 1) / (containing + 1)) + 1

# -----------------------------
# Scoring function
# -----------------------------
def score_chunk(chunk: Chunk, query_terms: List[str], idf_cache: Dict[str, float]) -> float:
    tokens = tokenize(chunk.text)
    score = 0.0
    for term in query_terms:
        if term not in STOPWORDS:
            score += tf(term, tokens) * idf_cache.get(term, 0.0)
    # Normalize by passage length
    return score / math.sqrt(len(tokens) + 1)

# -----------------------------
# PDF extraction
# -----------------------------
def extract_chunks(pdf_path: str) -> List[Chunk]:
    reader = pypdf.PdfReader(pdf_path)
    chunks: List[Chunk] = []
    for i, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        # Split into smaller chunks by double newline
        for para in text.split("\n\n"):
            if para.strip():
                chunks.append(Chunk(para.strip(), i))
    return chunks

# -----------------------------
# Main CLI
# -----------------------------
def main():
    parser = argparse.ArgumentParser(description="Search PDF with TF-IDF ranking")
    parser.add_argument("pdf_file", help="Path to PDF file")
    parser.add_argument("query", help="Search query string")
    parser.add_argument("num_results", type=int, help="Number of results to show")
    args = parser.parse_args()

    chunks = extract_chunks(args.pdf_file)
    if not chunks:
        print("No text extracted from PDF.")
        return

    query_terms = tokenize(args.query)
    filtered_terms = [t for t in query_terms if t not in STOPWORDS]
    if not filtered_terms:
        print("Query contains only stopwords.")
        return

    # Precompute IDF
    idf_cache = {t: idf(t, chunks) for t in filtered_terms}

    # Score each chunk
    for c in chunks:
        c.score = score_chunk(c, filtered_terms, idf_cache)

    # Sort by score
    ranked = sorted(chunks, key=lambda c: c.score, reverse=True)

    print(f'\nResults for: "{args.query}"')
    print("=" * 70)
    for i, c in enumerate(ranked[:args.num_results], start=1):
        if c.score > 0:
            snippet = c.text.replace("\n", " ")
            if len(snippet) > 180:
                snippet = snippet[:177] + "..."
            print(f"\n[{i}] Score: {c.score:.2f} (page {c.page})")
            print(f'    "{snippet}"')

if __name__ == "__main__":
    main()
