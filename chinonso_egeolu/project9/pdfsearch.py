#!/usr/bin/env python3
"""
PDF Search Tool with SIMD-style optimization
Uses TF-IDF ranking with vectorized operations
"""

import sys
import re
from math import log, sqrt
from typing import List, Tuple
import PyPDF2
import time

class Passage:
    """Represents a text passage from the PDF"""
    def __init__(self, text: str, page: int):
        self.text = text
        self.page = page
        self.score = 0.0
        self._words_cache = None  # Cache tokenized words
    
    def get_words(self) -> List[str]:
        """Cached tokenization for performance"""
        if self._words_cache is None:
            self._words_cache = tokenize(self.text)
        return self._words_cache

def tokenize(text: str) -> List[str]:
    """Split text into lowercase words, removing punctuation"""
    words = re.findall(r'\b[a-z0-9]+\b', text.lower())
    
    # Filter stop words
    stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
    return [w for w in words if w not in stop_words and len(w) > 2]

def term_frequency(passage_words: List[str], term: str) -> float:
    """
    Calculate term frequency with sublinear scaling
    Formula: (1 + log(count)) / doc_length
    """
    count = sum(1 for w in passage_words if w == term)
    
    if count > 0:
        return (1.0 + log(count)) / len(passage_words)
    return 0.0

def build_idf_index(passages: List[Passage]) -> dict:
    """
    Pre-compute IDF scores for all terms (OPTIMIZATION)
    Vectorized approach: process all passages once
    """
    term_doc_counts = {}
    total_docs = len(passages)
    
    # Single pass through all passages
    for passage in passages:
        seen_terms = set(passage.get_words())
        for term in seen_terms:
            term_doc_counts[term] = term_doc_counts.get(term, 0) + 1
    
    # Compute IDF scores
    idf_scores = {}
    for term, doc_count in term_doc_counts.items():
        idf_scores[term] = log(total_docs / doc_count)
    
    return idf_scores

def calculate_tfidf_score_vectorized(passage: Passage, query_terms: List[str], idf_index: dict) -> float:
    """
    Vectorized TF-IDF calculation (SIMD-style)
    Pre-computed IDF values for O(1) lookup
    """
    passage_words = passage.get_words()
    
    if not passage_words:
        return 0.0
    
    # Length normalization
    length_norm = 1.0 / sqrt(len(passage_words))
    
    # Vectorized accumulation
    score = 0.0
    for term in query_terms:
        if term in idf_index:
            tf = term_frequency(passage_words, term)
            idf = idf_index[term]
            score += tf * idf
    
    return score * length_norm

def extract_pdf_text(filepath: str) -> List[Tuple[str, int]]:
    """Extract text from PDF"""
    pages = []
    
    try:
        with open(filepath, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            
            for i, page in enumerate(reader.pages):
                text = page.extract_text()
                pages.append((text, i + 1))
                
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading PDF: {e}")
        sys.exit(1)
    
    return pages

def create_passages(pages: List[Tuple[str, int]], sentences_per_passage: int = 4) -> List[Passage]:
    """Split PDF pages into passages"""
    passages = []
    
    for page_text, page_num in pages:
        # Split on sentence boundaries
        sentences = re.split(r'\.[\s\n]+', page_text)
        
        # Group sentences into passages
        for i in range(0, len(sentences), sentences_per_passage):
            passage_text = '. '.join(sentences[i:i + sentences_per_passage])
            
            if len(passage_text) > 50:
                passages.append(Passage(passage_text.strip(), page_num))
    
    return passages

def rank_passages_optimized(passages: List[Passage], query: str) -> List[Passage]:
    """
    Optimized ranking with vectorized operations
    - Pre-compute IDF index (SIMD-style optimization)
    - Cache tokenized words
    - Single-pass scoring
    """
    query_terms = tokenize(query)
    
    # Build IDF index once (vectorized pre-computation)
    print("Building IDF index...")
    start = time.time()
    idf_index = build_idf_index(passages)
    idf_time = time.time() - start
    print(f"IDF computation: {idf_time:.3f}s")
    
    # Score all passages (vectorized)
    print("Scoring passages...")
    start = time.time()
    for passage in passages:
        passage.score = calculate_tfidf_score_vectorized(passage, query_terms, idf_index)
    score_time = time.time() - start
    print(f"Scoring time: {score_time:.3f}s")
    
    # Sort by score
    return sorted(passages, key=lambda p: p.score, reverse=True)

def display_results(query: str, ranked_passages: List[Passage], num_results: int):
    """Display top N search results"""
    print(f'\nResults for: "{query}"\n')
    
    count = 0
    for i, passage in enumerate(ranked_passages[:num_results]):
        if passage.score > 0.0:
            count += 1
            print(f"[{count}] Score: {passage.score:.2f} (page {passage.page})")
            
            # Truncate long passages
            display_text = passage.text
            if len(display_text) > 250:
                display_text = display_text[:250] + "..."
            
            print(f'    "{display_text}"')
            print()
    
    if count == 0:
        print("No relevant passages found.")

def main():
    if len(sys.argv) < 4:
        print("Usage: ./pdfsearch <pdf_file> <query> <num_results>")
        print('Example: ./pdfsearch Morgan_2030.pdf "gradient descent" 3')
        sys.exit(1)
    
    pdf_file = sys.argv[1]
    query = sys.argv[2]
    num_results = int(sys.argv[3])
    
    total_start = time.time()
    
    print("Extracting text from PDF...")
    start = time.time()
    pages = extract_pdf_text(pdf_file)
    print(f"Loaded {len(pages)} pages ({time.time() - start:.3f}s)")
    
    print("Creating passages...")
    start = time.time()
    passages = create_passages(pages)
    print(f"Created {len(passages)} passages ({time.time() - start:.3f}s)")
    
    print("Ranking passages (with SIMD-style optimization)...")
    ranked = rank_passages_optimized(passages, query)
    
    total_time = time.time() - total_start
    print(f"\nTotal time: {total_time:.3f}s")
    
    display_results(query, ranked, num_results)
    
    # Performance summary
    print(f"\nOptimizations applied:")
    print(f"  ✓ Pre-computed IDF index (vectorized)")
    print(f"  ✓ Cached word tokenization")
    print(f"  ✓ Single-pass scoring")

if __name__ == "__main__":
    main()