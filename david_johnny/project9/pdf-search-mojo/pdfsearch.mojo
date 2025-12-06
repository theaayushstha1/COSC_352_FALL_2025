"""
PDF Search Tool using TF-IDF Ranking
Implements efficient text search with SIMD optimization in Mojo
"""

from sys import argv
from math import log, sqrt
from collections import Dict, List
from python import Python

# PDF text extraction using Python library
fn extract_text_from_pdf(pdf_path: String) raises -> List[String]:
    """Extract text from PDF, returning list of pages"""
    let pypdf = Python.import_module("PyPDF2")
    let reader = pypdf.PdfReader(pdf_path)
    
    var pages = List[String]()
    for i in range(len(reader.pages)):
        let page = reader.pages[i]
        pages.append(page.extract_text())
    
    return pages

# Passage segmentation
struct Passage:
    var text: String
    var page_num: Int
    var start_pos: Int
    
    fn __init__(inout self, text: String, page: Int, start: Int):
        self.text = text
        self.page_num = page
        self.start_pos = start

fn create_passages(pages: List[String], window_size: Int = 500) -> List[Passage]:
    """
    Split document into overlapping passages
    window_size: characters per passage
    """
    var passages = List[Passage]()
    
    for page_idx in range(len(pages)):
        let page_text = pages[page_idx]
        let page_len = len(page_text)
        
        # Sliding window with 50% overlap
        var pos = 0
        while pos < page_len:
            let end = min(pos + window_size, page_len)
            let passage_text = page_text[pos:end]
            passages.append(Passage(passage_text, page_idx + 1, pos))
            pos += window_size // 2  # 50% overlap
    
    return passages

# Tokenization with SIMD optimization
@always_inline
fn is_alphanumeric_simd[simd_width: Int](char: SIMD[DType.uint8, simd_width]) -> SIMD[DType.bool, simd_width]:
    """SIMD check for alphanumeric characters"""
    let is_upper = (char >= ord('A')) & (char <= ord('Z'))
    let is_lower = (char >= ord('a')) & (char <= ord('z'))
    let is_digit = (char >= ord('0')) & (char <= ord('9'))
    return is_upper | is_lower | is_digit

fn tokenize_simd(text: String) -> List[String]:
    """
    Fast tokenization using SIMD operations
    Converts to lowercase and splits on non-alphanumeric
    """
    alias simd_width = 16
    var tokens = List[String]()
    var current_token = String()
    
    let text_bytes = text.as_bytes()
    let text_len = len(text_bytes)
    
    # Process in SIMD chunks
    var i = 0
    while i + simd_width <= text_len:
        let chunk = text_bytes.load[width=simd_width](i)
        
        # Convert to lowercase (SIMD)
        let is_upper = (chunk >= ord('A')) & (chunk <= ord('Z'))
        let lowercase_chunk = chunk + is_upper.cast[DType.uint8]() * 32
        
        # Check if alphanumeric
        let is_alphanum = is_alphanumeric_simd[simd_width](lowercase_chunk)
        
        # Process each character
        for j in range(simd_width):
            if is_alphanum[j]:
                current_token += chr(int(lowercase_chunk[j]))
            else:
                if len(current_token) > 0:
                    tokens.append(current_token)
                    current_token = String()
        
        i += simd_width
    
    # Handle remaining characters
    while i < text_len:
        let c = text_bytes[i]
        if is_alphanumeric_simd[1](c)[0]:
            let lower_c = c if c < ord('A') or c > ord('Z') else c + 32
            current_token += chr(int(lower_c))
        else:
            if len(current_token) > 0:
                tokens.append(current_token)
                current_token = String()
        i += 1
    
    if len(current_token) > 0:
        tokens.append(current_token)
    
    return tokens

# Stop words removal
fn get_stop_words() -> Dict[String, Bool]:
    """Common English stop words"""
    let stop_list = ["the", "a", "an", "and", "or", "but", "in", "on", 
                     "at", "to", "for", "of", "with", "by", "from", "is",
                     "are", "was", "were", "be", "been", "being", "have",
                     "has", "had", "do", "does", "did", "will", "would",
                     "could", "should", "may", "might", "must", "can",
                     "this", "that", "these", "those", "it", "its"]
    
    var stop_words = Dict[String, Bool]()
    for word in stop_list:
        stop_words[word] = True
    return stop_words

# TF-IDF Calculation
struct TermFrequency:
    var counts: Dict[String, Int]
    var total_terms: Int
    
    fn __init__(inout self):
        self.counts = Dict[String, Int]()
        self.total_terms = 0
    
    fn add_term(inout self, term: String):
        if term in self.counts:
            self.counts[term] += 1
        else:
            self.counts[term] = 1
        self.total_terms += 1
    
    fn get_tf(self, term: String) -> Float64:
        """Term frequency with log normalization"""
        if term not in self.counts:
            return 0.0
        let raw_count = float(self.counts[term])
        return 1.0 + log(raw_count)  # Diminishing returns

struct InverseDocumentFrequency:
    var doc_counts: Dict[String, Int]
    var total_docs: Int
    
    fn __init__(inout self, passages: List[Passage], stop_words: Dict[String, Bool]):
        self.doc_counts = Dict[String, Int]()
        self.total_docs = len(passages)
        
        # Count documents containing each term
        for passage in passages:
            let tokens = tokenize_simd(passage.text)
            var seen = Dict[String, Bool]()
            
            for token in tokens:
                if len(token) > 2 and token not in stop_words:
                    if token not in seen:
                        seen[token] = True
                        if token in self.doc_counts:
                            self.doc_counts[token] += 1
                        else:
                            self.doc_counts[token] = 1
    
    fn get_idf(self, term: String) -> Float64:
        """Inverse document frequency"""
        if term not in self.doc_counts:
            return 0.0
        let doc_freq = float(self.doc_counts[term])
        return log(float(self.total_docs) / doc_freq)

struct SearchResult:
    var passage: Passage
    var score: Float64
    
    fn __init__(inout self, passage: Passage, score: Float64):
        self.passage = passage
        self.score = score

fn calculate_tfidf_score(
    passage: Passage,
    query_terms: List[String],
    idf: InverseDocumentFrequency,
    stop_words: Dict[String, Bool]
) -> Float64:
    """Calculate TF-IDF score for a passage given query terms"""
    
    # Build term frequency for passage
    let tokens = tokenize_simd(passage.text)
    var tf = TermFrequency()
    
    for token in tokens:
        if len(token) > 2 and token not in stop_words:
            tf.add_term(token)
    
    # Calculate TF-IDF score (dot product of query and document vectors)
    var score: Float64 = 0.0
    var doc_norm: Float64 = 0.0  # For cosine normalization
    
    for term in query_terms:
        let term_tf = tf.get_tf(term)
        let term_idf = idf.get_idf(term)
        let tfidf = term_tf * term_idf
        
        score += tfidf * term_idf  # Query weight = IDF
        doc_norm += tfidf * tfidf
    
    # Cosine normalization (prevents long documents from dominating)
    if doc_norm > 0.0:
        score = score / sqrt(doc_norm)
    
    return score

fn search_passages(
    passages: List[Passage],
    query: String,
    n_results: Int,
    idf: InverseDocumentFrequency,
    stop_words: Dict[String, Bool]
) -> List[SearchResult]:
    """Search passages and return top N results"""
    
    # Tokenize query
    let query_terms = tokenize_simd(query)
    var filtered_terms = List[String]()
    for term in query_terms:
        if len(term) > 2 and term not in stop_words:
            filtered_terms.append(term)
    
    # Score all passages
    var results = List[SearchResult]()
    for passage in passages:
        let score = calculate_tfidf_score(passage, filtered_terms, idf, stop_words)
        if score > 0.0:
            results.append(SearchResult(passage, score))
    
    # Sort by score (descending) - implement insertion sort for simplicity
    for i in range(len(results)):
        for j in range(i + 1, len(results)):
            if results[j].score > results[i].score:
                let temp = results[i]
                results[i] = results[j]
                results[j] = temp
    
    # Return top N
    var top_results = List[SearchResult]()
    for i in range(min(n_results, len(results))):
        top_results.append(results[i])
    
    return top_results

fn format_passage(text: String, max_length: Int = 200) -> String:
    """Format passage for display, truncating if needed"""
    if len(text) <= max_length:
        return text
    return text[:max_length] + "..."

fn main():
    """Main entry point"""
    let args = argv()
    
    if len(args) != 4:
        print("Usage: ./pdfsearch <pdf_file> <query> <n_results>")
        return
    
    let pdf_path = args[1]
    let query = args[2]
    let n_results = atol(args[3])
    
    try:
        print("Loading PDF...")
        let pages = extract_text_from_pdf(pdf_path)
        
        print("Creating passages...")
        let passages = create_passages(pages)
        
        print("Building search index...")
        let stop_words = get_stop_words()
        let idf = InverseDocumentFrequency(passages, stop_words)
        
        print("\nSearching for: \"" + query + "\"\n")
        let results = search_passages(passages, query, n_results, idf, stop_words)
        
        # Display results
        for i in range(len(results)):
            let result = results[i]
            print("[" + String(i + 1) + "] Score: " + String(result.score)[:4] + 
                  " (page " + String(result.passage.page_num) + ")")
            print("    \"" + format_passage(result.passage.text) + "\"")
            print()
        
    except e:
        print("Error: " + str(e))