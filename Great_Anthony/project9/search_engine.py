#!/usr/bin/env python3
import sys
import math
import re

class Passage:
    def __init__(self, id, page, content):
        self.id = id
        self.page = page
        self.content = content
        self.score = 0.0

def read_file(filepath):
    """Read entire file content"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        return f.read()

def split_into_passages(text):
    """Split extracted text into passages based on paragraph breaks"""
    passages = []
    current_passage = ""
    passage_id = 0
    current_page = 1
    
    lines = text.split('\n')
    
    for line in lines:
        # Detect page breaks (form feed character)
        if '\f' in line:
            if current_passage.strip():
                passages.append(Passage(passage_id, current_page, current_passage.strip()))
                passage_id += 1
                current_passage = ""
            current_page += 1
            continue
        
        stripped_line = line.strip()
        
        # Empty line marks paragraph boundary
        if not stripped_line:
            if len(current_passage.strip()) > 10:  # Minimum passage length
                passages.append(Passage(passage_id, current_page, current_passage.strip()))
                passage_id += 1
                current_passage = ""
        else:
            if current_passage:
                current_passage += " " + stripped_line
            else:
                current_passage = stripped_line
    
    # Add final passage
    if len(current_passage.strip()) > 10:
        passages.append(Passage(passage_id, current_page, current_passage.strip()))
    
    return passages

def tokenize(text):
    """Tokenize text into lowercase words"""
    # Convert to lowercase
    text = text.lower()
    
    # Remove punctuation and split
    text = re.sub(r'[,.:;!?()\"\']', ' ', text)
    tokens = text.split()
    
    return [token for token in tokens if token]

def count_occurrences(term, tokens):
    """Count how many times a term appears in token list"""
    return tokens.count(term.lower())

def calculate_idf(term, passages):
    """Calculate Inverse Document Frequency"""
    doc_count = 0
    term_lower = term.lower()
    
    for passage in passages:
        if term_lower in passage.content.lower():
            doc_count += 1
    
    if doc_count == 0:
        return 0.0
    
    total_docs = len(passages)
    return math.log(total_docs / doc_count)

def calculate_tf_idf(passage_tokens, query_terms, idf_scores):
    """
    Calculate TF-IDF score with:
    1. Diminishing returns (sublinear TF scaling)
    2. IDF weighting for rare terms
    3. Length normalization
    """
    score = 0.0
    passage_length = len(passage_tokens)
    
    if passage_length == 0:
        return 0.0
    
    # Length normalization factor
    length_norm = math.sqrt(passage_length)
    
    for i, term in enumerate(query_terms):
        tf = count_occurrences(term, passage_tokens)
        
        if tf > 0:
            # Sublinear TF scaling: 1 + log(tf) for diminishing returns
            scaled_tf = 1.0 + math.log(tf)
            
            # Get IDF score
            idf = idf_scores[i]
            
            # TF-IDF with length normalization
            tf_idf = (scaled_tf / length_norm) * idf
            
            score += tf_idf
    
    return score

def rank_passages(passages, query):
    """Rank passages using TF-IDF algorithm"""
    query_terms = tokenize(query)
    
    # Calculate IDF for each query term
    idf_scores = [calculate_idf(term, passages) for term in query_terms]
    
    # Calculate score for each passage
    for passage in passages:
        passage_tokens = tokenize(passage.content)
        passage.score = calculate_tf_idf(passage_tokens, query_terms, idf_scores)

def main():
    # Parse command-line arguments
    if len(sys.argv) != 4:
        print("Error: Expected 3 arguments")
        print("Usage: python3 search_engine.py <text_file> <query> <num_results>")
        sys.exit(1)
    
    text_file = sys.argv[1]
    query = sys.argv[2]
    num_results = int(sys.argv[3])
    
    # Read extracted text
    print("Reading extracted text...")
    text = read_file(text_file)
    
    # Split into passages
    print("Splitting into passages...")
    passages = split_into_passages(text)
    
    if not passages:
        print("Error: No passages found in document")
        sys.exit(1)
    
    print(f"Found {len(passages)} passages")
    
    # Rank passages
    print("Ranking passages by relevance...")
    rank_passages(passages, query)
    
    # Sort by score (descending)
    passages.sort(key=lambda p: p.score, reverse=True)
    
    # Display results
    print(f'\nResults for: "{query}"')
    print()
    
    results_to_show = min(num_results, len(passages))
    shown = 0
    
    for passage in passages:
        if shown >= results_to_show:
            break
        
        if passage.score > 0.0:
            shown += 1
            print(f"[{shown}] Score: {passage.score:.4f} (page {passage.page})")
            
            # Truncate content to ~200 characters
            display_content = passage.content
            if len(display_content) > 200:
                display_content = display_content[:200] + "..."
            
            print(f'    "{display_content}"')
            print()
    
    if shown == 0:
        print(f'No relevant passages found for query: "{query}"')

if __name__ == "__main__":
    main()
