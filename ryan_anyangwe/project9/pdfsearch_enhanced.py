#!/usr/bin/env python3
import sys
import math
from collections import defaultdict
from PyPDF2 import PdfReader

class TFIDFSearchEngine:
    """Enhanced search with proper TF-IDF scoring"""
    
    def __init__(self):
        self.passages = []
        self.doc_freq = defaultdict(int)  # How many passages contain each term
        self.total_docs = 0
        
    def extract_text_from_pdf(self, pdf_path):
        """Extract text from PDF"""
        with open(pdf_path, 'rb') as f:
            reader = PdfReader(f)
            pages = []
            for page in reader.pages:
                pages.append(page.extract_text())
        return pages
    
    def tokenize(self, text):
        """Tokenize and filter stopwords"""
        stopwords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 
                    'to', 'for', 'of', 'as', 'by', 'is', 'was', 'are', 'be',
                    'this', 'that', 'with', 'from', 'have', 'has', 'had'}
        
        tokens = []
        current = ""
        for c in text.lower():
            if c.isalnum():
                current += c
            elif current:
                if current not in stopwords and len(current) > 2:
                    tokens.append(current)
                current = ""
        if current and current not in stopwords and len(current) > 2:
            tokens.append(current)
        return tokens
    
    def create_passages(self, pages, passage_size=300, overlap=75):
        """Create overlapping passages from pages"""
        passages = []
        for page_num, page_text in enumerate(pages, 1):
            start = 0
            while start < len(page_text):
                end = min(start + passage_size, len(page_text))
                passage = page_text[start:end]
                if len(passage.strip()) > 20:
                    passages.append({
                        'text': passage,
                        'page': page_num,
                        'tokens': self.tokenize(passage)
                    })
                start += (passage_size - overlap)
                if end >= len(page_text):
                    break
        return passages
    
    def build_index(self, passages):
        """Build inverted index and document frequency"""
        self.passages = passages
        self.total_docs = len(passages)
        
        # Calculate document frequency for each term
        for passage in passages:
            unique_terms = set(passage['tokens'])
            for term in unique_terms:
                self.doc_freq[term] += 1
    
    def compute_tf(self, term, passage):
        """Compute term frequency with sublinear scaling"""
        count = passage['tokens'].count(term)
        if count == 0:
            return 0.0
        return 1.0 + math.log(count)
    
    def compute_idf(self, term):
        """Compute inverse document frequency"""
        if term not in self.doc_freq:
            return 0.0
        return math.log(self.total_docs / self.doc_freq[term])
    
    def compute_tfidf_score(self, passage, query_terms):
        """Compute TF-IDF score with length normalization"""
        score = 0.0
        norm = 0.0
        
        for term in query_terms:
            tf = self.compute_tf(term, passage)
            idf = self.compute_idf(term)
            tfidf = tf * idf
            score += tfidf
            norm += tfidf * tfidf
        
        # Length normalization
        if norm > 0:
            score = score / math.sqrt(norm)
        
        return score
    
    def compute_phrase_bonus(self, passage, query):
        """Bonus for exact phrase matches"""
        text_lower = passage['text'].lower()
        query_lower = query.lower()
        count = text_lower.count(query_lower)
        if count > 0:
            return math.log(count + 1) * 1.5
        return 0.0
    
    def search(self, query, top_n=10):
        """Search and rank passages"""
        query_terms = self.tokenize(query)
        
        if not query_terms:
            return []
        
        results = []
        for passage in self.passages:
            # TF-IDF score
            score = self.compute_tfidf_score(passage, query_terms)
            
            # Add phrase matching bonus
            phrase_bonus = self.compute_phrase_bonus(passage, query)
            score += phrase_bonus
            
            if score > 0:
                results.append({
                    'passage': passage,
                    'score': score
                })
        
        # Sort by score descending
        results.sort(key=lambda x: x['score'], reverse=True)
        return results[:top_n]
    
    def format_result(self, text, max_len=250):
        """Format result text"""
        clean = ' '.join(text.split())
        if len(clean) > max_len:
            return clean[:max_len] + "..."
        return clean

def main():
    if len(sys.argv) < 4:
        print("Usage: python3 pdfsearch_enhanced.py <pdf_file> <query> <top_n>")
        print("\nFeatures:")
        print("  - TF-IDF scoring with length normalization")
        print("  - Stopword filtering")
        print("  - Phrase matching bonus")
        print("  - Overlapping passages")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3])
    
    # Initialize search engine
    engine = TFIDFSearchEngine()
    
    print(f"Loading PDF: {pdf_path}")
    pages = engine.extract_text_from_pdf(pdf_path)
    print(f"✓ Extracted {len(pages)} pages")
    
    print("Creating passages...")
    passages = engine.create_passages(pages)
    print(f"✓ Created {len(passages)} passages")
    
    print("Building index...")
    engine.build_index(passages)
    print(f"✓ Indexed {len(engine.doc_freq)} unique terms")
    
    print("Searching...")
    results = engine.search(query, top_n)
    
    print(f"\nResults for: \"{query}\"\n")
    print(f"Algorithm: TF-IDF with length normalization")
    print(f"Features: Stopword filtering, phrase matching\n")
    
    if not results:
        print("No results found.")
        return
    
    for i, result in enumerate(results, 1):
        passage = result['passage']
        score = result['score']
        print(f"[{i}] Score: {score:.2f} (page {passage['page']})")
        print(f"    \"{engine.format_result(passage['text'])}\"")
        print()
    
    # Show statistics
    print(f"\nStatistics:")
    print(f"  Total passages searched: {len(passages)}")
    print(f"  Results returned: {len(results)}")
    print(f"  Unique terms in index: {len(engine.doc_freq)}")

if __name__ == "__main__":
    main()
