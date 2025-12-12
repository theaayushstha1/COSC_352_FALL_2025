#!/usr/bin/env python3
"""
PDF Search Tool with TF-IDF Ranking
Python fallback implementation
"""

import sys
import math
import PyPDF2

def normalize_text(text):
    """Normalize text to lowercase and remove special characters."""
    result = []
    for c in text:
        if c.isalpha():
            result.append(c.lower())
        elif c.isdigit():
            result.append(c)
        else:
            result.append(' ')
    return ''.join(result)

def tokenize(text):
    """Split text into words."""
    return [word for word in text.split() if word]

def is_stop_word(word):
    """Check if word is a common stop word."""
    stop_words = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
        'to', 'for', 'of', 'with', 'by', 'from', 'as', 'is',
        'was', 'are', 'were', 'be', 'been', 'being', 'have',
        'has', 'had', 'do', 'does', 'did', 'will', 'would'
    }
    return word.lower() in stop_words

def extract_passages(pages, window_size=3):
    """Extract passages from pages using sliding window."""
    passages = []
    passage_pages = []
    
    for page_num, page_text in enumerate(pages):
        # Split into sentences
        sentences = []
        current = ""
        
        for i, c in enumerate(page_text):
            current += c
            if c == '.' and i + 1 < len(page_text):
                if page_text[i + 1] in ' \n':
                    if len(current.strip()) > 20:
                        sentences.append(current)
                    current = ""
        
        # Create overlapping windows
        for i in range(len(sentences) - window_size + 1):
            passage = ''.join(sentences[i:i + window_size])
            passages.append(passage)
            passage_pages.append(page_num + 1)
    
    return passages, passage_pages

def calculate_tf_idf_score(passage, query_terms):
    """Calculate TF-IDF score for a passage."""
    passage_lower = normalize_text(passage)
    passage_tokens = tokenize(passage_lower)
    
    score = 0.0
    
    for term in query_terms:
        if is_stop_word(term):
            continue
        
        # Count term frequency
        count = passage_tokens.count(term)
        
        if count > 0:
            # TF with logarithmic scaling
            tf = 1.0 + math.log(count)
            score += tf
    
    # Normalize by passage length
    if len(passage_tokens) > 0:
        score = score / math.sqrt(len(passage_tokens))
    
    return score

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 pdfsearch.py <pdf_file> <query> <num_results>")
        print('Example: python3 pdfsearch.py document.pdf "research university" 3')
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3])
    
    print("\n╔══════════════════════════════════════════════════════════════╗")
    print("║  PDF Search Tool - Python with TF-IDF Ranking               ║")
    print("╚══════════════════════════════════════════════════════════════╝\n")
    
    # Extract PDF text
    print("Extracting text from PDF...")
    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        num_pages = len(reader.pages)
        print(f"Total pages: {num_pages}")
        
        pages = []
        for i, page in enumerate(reader.pages):
            text = page.extract_text()
            pages.append(text)
            
            if (i + 1) % 10 == 0:
                print(f"  Processed {i + 1} pages...")
    
    # Extract passages
    print("\nExtracting passages...")
    passages, passage_pages = extract_passages(pages)
    print(f"Total passages: {len(passages)}")
    
    # Tokenize query
    query_normalized = normalize_text(query)
    query_terms = tokenize(query_normalized)
    
    print(f'\nSearching for: "{query}"')
    print(f"Query terms: {len(query_terms)}")
    
    # Score passages
    print("Scoring passages...")
    scored_passages = []
    
    for i, passage in enumerate(passages):
        score = calculate_tf_idf_score(passage, query_terms)
        if score > 0:
            scored_passages.append({
                'passage': passage,
                'page': passage_pages[i],
                'score': score
            })
    
    # Sort by score
    print("Ranking results...")
    scored_passages.sort(key=lambda x: x['score'], reverse=True)
    
    # Display top N
    print("\n" + "="*70)
    print(f'Results for: "{query}"')
    print("="*70 + "\n")
    
    if not scored_passages:
        print("No relevant passages found.")
    else:
        for rank, result in enumerate(scored_passages[:top_n], 1):
            passage = result['passage']
            page = result['page']
            score = result['score']
            
            print(f"[{rank}] Score: {score:.2f} (page {page})")
            
            # Clean and truncate passage
            snippet = passage.replace('\n', ' ').replace('  ', ' ')
            if len(snippet) > 200:
                snippet = snippet[:197] + "..."
            
            print(f'    "{snippet}"\n')
    
    print("\n╔══════════════════════════════════════════════════════════════╗")
    print("║  Search Complete                                             ║")
    print("╚══════════════════════════════════════════════════════════════╝\n")

if __name__ == "__main__":
    main()