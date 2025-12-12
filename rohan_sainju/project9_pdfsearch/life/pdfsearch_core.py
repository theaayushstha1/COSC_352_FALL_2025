"""
Core search logic - called by Mojo
"""
import sys
import math
from pdf_extractor import extract_text_from_pdf

STOPWORDS = {
    "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
    "of", "with", "by", "from", "as", "is", "was", "are", "were", "be",
    "been", "being", "have", "has", "had", "do", "does", "did", "will",
    "would", "should", "could", "may", "might", "must", "can", "this",
    "that", "these", "those", "i", "you", "he", "she", "it", "we", "they"
}

class Passage:
    def __init__(self, text, page_num):
        self.text = text
        self.page_num = page_num
        self.score = 0.0

class SearchEngine:
    def __init__(self):
        self.passages = []
    
    def tokenize(self, text):
        tokens = []
        current_word = ""
        for c in text:
            if c.isalnum():
                current_word += c.lower()
            else:
                if current_word:
                    tokens.append(current_word)
                    current_word = ""
        if current_word:
            tokens.append(current_word)
        return tokens
    
    def is_stopword(self, word):
        return word in STOPWORDS
    
    def split_into_passages(self, pages_text):
        window_size = 300
        overlap = 100
        
        for page_num, page_text in pages_text:
            tokens = self.tokenize(page_text)
            start = 0
            while start < len(tokens):
                end = min(start + window_size, len(tokens))
                passage_text = " ".join(tokens[start:end])
                if len(passage_text.strip()) > 20:
                    self.passages.append(Passage(passage_text, page_num))
                if end >= len(tokens):
                    break
                start += (window_size - overlap)
    
    def calculate_tf(self, term, passage_tokens):
        count = passage_tokens.count(term)
        if count == 0:
            return 0.0
        return 1.0 + math.log(count)
    
    def calculate_idf(self, term):
        doc_count = 0
        for passage in self.passages:
            tokens = self.tokenize(passage.text)
            if term in tokens:
                doc_count += 1
        if doc_count == 0:
            return 0.0
        return math.log(len(self.passages) / doc_count)
    
    def calculate_passage_score(self, passage, query_terms):
        passage_tokens = self.tokenize(passage.text)
        score = 0.0
        for term in query_terms:
            if self.is_stopword(term):
                continue
            tf = self.calculate_tf(term, passage_tokens)
            if tf > 0.0:
                idf = self.calculate_idf(term)
                score += tf * idf
        passage_length = len(passage_tokens)
        if passage_length > 0:
            score = score / math.sqrt(passage_length)
        return score
    
    def search(self, query, top_n):
        query_terms = self.tokenize(query)
        for passage in self.passages:
            passage.score = self.calculate_passage_score(passage, query_terms)
        sorted_passages = sorted(self.passages, key=lambda p: p.score, reverse=True)
        return sorted_passages[:top_n]
    
    def print_results(self, query, results):
        print(f'\nResults for: "{query}"\n')
        for rank, passage in enumerate(results, 1):
            score_str = f"{passage.score:.2f}"
            print(f"[{rank}] Score: {score_str} (page {passage.page_num})")
            display_text = passage.text
            if len(display_text) > 250:
                display_text = display_text[:247] + "..."
            print(f'    "{display_text}"')
            print()

def run_search(pdf_path, query, num_results):
    print("Extracting text from PDF...")
    pages_text = extract_text_from_pdf(pdf_path)
    print(f"✓ Extracted {len(pages_text)} pages\n")
    
    engine = SearchEngine()
    print("Creating passages...")
    engine.split_into_passages(pages_text)
    print(f"✓ Created {len(engine.passages)} passages\n")
    
    print("Searching...")
    results = engine.search(query, num_results)
    print("✓ Search complete\n")
    print("=" * 60)
    
    engine.print_results(query, results)
