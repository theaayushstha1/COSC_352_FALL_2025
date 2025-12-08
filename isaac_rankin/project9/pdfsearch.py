#!/usr/bin/env python3

import sys
import re
import math
from collections import Counter, defaultdict
from pathlib import Path
import time
import numpy as np
import PyPDF2


class PDFSearchEngine:
    def __init__(self, pdf_path):
        self.pdf_path = pdf_path
        self.passages = []
        self.vocabulary = []
        self.idf = {}
        self.passage_tfidf_matrix = None
        
    def extract_text(self):
        print(f"Extracting text from {self.pdf_path}...")
        
        with open(self.pdf_path, 'rb') as file:
            reader = PyPDF2.PdfReader(file)
            for page_num in range(len(reader.pages)):
                page = reader.pages[page_num]
                text = page.extract_text()
                
                paragraphs = text.split('.\n')
                
                for para in paragraphs:
                    clean_text = para.strip()
                    clean_text = ' '.join(clean_text.split())

                    clean_text = clean_text.replace("\n", "")

                    if len(para) > 50:
                        self.passages.append({
                            'page': page_num + 1,
                            'text': clean_text
                        })
        
        print(f"Extracted {len(self.passages)} passages from {len(reader.pages)} pages")
    
    # Tokenization and Vocabulary methods remain largely unchanged,
    # as they are driven by Python's regex/string processing.
    def tokenize(self, text):
        tokens = re.findall(r'\b[a-z]{3,}\b', text.lower())
        stopwords = {
            'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can',
            'her', 'was', 'one', 'our', 'out', 'this', 'that', 'with',
            'have', 'from', 'they', 'been', 'has', 'had', 'will', 'more',
            'when', 'who', 'which', 'their', 'said', 'each', 'she', 'than',
            'what', 'some', 'its', 'may', 'into', 'time', 'these', 'two',
            'about', 'also', 'only', 'such', 'over', 'through', 'before',
            'after', 'where', 'both', 'many', 'most', 'other', 'being'
        }
        return [token for token in tokens if token not in stopwords]
    
    def build_vocabulary(self, query):
        print("Building vocabulary...")
        vocab_set = set()
        query_tokens = self.tokenize(query)
        vocab_set.update(query_tokens)
        
        for passage in self.passages:
            tokens = self.tokenize(passage['text'])
            vocab_set.update(tokens)
        
        self.vocabulary = sorted(list(vocab_set))

        self.vocab_index = {term: i for i, term in enumerate(self.vocabulary)}
        print(f"Vocabulary size: {len(self.vocabulary)}")
    
    def compute_tf(self, tokens):
        # Returns a vector (list) based on the vocabulary order
        tf_vector = [0.0] * len(self.vocabulary)
        token_counts = Counter(tokens)
        
        for term, count in token_counts.items():
            if term in self.vocab_index:
                index = self.vocab_index[term]

                tf_vector[index] = (1 + math.log(count)) if count > 0 else 0.0
        
        return tf_vector
    
    def compute_idf(self):
        print("Computing IDF...")
        doc_freq = defaultdict(int)
        
        for passage in self.passages:
            tokens = set(self.tokenize(passage['text']))
            for token in tokens:
                if token in self.vocab_index:
                    doc_freq[token] += 1
        
        n_docs = len(self.passages)
        idf_vector = np.zeros(len(self.vocabulary), dtype=np.float32)
        
        for term, index in self.vocab_index.items():
            df = doc_freq.get(term, 0)
            idf_vector[index] = math.log(n_docs / df) if df > 0 else 0.0
            
        # Store IDF as a NumPy array
        self.idf = idf_vector
    
    def compute_passage_tfidf(self):
        print("Computing TF-IDF matrix...")
        
        # Initialize a 2D NumPy array (Matrix)
        n_docs = len(self.passages)
        vocab_size = len(self.vocabulary)
        matrix = np.zeros((n_docs, vocab_size), dtype=np.float32)
        
        for i, passage in enumerate(self.passages):
            tokens = self.tokenize(passage['text'])
            tf_vector = self.compute_tf(tokens) # Returns list
            
            # Convert list TF vector to NumPy array for element-wise multiplication
            tf_array = np.array(tf_vector, dtype=np.float32)
            
            # TF-IDF vector: Element-wise multiplication (SIMD utilized here)
            tfidf_vector = tf_array * self.idf 
            matrix[i] = tfidf_vector
            
            if (i + 1) % 100 == 0:
                print(f"  Processed {i + 1}/{n_docs} passages")
                
        self.passage_tfidf_matrix = matrix
        
    def search(self, query, top_n):
        print(f"\nSearching for: '{query}'")
        
        # Compute query TF-IDF vector (as a 1D NumPy array)
        query_tokens = self.tokenize(query)
        query_tf_list = self.compute_tf(query_tokens)
        query_tf_array = np.array(query_tf_list, dtype=np.float32)
        query_tfidf = query_tf_array * self.idf
        
        print("Scoring passages...")
        start_time = time.time()
        
        # 1. Compute Dot Product (A · B) for all passages at once:
        # matrix @ vector (or dot product of matrix row and vector)
        # NumPy/SIMD handles the massive loop efficiently.
        dot_products = self.passage_tfidf_matrix.dot(query_tfidf) 

        # 2. Compute Norms (||A|| and ||B||)
        # ||A||: Pre-computed norm of query vector
        query_norm = np.linalg.norm(query_tfidf)
        
        # ||B||: Norms of all passage vectors (Euclidean norm of each row)
        passage_norms = np.linalg.norm(self.passage_tfidf_matrix, axis=1)

        # 3. Compute Cosine Similarity = (A · B) / (||A|| * ||B||)
        # Avoid division by zero by setting norm to 1 where it is zero (score will be 0)
        passage_norms[passage_norms == 0] = 1.0 
        
        # Final scores vector (SIMD utilized here)
        scores = dot_products / (passage_norms * query_norm)
        
        elapsed_time = time.time() - start_time
        print(f"Scored {len(self.passages)} passages in {elapsed_time:.3f} seconds")
        
        # 4. Filter and Sort Results
        valid_indices = scores > 0
        valid_scores = scores[valid_indices]
        valid_passages = np.array(self.passages, dtype=object)[valid_indices]

        # Get indices that would sort the scores in descending order
        sorted_indices = np.argsort(valid_scores)[::-1]
        
        results = []
        for idx in sorted_indices[:top_n]:
            passage = valid_passages[idx]
            results.append({
                'score': valid_scores[idx],
                'page': passage['page'],
                'text': passage['text']
            })
        
        return results
    
    # Display method is unchanged
    def display_results(self, results, query):
        """Display search results in formatted output"""
        print("\n" + "-"*70)
        print(f'Results for: "{query}"')
        print("-"*70 + "\n")
        
        if not results:
            print("No relevant passages found.")
            return
        
        for i, result in enumerate(results, 1):
            score = result['score']
            page = result['page']
            text = result['text']
            
            print(f"[{i}] Score: {score:.4f} (page {page})")
            
            if len(text) > 250:
                truncated = text[:250]
                last_period = truncated.rfind('.')
                if last_period > 200:
                    truncated = truncated[:last_period + 1]
                print(f'    "{truncated}..."')
            else:
                print(f'    "{text}"')
            print()


def main():
    if len(sys.argv) != 4:
        print("Usage: python pdfsearch_optimized.py document.pdf \"search query\" N")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3])
    
    # Validate inputs
    if not Path(pdf_path).exists():
        print(f"Error: PDF file '{pdf_path}' not found")
        sys.exit(1)
    
    if top_n < 1:
        print("Error: N must be at least 1")
        sys.exit(1)
    
    # Initialize search engine
    engine = PDFSearchEngine(pdf_path)
    
    # Process PDF
    engine.extract_text()
    
    if not engine.passages:
        print("Error: No text extracted from PDF")
        sys.exit(1)
    
    # Build index
    engine.build_vocabulary(query)
    engine.compute_idf()
    engine.compute_passage_tfidf() # Creates the NumPy matrix
    
    # Execute search
    results = engine.search(query, top_n)
    engine.display_results(results, query)
    


if __name__ == '__main__':
    main()