"""
PDF Search Tool - Mojo Implementation
High-performance search with SIMD optimizations

This is Mojo syntax (not Python). Save as pdfsearch.mojo
Compile and run with: mojo run pdfsearch.mojo <pdf> <query> <n>
"""

from memory import memset_zero, memcpy
from algorithm import vectorize, parallelize
from math import log, sqrt
from python import Python
from collections import Dict, List


# ============================================================================
# MOJO SIMD-OPTIMIZED TOKENIZATION
# ============================================================================

fn is_alphanumeric(char: UInt8) -> Bool:
    """Check if character is alphanumeric."""
    let is_lower = (char >= ord('a')) and (char <= ord('z'))
    let is_upper = (char >= ord('A')) and (char <= ord('Z'))
    let is_digit = (char >= ord('0')) and (char <= ord('9'))
    return is_lower or is_upper or is_digit


fn to_lowercase(char: UInt8) -> UInt8:
    """Convert character to lowercase."""
    if (char >= ord('A')) and (char <= ord('Z')):
        return char + 32  # Convert A-Z to a-z
    return char


fn tokenize_simd(text: String) -> List[String]:
    """
    SIMD-optimized tokenization.
    Processes 16 characters at once using vector operations.
    """
    var tokens = List[String]()
    var current_token = String()
    let text_len = len(text)
    
    # Process characters in chunks of 16 using SIMD
    alias simd_width = 16
    let n_chunks = text_len // simd_width
    
    for chunk_idx in range(n_chunks):
        let offset = chunk_idx * simd_width
        
        # Load 16 characters into SIMD register
        var chars = SIMD[DType.uint8, simd_width]()
        for i in range(simd_width):
            chars[i] = ord(text[offset + i])
        
        # Vectorized lowercase conversion
        let is_upper_mask = (chars >= ord('A')) & (chars <= ord('Z'))
        chars = chars + is_upper_mask.select(UInt8(32), UInt8(0))
        
        # Process each character in the chunk
        for i in range(simd_width):
            let char = chars[i]
            
            if is_alphanumeric(char):
                current_token += chr(int(char))
            else:
                if len(current_token) > 0:
                    tokens.append(current_token)
                    current_token = String()
    
    # Handle remaining characters (not divisible by 16)
    let remaining_start = n_chunks * simd_width
    for i in range(remaining_start, text_len):
        let char = to_lowercase(ord(text[i]))
        
        if is_alphanumeric(char):
            current_token += chr(int(char))
        else:
            if len(current_token) > 0:
                tokens.append(current_token)
                current_token = String()
    
    # Don't forget last token
    if len(current_token) > 0:
        tokens.append(current_token)
    
    return tokens


# ============================================================================
# TERM FREQUENCY CALCULATION
# ============================================================================

struct TermFrequency:
    """Efficient term frequency counter using hash map."""
    var counts: Dict[String, Int]
    
    fn __init__(inout self):
        self.counts = Dict[String, Int]()
    
    fn add_token(inout self, token: String):
        """Add a token to the frequency counter."""
        if token in self.counts:
            self.counts[token] += 1
        else:
            self.counts[token] = 1
    
    fn get_frequency(self, token: String) -> Int:
        """Get frequency of a token."""
        if token in self.counts:
            return self.counts[token]
        return 0
    
    fn compute_from_tokens(inout self, tokens: List[String]):
        """Compute term frequencies from token list."""
        for i in range(len(tokens)):
            self.add_token(tokens[i])


# ============================================================================
# TF-IDF SCORING WITH SIMD
# ============================================================================

fn compute_tfidf_score_simd(
    query_terms: List[String],
    passage_tf: TermFrequency,
    doc_freq: Dict[String, Int],
    total_passages: Int,
    passage_length: Int
) -> Float64:
    """
    SIMD-optimized TF-IDF scoring.
    Processes multiple terms in parallel using vector operations.
    """
    var score: Float64 = 0.0
    let n_terms = len(query_terms)
    
    # Process terms in batches of 4 using SIMD
    alias simd_width = 4
    let n_batches = n_terms // simd_width
    
    # Vectorized scoring for batches of 4 terms
    for batch_idx in range(n_batches):
        var tf_vec = SIMD[DType.float64, simd_width]()
        var idf_vec = SIMD[DType.float64, simd_width]()
        
        # Load TF and IDF values for 4 terms
        for i in range(simd_width):
            let term_idx = batch_idx * simd_width + i
            let term = query_terms[term_idx]
            
            # Term Frequency (with sublinear scaling)
            let tf_count = passage_tf.get_frequency(term)
            tf_vec[i] = Float64(tf_count)
            
            # Inverse Document Frequency
            let df = doc_freq.get(term, 1)
            idf_vec[i] = log(Float64(total_passages) / Float64(df))
        
        # SIMD operations: log(1 + tf) * idf
        let tf_log = (tf_vec + 1.0).log()  # Vectorized log
        let tfidf = tf_log * idf_vec        # Vectorized multiply
        
        # Sum all 4 elements
        score += tfidf.reduce_add()
    
    # Handle remaining terms (not divisible by 4)
    let remaining_start = n_batches * simd_width
    for i in range(remaining_start, n_terms):
        let term = query_terms[i]
        let tf_count = passage_tf.get_frequency(term)
        
        if tf_count > 0:
            let tf_score = 1.0 + log(Float64(tf_count))
            let df = doc_freq.get(term, 1)
            let idf_score = log(Float64(total_passages) / Float64(df))
            score += tf_score * idf_score
    
    # Length normalization
    if passage_length > 0:
        score = score / sqrt(Float64(passage_length))
    
    return score


# ============================================================================
# PASSAGE STRUCTURE
# ============================================================================

struct Passage:
    """Represents a searchable passage from PDF."""
    var text: String
    var page_num: Int
    var tokens: List[String]
    var tf: TermFrequency
    
    fn __init__(inout self, text: String, page_num: Int):
        self.text = text
        self.page_num = page_num
        self.tokens = tokenize_simd(text)
        self.tf = TermFrequency()
        self.tf.compute_from_tokens(self.tokens)
    
    fn get_length(self) -> Int:
        return len(self.tokens)


# ============================================================================
# STOPWORD FILTERING
# ============================================================================

fn is_stopword(word: String) -> Bool:
    """Check if word is a common stopword."""
    # Common English stopwords
    let stopwords = [
        "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
        "has", "he", "in", "is", "it", "its", "of", "on", "that", "the",
        "to", "was", "will", "with", "this", "but", "they", "have", "had"
    ]
    
    for i in range(len(stopwords)):
        if word == stopwords[i]:
            return True
    return False


fn filter_stopwords(tokens: List[String]) -> List[String]:
    """Remove stopwords from token list."""
    var filtered = List[String]()
    
    for i in range(len(tokens)):
        if not is_stopword(tokens[i]):
            filtered.append(tokens[i])
    
    return filtered


# ============================================================================
# DOCUMENT FREQUENCY CALCULATION
# ============================================================================

fn compute_document_frequencies(passages: List[Passage]) -> Dict[String, Int]:
    """
    Compute document frequency for each term.
    DF = number of passages containing the term.
    """
    var doc_freq = Dict[String, Int]()
    
    for passage_idx in range(len(passages)):
        let passage = passages[passage_idx]
        
        # Use set-like behavior: count each term once per passage
        var seen_terms = Dict[String, Bool]()
        
        for token_idx in range(len(passage.tokens)):
            let token = passage.tokens[token_idx]
            
            if token not in seen_terms:
                seen_terms[token] = True
                
                if token in doc_freq:
                    doc_freq[token] += 1
                else:
                    doc_freq[token] = 1
    
    return doc_freq


# ============================================================================
# PARALLEL SEARCH
# ============================================================================

struct SearchResult:
    """Search result with passage and score."""
    var passage_idx: Int
    var score: Float64
    
    fn __init__(inout self, passage_idx: Int, score: Float64):
        self.passage_idx = passage_idx
        self.score = score


fn parallel_score_passages(
    passages: List[Passage],
    query_terms: List[String],
    doc_freq: Dict[String, Int],
    total_passages: Int
) -> List[SearchResult]:
    """
    Score all passages in parallel.
    Uses Mojo's parallelize for multi-threaded execution.
    """
    var results = List[SearchResult]()
    let n_passages = len(passages)
    
    # Allocate results array
    var scores = List[Float64]()
    for _ in range(n_passages):
        scores.append(0.0)
    
    # Parallel scoring function
    @parameter
    fn score_batch(start: Int, end: Int):
        for i in range(start, end):
            let passage = passages[i]
            let score = compute_tfidf_score_simd(
                query_terms,
                passage.tf,
                doc_freq,
                total_passages,
                passage.get_length()
            )
            scores[i] = score
    
    # Execute in parallel (Mojo will distribute across CPU cores)
    parallelize[score_batch](n_passages, n_passages)
    
    # Collect results with non-zero scores
    for i in range(n_passages):
        if scores[i] > 0.0:
            results.append(SearchResult(i, scores[i]))
    
    return results


# ============================================================================
# SORTING
# ============================================================================

fn sort_results_by_score(inout results: List[SearchResult]):
    """
    Sort results by score in descending order.
    Simple insertion sort (good for small result sets).
    For large datasets, use quicksort or mergesort.
    """
    let n = len(results)
    
    for i in range(1, n):
        let key_idx = results[i].passage_idx
        let key_score = results[i].score
        var j = i - 1
        
        # Move elements greater than key down
        while j >= 0 and results[j].score < key_score:
            results[j + 1] = results[j]
            j -= 1
        
        results[j + 1] = SearchResult(key_idx, key_score)


# ============================================================================
# PDF EXTRACTION (Using Python)
# ============================================================================

fn extract_passages_from_pdf(pdf_path: String) -> List[Passage]:
    """
    Extract passages from PDF using Python's PyPDF2.
    Mojo can call Python libraries when needed.
    """
    var passages = List[Passage]()
    
    try:
        # Import Python's PyPDF2
        let pypdf = Python.import_module("PyPDF2")
        let builtins = Python.import_module("builtins")
        
        # Open and read PDF
        let pdf_file = builtins.open(pdf_path, "rb")
        let reader = pypdf.PdfReader(pdf_file)
        
        let n_pages = len(reader.pages)
        
        for page_num in range(n_pages):
            let page = reader.pages[page_num]
            let text = page.extract_text()
            
            # Simple paragraph splitting
            let paragraphs = str(text).split("\n\n")
            
            for para in paragraphs:
                let para_str = str(para).strip()
                if len(para_str) >= 50:  # Minimum passage length
                    passages.append(Passage(para_str, page_num + 1))
        
        pdf_file.close()
        
    except:
        print("Error reading PDF file")
    
    return passages


# ============================================================================
# MAIN SEARCH ENGINE
# ============================================================================

struct PDFSearchEngine:
    """Main search engine with all components."""
    var passages: List[Passage]
    var doc_freq: Dict[String, Int]
    var total_passages: Int
    
    fn __init__(inout self, pdf_path: String):
        print("Loading PDF:", pdf_path)
        self.passages = extract_passages_from_pdf(pdf_path)
        self.total_passages = len(self.passages)
        print("Extracted", self.total_passages, "passages")
        
        print("Computing document statistics...")
        self.doc_freq = compute_document_frequencies(self.passages)
        print("Ready to search!")
    
    fn search(self, query: String, top_n: Int) -> List[SearchResult]:
        """Search and return top N results."""
        # Tokenize and filter query
        var query_tokens = tokenize_simd(query)
        query_tokens = filter_stopwords(query_tokens)
        
        # Score all passages in parallel
        var results = parallel_score_passages(
            self.passages,
            query_tokens,
            self.doc_freq,
            self.total_passages
        )
        
        # Sort by score
        sort_results_by_score(results)
        
        # Return top N
        var top_results = List[SearchResult]()
        let limit = min(top_n, len(results))
        for i in range(limit):
            top_results.append(results[i])
        
        return top_results
    
    fn print_results(self, query: String, results: List[SearchResult]):
        """Print search results in formatted output."""
        print("\nResults for:", query)
        print()
        
        if len(results) == 0:
            print("No results found.")
            return
        
        for rank in range(len(results)):
            let result = results[rank]
            let passage = self.passages[result.passage_idx]
            
            # Format text (truncate if needed)
            var text = passage.text
            if len(text) > 200:
                text = text[:197] + "..."
            
            print("[" + str(rank + 1) + "] Score:", result.score, "(page", passage.page_num, ")")
            print("    \"" + text + "\"")
            print()


# ============================================================================
# MAIN FUNCTION
# ============================================================================

fn main() raises:
    """Main entry point."""
    let args = sys.argv()
    
    if len(args) < 4:
        print("Usage: mojo run pdfsearch.mojo <pdf_file> <query> <num_results>")
        print()
        print("Example:")
        print("  mojo run pdfsearch.mojo document.pdf \"machine learning\" 5")
        return
    
    let pdf_path = args[1]
    let query = args[2]
    let top_n = atol(args[3])
    
    # Create search engine
    var engine = PDFSearchEngine(pdf_path)
    
    # Run search
    let results = engine.search(query, top_n)
    
    # Print results
    engine.print_results(query, results)
