"""
PDF Search Tool using TF-IDF ranking
No external search libraries - implements core algorithm from scratch
"""

import sys
import math
from collections import defaultdict
from typing import List, Dict, Tuple
import pypdf

class Passage:
    """Represents a text passage from the PDF"""
    def __init__(self, text: str, page: int):
        self.text = text
        self.page = page
        self.score = 0.0

STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
    "be", "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "must", "can", "this", "that",
    "these", "those", "it", "its", "they", "them", "their"
}

def tokenize(text: str) -> List[str]:
    """Convert text to lowercase tokens (words)"""
    tokens = []
    current_word = ""
    
    for char in text:
        if char.isalnum():
            current_word += char.lower()
        else:
            if current_word:
                tokens.append(current_word)
                current_word = ""
    
    if current_word:
        tokens.append(current_word)
    
    return tokens

def calculate_tf(term: str, tokens: List[str]) -> float:
    """Calculate term frequency with sublinear scaling"""
    count = sum(1 for t in tokens if t == term)
    
    if count > 0:
        return 1.0 + math.log(count)
    return 0.0

def calculate_idf(term: str, all_passages: List[Passage]) -> float:
    """Calculate inverse document frequency"""
    doc_count = 0
    total_docs = len(all_passages)
    
    for passage in all_passages:
        tokens = tokenize(passage.text)
        if term in tokens:
            doc_count += 1
    
    # IDF formula: log(N / df)
    if doc_count > 0:
        return math.log(total_docs / doc_count)
    return 0.0

def calculate_relevance(query_terms: List[str], passage: Passage, 
                       idf_cache: Dict[str, float]) -> float:
    """Calculate TF-IDF relevance score between query and passage"""
    passage_tokens = tokenize(passage.text)
    score = 0.0
    
    passage_terms = set(t for t in passage_tokens if t not in STOPWORDS)
    
    for term in query_terms:
        if term in STOPWORDS:
            continue
        
        tf = calculate_tf(term, passage_tokens)
        idf = idf_cache.get(term, 0.0)
        tfidf = tf * idf
        
        score += tfidf
    
    if len(passage_terms) > 0:
        score = score / math.sqrt(len(passage_terms))
    
    return score

def extract_pdf_text(filepath: str) -> List[Passage]:
    """Extract text from PDF file"""
    passages = []
    
    try:
        reader = pypdf.PdfReader(filepath)
        num_pages = len(reader.pages)
        
        for page_num in range(num_pages):
            page = reader.pages[page_num]
            text = page.extract_text()
            
            if text.strip():
                passages.append(Passage(text, page_num + 1))
        
    except Exception as e:
        print(f"Error reading PDF: {e}")
        sys.exit(1)
    
    return passages

def main():
    if len(sys.argv) < 4:
        print("Usage: python pdfsearch.py <pdf_file> <query> <num_results>")
        print('Example: python pdfsearch.py document.pdf "gradient descent" 3')
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    query = sys.argv[2]
    num_results = int(sys.argv[3])
    
    print("Extracting text from PDF...")
    passages = extract_pdf_text(pdf_path)
    
    if not passages:
        print("Error: No text extracted from PDF")
        sys.exit(1)
    
    print(f"Indexing {len(passages)} passages...")
    
    query_terms = tokenize(query)
    filtered_query = [t for t in query_terms if t not in STOPWORDS]
    
    if not filtered_query:
        print("Error: Query contains only stopwords")
        sys.exit(1)
    
    print("Calculating IDF scores...")
    idf_cache = {}
    for term in filtered_query:
        idf_cache[term] = calculate_idf(term, passages)
    
    print("Ranking passages by relevance...")
    for passage in passages:
        passage.score = calculate_relevance(filtered_query, passage, idf_cache)
    
    passages.sort(key=lambda p: p.score, reverse=True)
    
    print(f'\nResults for: "{query}"')
    print("=" * 70)
    
    results_to_show = min(num_results, len(passages))
    found_results = False
    
    for i in range(results_to_show):
        p = passages[i]
        if p.score > 0:
            found_results = True
            print(f"\n[{i + 1}] Score: {p.score:.2f} (page {p.page})")
            
            snippet = p.text.strip().replace("\n", " ")
            if len(snippet) > 200:
                snippet = snippet[:197] + "..."
            
            print(f'    "{snippet}"')
    
    if not found_results:
        print("\nNo relevant passages found for query terms.")

if __name__ == "__main__":
    main()