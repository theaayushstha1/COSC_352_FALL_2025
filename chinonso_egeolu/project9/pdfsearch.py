#!/usr/bin/env python3
"""
PDF Search Tool - Mojo-style implementation in Python
Uses TF-IDF ranking for relevance scoring
"""

import sys
import re
from math import log, sqrt
from typing import List, Tuple
import PyPDF2

class Passage:
    """Represents a text passage from the PDF"""
    def __init__(self, text: str, page: int):
        self.text = text
        self.page = page
        self.score = 0.0

def tokenize(text: str) -> List[str]:
    """Split text into lowercase words, removing punctuation"""
    # Remove non-alphanumeric characters and convert to lowercase
    words = re.findall(r'\b[a-z0-9]+\b', text.lower())
    
    # Filter out very common stop words (optional but improves results)
    stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'}
    return [w for w in words if w not in stop_words and len(w) > 2]

def term_frequency(passage_words: List[str], term: str) -> float:
    """
    Calculate term frequency with logarithmic scaling
    - More occurrences = higher score
    - Diminishing returns (log scaling)
    - Normalized by passage length
    """
    count = sum(1 for w in passage_words if w == term)
    
    if count > 0:
        # Log scaling for diminishing returns
        return (1.0 + log(count)) / len(passage_words)
    return 0.0

def inverse_document_frequency(passages: List[Passage], term: str) -> float:
    """
    Calculate IDF - rare terms are more valuable
    - Terms appearing in fewer passages score higher
    - Common terms across all passages score lower
    """
    doc_count = 0
    for passage in passages:
        words = tokenize(passage.text)
        if term in words:
            doc_count += 1
    
    if doc_count > 0:
        return log(len(passages) / doc_count)
    return 0.0

def calculate_tfidf_score(passage: Passage, query_terms: List[str], all_passages: List[Passage]) -> float:
    """
    Calculate TF-IDF score for ranking
    
    Addresses requirements:
    1. More mentions = higher score (TF with log scaling)
    2. Rare terms matter more (IDF)
    3. Length normalization prevents long passage bias
    """
    passage_words = tokenize(passage.text)
    
    # Length normalization - prevent longer passages from dominating
    length_norm = 1.0 / sqrt(len(passage_words)) if passage_words else 0.0
    
    score = 0.0
    for term in query_terms:
        tf = term_frequency(passage_words, term)
        idf = inverse_document_frequency(all_passages, term)
        score += tf * idf
    
    return score * length_norm

def extract_pdf_text(filepath: str) -> List[Tuple[str, int]]:
    """Extract text from PDF, returning (text, page_number) tuples"""
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
    """
    Split PDF pages into passages
    
    A "passage" is defined as:
    - 3-4 sentences grouped together
    - Provides enough context for relevance
    - Not too long to lose focus
    """
    passages = []
    
    for page_text, page_num in pages:
        # Split on sentence boundaries (periods followed by space/newline)
        sentences = re.split(r'\.[\s\n]+', page_text)
        
        # Group sentences into passages
        for i in range(0, len(sentences), sentences_per_passage):
            passage_text = '. '.join(sentences[i:i + sentences_per_passage])
            
            # Only keep passages with reasonable length
            if len(passage_text) > 50:
                passages.append(Passage(passage_text.strip(), page_num))
    
    return passages

def rank_passages(passages: List[Passage], query: str) -> List[Passage]:
    """Rank passages by TF-IDF relevance score"""
    query_terms = tokenize(query)
    
    # Calculate scores
    for passage in passages:
        passage.score = calculate_tfidf_score(passage, query_terms, passages)
    
    # Sort by score descending
    return sorted(passages, key=lambda p: p.score, reverse=True)

def display_results(query: str, ranked_passages: List[Passage], num_results: int):
    """Display top N search results"""
    print(f'\nResults for: "{query}"\n')
    
    count = 0
    for i, passage in enumerate(ranked_passages[:num_results]):
        # Only show passages with non-zero scores
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
        print('Example: ./pdfsearch Morgan_2030.pdf "gradient descent optimization" 3')
        sys.exit(1)
    
    pdf_file = sys.argv[1]
    query = sys.argv[2]
    num_results = int(sys.argv[3])
    
    print("Extracting text from PDF...")
    pages = extract_pdf_text(pdf_file)
    print(f"Loaded {len(pages)} pages")
    
    print("Creating passages...")
    passages = create_passages(pages)
    print(f"Created {len(passages)} passages")
    
    print("Ranking passages...")
    ranked = rank_passages(passages, query)
    
    display_results(query, ranked, num_results)

if __name__ == "__main__":
    main()