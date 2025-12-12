# Extracts text from PDF
# Split into passages (paragraphs)
# Track page numbers
# Save to JSON for Mojo to read
# NEW: TF-IDF search engine for searching passages

import sys
import json
import math
import re
from pathlib import Path

# PDF parsing library
try:
    import pypdf
    HAS_PYPDF = True
except ImportError:
    HAS_PYPDF = False
    print("⚠️  Warning: pypdf not installed. Run: pixi add pypdf")


# ============================================================================
# PDF EXTRACTION (Original Project 9 functionality)
# ============================================================================

def extract_text_from_pdf(pdf_path):
    """
    Extract text from PDF file page by page.
    Returns list of (page_number, text) tuples.
    """
    if not HAS_PYPDF:
        print("❌ pypdf library is required but not installed.")
        return None
    
    try:
        print(f"📖 Opening PDF: {pdf_path}")
        
        with open(pdf_path, 'rb') as file:
            reader = pypdf.PdfReader(file)
            num_pages = len(reader.pages)
            
            print(f"✅ PDF loaded successfully! Total pages: {num_pages}")
            
            pages_data = []
            for page_num in range(num_pages):
                page = reader.pages[page_num]
                text = page.extract_text()
                
                if text.strip():  # Only include pages with text
                    pages_data.append((page_num + 1, text))  # 1-indexed pages
                    print(f"  - Extracted page {page_num + 1}: {len(text)} characters")
                else:
                    print(f"  - Skipping page {page_num + 1}: No text found")
            
            print(f"✅ Successfully extracted {len(pages_data)} pages with text")
            return pages_data
            
    except FileNotFoundError:
        print(f"❌ Error: PDF file not found at {pdf_path}")
        return None
    except Exception as e:
        print(f"❌ Error reading PDF: {e}")
        import traceback
        traceback.print_exc()
        return None


def split_into_passages(pages_data, method='paragraph'):
    """
    Split extracted text into searchable passages.
    Similar to how you extracted rows from tables, but for text!
    
    Args:
        pages_data: List of (page_num, text) tuples
        method: 'paragraph' or 'fixed' (fixed-size chunks)
    
    Returns:
        List of dicts: [{"text": "...", "page": 5}, ...]
    """
    print(f"\n{'='*60}")
    print(f"Splitting text into passages (method: {method})...")
    print(f"{'='*60}")
    
    all_passages = []
    
    for page_num, page_text in pages_data:
        if method == 'paragraph':
            # Split by double newlines (paragraphs)
            paragraphs = page_text.split('\n\n')
            
            for para in paragraphs:
                # Clean up whitespace
                cleaned = ' '.join(para.strip().split())
                
                # Skip if too short (headers, page numbers, etc.)
                if len(cleaned.split()) < 10:  # At least 10 words
                    continue
                
                # Skip if looks like a header or title
                if cleaned.isupper() and len(cleaned.split()) < 15:
                    continue
                
                passage = {
                    "text": cleaned,
                    "page": page_num,
                    "word_count": len(cleaned.split())
                }
                all_passages.append(passage)
        
        elif method == 'fixed':
            # Fixed-size chunks (e.g., 200 words)
            words = page_text.split()
            chunk_size = 200
            
            for i in range(0, len(words), chunk_size):
                chunk = ' '.join(words[i:i+chunk_size])
                
                passage = {
                    "text": chunk,
                    "page": page_num,
                    "word_count": len(chunk.split())
                }
                all_passages.append(passage)
    
    print(f"✅ Created {len(all_passages)} passages")
    
    # Show breakdown by page
    page_count = {}
    for p in all_passages:
        page_count[p['page']] = page_count.get(p['page'], 0) + 1
    
    print(f"\n📊 Breakdown by Page (first 5 pages):")
    for page in sorted(page_count.keys())[:5]:
        print(f"  - Page {page}: {page_count[page]} passages")
    
    return all_passages


def save_to_json(passages, filepath):
    """
    Save passages to JSON file.
    Adapted from your save_to_csv() function!
    """
    print(f"\n{'='*60}")
    print(f"Saving to JSON: {filepath}")
    print(f"{'='*60}")
    
    try:
        output_data = {
            "total_passages": len(passages),
            "passages": passages
        }
        
        with open(filepath, 'w', encoding='utf-8') as json_file:
            json.dump(output_data, json_file, indent=2, ensure_ascii=False)
        
        print(f"✅ JSON file '{filepath}' created successfully!")
        print(f"   Total passages: {len(passages)}")
        
        # Show preview (like your CSV preview)
        print(f"\n📋 Preview of first 3 passages:")
        for i, passage in enumerate(passages[:3]):
            preview_text = passage['text'][:80] + "..." if len(passage['text']) > 80 else passage['text']
            print(f"  {i+1}. Page {passage['page']} | Words: {passage['word_count']}")
            print(f"     \"{preview_text}\"")
        
        return True
        
    except Exception as e:
        print(f"❌ Error saving to JSON: {e}")
        import traceback
        traceback.print_exc()
        return False


# ============================================================================
# TF-IDF SEARCH ENGINE (NEW - Added for searching passages)
# ============================================================================

def clean_text(text):
    """Clean text: lowercase, remove punctuation."""
    text = text.lower()
    for char in '.,!?;:()[]"\'-_':
        text = text.replace(char, ' ')
    while '  ' in text:
        text = text.replace('  ', ' ')
    return text.strip()


def is_stopword(word):
    """Check if word is a stopword."""
    stopwords = {
        'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have',
        'i', 'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you',
        'do', 'at', 'this', 'but', 'his', 'by', 'from', 'they',
        'we', 'say', 'her', 'she', 'or', 'an', 'will', 'my', 'one',
        'all', 'would', 'there', 'their', 'what', 'so', 'up', 'out',
        'if', 'about', 'who', 'get', 'which', 'go', 'me', 'when',
        'make', 'can', 'like', 'time', 'no', 'just', 'him', 'know',
        'take', 'into', 'year', 'your', 'some', 'could', 'them',
        'see', 'other', 'than', 'then', 'now', 'look', 'only',
        'come', 'its', 'over', 'also', 'back', 'after', 'use',
        'two', 'how', 'our', 'work', 'first', 'well', 'way',
        'even', 'new', 'want', 'because', 'any', 'these', 'give',
        'day', 'most', 'us', 'is', 'was', 'are'
    }
    return word in stopwords


def preprocess_query(query):
    """Clean query and return list of terms."""
    cleaned = clean_text(query)
    words = cleaned.split()
    terms = [w for w in words if w and not is_stopword(w)]
    return terms


def count_term(text, term):
    """Count occurrences of term in text (case-insensitive)."""
    text_lower = text.lower()
    term_lower = term.lower()
    count = 0
    start = 0
    while True:
        pos = text_lower.find(term_lower, start)
        if pos == -1:
            break
        count += 1
        start = pos + len(term_lower)
    return count


def calculate_idf(total_passages, passages_with_term):
    """Calculate IDF - rare terms get higher weight."""
    if passages_with_term == 0:
        return 0.0
    return math.log(total_passages / passages_with_term)


def calculate_tf(term_count):
    """Calculate TF with diminishing returns using log."""
    if term_count == 0:
        return 0.0
    return math.log(1.0 + term_count)


def search_tfidf(passages_file, query, top_n):
    """
    Perform TF-IDF search on passages.
    
    Algorithm:
    1. Load passages from JSON
    2. Preprocess query (clean, remove stopwords)
    3. Calculate IDF for each query term
    4. Score each passage using TF-IDF
    5. Return top N results sorted by score
    """
    print(f"\n{'='*60}")
    print("TF-IDF SEARCH ENGINE")
    print(f"{'='*60}")
    print(f"Query: {query}")
    print(f"Top N: {top_n}")
    print(f"{'='*60}\n")
    
    # Step 1: Load passages
    print(f"📖 Loading passages from: {passages_file}")
    try:
        with open(passages_file, 'r') as f:
            data = json.load(f)
        passages = data['passages']
        print(f"✅ Loaded {len(passages)} passages\n")
    except FileNotFoundError:
        print(f"❌ Error: File not found: {passages_file}")
        return []
    except Exception as e:
        print(f"❌ Error loading passages: {e}")
        return []
    
    # Step 2: Preprocess query
    print("🔍 Preprocessing query...")
    query_terms = preprocess_query(query)
    print(f"   Query terms: {query_terms}\n")
    
    if not query_terms:
        print("⚠️  No valid search terms after removing stopwords!")
        return []
    
    # Step 3: Calculate IDF for each term
    print("📊 Calculating IDF values for query terms...")
    idf_values = {}
    for term in query_terms:
        passages_with_term = sum(1 for p in passages if term in p['text'].lower())
        idf = calculate_idf(len(passages), passages_with_term)
        idf_values[term] = idf
        print(f"   '{term}': appears in {passages_with_term} passages -> IDF = {idf:.4f}")
    print()
    
    # Step 4: Score all passages
    print(f"⚡ Scoring {len(passages)} passages...")
    scores = []
    for i, passage in enumerate(passages):
        score = 0.0
        
        # Calculate TF-IDF score for this passage
        for term in query_terms:
            term_count = count_term(passage['text'], term)
            if term_count > 0:
                tf = calculate_tf(term_count)
                score += tf * idf_values[term]
        
        # Normalize by passage length (prevents long passages from dominating)
        if passage['word_count'] > 0:
            score = score / math.sqrt(passage['word_count'])
        
        scores.append((score, i))
    
    print(f"✅ Scoring complete!\n")
    
    # Step 5: Sort and get top N
    print("🔄 Sorting results by relevance...")
    scores.sort(reverse=True, key=lambda x: x[0])
    
    results = []
    for i in range(min(top_n, len(scores))):
        score, idx = scores[i]
        passage = passages[idx]
        
        text = passage['text']
        display_text = text[:200] + "..." if len(text) > 200 else text
        
        results.append({
            'rank': i + 1,
            'score': score,
            'page': passage['page'],
            'word_count': passage['word_count'],
            'text': display_text,
            'full_text': text
        })
    
    print(f"✅ Top {len(results)} results ready!\n")
    
    return results


def display_results(results):
    """Display search results."""
    print(f"{'='*60}")
    print("SEARCH RESULTS")
    print(f"{'='*60}\n")
    
    if not results:
        print("No results found.")
        return
    
    for result in results:
        print(f"Rank #{result['rank']}")
        print(f"Score: {result['score']:.4f}")
        print(f"Page: {result['page']}")
        print(f"Length: {result['word_count']} words")
        print(f"Text: {result['text']}")
        print(f"{'-'*60}\n")


# ============================================================================
# MAIN - Orchestrate PDF extraction or search
# ============================================================================

def main_extract(pdf_path=None):
    """
    Main function to extract text from PDF and create searchable passages.
    Structure adapted from your web scraping main()!
    """
    print(f"\n{'='*60}")
    print("PDF Text Extraction for Project 9")
    print(f"{'='*60}\n")
    
    if pdf_path is None:
        pdf_path = "data/Morgan_2030.pdf"
    
    # Check if file exists
    if not Path(pdf_path).exists():
        print(f"❌ PDF file not found: {pdf_path}")
        return
    
    # Step 1: Extract text from PDF
    pages_data = extract_text_from_pdf(pdf_path)
    
    if not pages_data:
        print("❌ Failed to extract text from PDF")
        return
    
    # Step 2: Split into passages
    passages = split_into_passages(pages_data, method='paragraph')
    
    if not passages:
        print("❌ No passages created")
        return
    
    # Step 3: Save to JSON
    output_file = "data/passages.json"
    
    if save_to_json(passages, output_file):
        print(f"\n{'='*60}")
        print(f"✅ SUCCESS! Extracted {len(passages)} passages")
        print(f"   Saved to: {output_file}")
        print(f"   Ready for Mojo search engine!")
        print(f"{'='*60}\n")
    else:
        print(f"❌ Failed to save passages")


if __name__ == "__main__":
    # Check command-line arguments
    if len(sys.argv) > 1 and sys.argv[1] == "search":
        # Run TF-IDF search
        if len(sys.argv) >= 4:
            query = sys.argv[2]
            top_n = int(sys.argv[3])
        else:
            # Default test search
            query = "research excellence"
            top_n = 5
        
        results = search_tfidf("data/passages.json", query, top_n)
        display_results(results)
    else:
        # Run PDF extraction (original functionality)
        print("Using default PDF: data/Morgan_2030.pdf")
        main_extract()