#!/usr/bin/env python3
import sys
import math
from PyPDF2 import PdfReader

def extract_text_from_pdf(pdf_path):
    with open(pdf_path, 'rb') as f:
        reader = PdfReader(f)
        pages = []
        for page in reader.pages:
            pages.append(page.extract_text())
    return pages

def tokenize(text):
    tokens = []
    current = ""
    for c in text.lower():
        if c.isalnum():
            current += c
        elif current:
            tokens.append(current)
            current = ""
    if current:
        tokens.append(current)
    return tokens

def create_passages(pages):
    passages = []
    for page_num, page_text in enumerate(pages, 1):
        start = 0
        while start < len(page_text):
            end = min(start + 300, len(page_text))
            passage = page_text[start:end]
            if len(passage.strip()) > 20:
                passages.append({'text': passage, 'page': page_num})
            start += 250
            if end >= len(page_text):
                break
    return passages

def score_passage(passage, query_terms):
    text_lower = passage['text'].lower()
    score = 0.0
    for term in query_terms:
        count = text_lower.count(term)
        if count > 0:
            score += math.log(count + 1)
    return score

def search(passages, query, top_n):
    query_terms = tokenize(query)
    results = []
    
    for passage in passages:
        score = score_passage(passage, query_terms)
        if score > 0:
            results.append({'passage': passage, 'score': score})
    
    results.sort(key=lambda x: x['score'], reverse=True)
    return results[:top_n]

def format_text(text, max_len=200):
    clean = ' '.join(text.split())
    if len(clean) > max_len:
        return clean[:max_len] + "..."
    return clean

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 pdfsearch.py <pdf_file> <query> <top_n>")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3])
    
    print(f"Loading PDF: {pdf_path}")
    pages = extract_text_from_pdf(pdf_path)
    print(f"Extracted {len(pages)} pages")
    
    print("Creating passages...")
    passages = create_passages(pages)
    print(f"Created {len(passages)} passages")
    
    print("Searching...")
    results = search(passages, query, top_n)
    
    print(f"\nResults for: \"{query}\"\n")
    
    for i, result in enumerate(results, 1):
        print(f"[{i}] Score: {result['score']:.2f} (page {result['passage']['page']})")
        print(f"    \"{format_text(result['passage']['text'])}\"")
        print()

if __name__ == "__main__":
    main()
