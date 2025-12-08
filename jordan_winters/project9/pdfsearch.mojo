from sys import argv
from algorithm import vectorize, parallelize
from math import sqrt, log
from memory import memset_zero, memcpy
from python import Python

# Configuration
alias SIMD_WIDTH = 8
alias MAX_TERM_LENGTH = 64
alias MAX_PASSAGES = 10000
alias PASSAGE_SIZE = 500  # characters per passage
alias OVERLAP = 100  # overlap between passages

struct Term:
    var text: String
    var doc_freq: Int
    var idf: Float64
    
    fn __init__(inout self, text: String):
        self.text = text
        self.doc_freq = 0
        self.idf = 0.0

struct Passage:
    var text: String
    var page: Int
    var start_pos: Int
    var score: Float64
    var term_freqs: DynamicVector[Int]
    
    fn __init__(inout self, text: String, page: Int, start_pos: Int):
        self.text = text
        self.page = page
        self.start_pos = start_pos
        self.score = 0.0
        self.term_freqs = DynamicVector[Int]()

fn normalize_text(text: String) -> String:
    """Convert to lowercase and remove punctuation"""
    var result = String("")
    for i in range(len(text)):
        let c = text[i]
        if (c >= 'A' and c <= 'Z'):
            result += chr(ord(c) + 32)
        elif (c >= 'a' and c <= 'z') or (c >= '0' and c <= '9') or c == ' ':
            result += c
        else:
            result += ' '
    return result

fn tokenize(text: String) -> DynamicVector[String]:
    """Split text into tokens"""
    var tokens = DynamicVector[String]()
    var current = String("")
    
    for i in range(len(text)):
        let c = text[i]
        if c == ' ' or c == '\n' or c == '\t':
            if len(current) > 0:
                tokens.push_back(current)
                current = String("")
        else:
            current += c
    
    if len(current) > 0:
        tokens.push_back(current)
    
    return tokens

fn is_stopword(word: String) -> Bool:
    """Check if word is a common stopword"""
    let stopwords = DynamicVector[String]()
    # Add common stopwords
    let stops = String("the a an and or but in on at to for of with by from as is was are be been being have has had do does did will would could should may might must can this that these those")
    var current = String("")
    
    for i in range(len(stops)):
        if stops[i] == ' ':
            if len(current) > 0:
                if word == current:
                    return True
                current = String("")
        else:
            current += stops[i]
    
    return False

fn count_term_occurrences_simd(text: String, term: String) -> Int:
    """Count occurrences of term in text using SIMD where possible"""
    if len(term) == 0 or len(text) < len(term):
        return 0
    
    var count = 0
    let text_len = len(text)
    let term_len = len(term)
    let search_len = text_len - term_len + 1
    
    # For single character terms, use SIMD
    if term_len == 1:
        let target = ord(term[0])
        var i = 0
        
        # SIMD vectorized counting
        while i + SIMD_WIDTH <= text_len:
            var matches = 0
            for j in range(SIMD_WIDTH):
                if ord(text[i + j]) == target:
                    matches += 1
            count += matches
            i += SIMD_WIDTH
        
        # Handle remainder
        while i < text_len:
            if ord(text[i]) == target:
                count += 1
            i += 1
        
        return count
    
    # For longer terms, use standard search with word boundaries
    var i = 0
    while i < search_len:
        var match = True
        for j in range(term_len):
            if text[i + j] != term[j]:
                match = False
                break
        
        if match:
            # Check word boundaries
            let before_ok = (i == 0) or (text[i-1] == ' ' or text[i-1] == '\n')
            let after_ok = (i + term_len >= text_len) or (text[i + term_len] == ' ' or text[i + term_len] == '\n')
            
            if before_ok and after_ok:
                count += 1
                i += term_len
            else:
                i += 1
        else:
            i += 1
    
    return count

fn compute_tf(count: Int, passage_length: Int) -> Float64:
    """Compute term frequency with sublinear scaling"""
    if count == 0:
        return 0.0
    # Use log scaling to provide diminishing returns
    return 1.0 + log(Float64(count))

fn compute_idf(doc_freq: Int, total_passages: Int) -> Float64:
    """Compute inverse document frequency"""
    return log(Float64(total_passages) / Float64(doc_freq + 1))

fn compute_passage_score(passage: Passage, query_terms: DynamicVector[Term]) -> Float64:
    """Compute TF-IDF score for passage"""
    var score = 0.0
    let passage_length = len(passage.text)
    
    for i in range(len(query_terms)):
        let term = query_terms[i]
        let count = count_term_occurrences_simd(passage.text, term.text)
        
        if count > 0:
            let tf = compute_tf(count, passage_length)
            let idf = term.idf
            score += tf * idf
    
    # Normalize by passage length to avoid bias toward longer passages
    if passage_length > 0:
        score = score / sqrt(Float64(passage_length))
    
    return score

fn extract_passages(text: String, page_breaks: DynamicVector[Int]) -> DynamicVector[Passage]:
    """Extract overlapping passages from text"""
    var passages = DynamicVector[Passage]()
    let text_len = len(text)
    var pos = 0
    var current_page = 1
    var page_break_idx = 0
    
    while pos < text_len:
        # Update current page
        while page_break_idx < len(page_breaks) and page_breaks[page_break_idx] <= pos:
            current_page += 1
            page_break_idx += 1
        
        # Extract passage
        let end_pos = min(pos + PASSAGE_SIZE, text_len)
        var passage_text = String("")
        for i in range(pos, end_pos):
            passage_text += text[i]
        
        let passage = Passage(passage_text, current_page, pos)
        passages.push_back(passage)
        
        # Move forward with overlap
        pos += PASSAGE_SIZE - OVERLAP
        
        if pos >= text_len:
            break
    
    return passages

fn main() raises:
    let args = argv()
    
    if len(args) != 4:
        print("Usage: pdfsearch <pdf_file> <query> <num_results>")
        return
    
    let pdf_file = args[1]
    let query = args[2]
    let num_results = atol(args[3])
    
    # Extract text from PDF using Python
    let py = Python.import_module("builtins")
    let pypdf = Python.import_module("PyPDF2")
    
    print("Loading PDF...")
    let pdf_reader = pypdf.PdfReader(pdf_file)
    let num_pages = len(pdf_reader.pages)
    
    var full_text = String("")
    var page_breaks = DynamicVector[Int]()
    
    for page_num in range(num_pages):
        let page = pdf_reader.pages[page_num]
        let page_text = str(page.extract_text())
        page_breaks.push_back(len(full_text))
        full_text += page_text
        full_text += "\n"
    
    print("Extracted", num_pages, "pages")
    
    # Normalize text
    let normalized_text = normalize_text(full_text)
    
    # Parse query
    let normalized_query = normalize_text(query)
    let query_tokens = tokenize(normalized_query)
    
    # Filter stopwords from query
    var filtered_query = DynamicVector[String]()
    for i in range(len(query_tokens)):
        if not is_stopword(query_tokens[i]):
            filtered_query.push_back(query_tokens[i])
    
    if len(filtered_query) == 0:
        print("Error: Query contains only stopwords")
        return
    
    print("Query terms:", len(filtered_query))
    
    # Extract passages
    print("Extracting passages...")
    var passages = extract_passages(normalized_text, page_breaks)
    let num_passages = len(passages)
    print("Found", num_passages, "passages")
    
    # Build query terms with IDF
    var query_terms = DynamicVector[Term]()
    
    for i in range(len(filtered_query)):
        let term_text = filtered_query[i]
        var term = Term(term_text)
        
        # Count document frequency
        for j in range(num_passages):
            if count_term_occurrences_simd(passages[j].text, term_text) > 0:
                term.doc_freq += 1
        
        term.idf = compute_idf(term.doc_freq, num_passages)
        query_terms.push_back(term)
    
    # Score all passages
    print("Scoring passages...")
    for i in range(num_passages):
        passages[i].score = compute_passage_score(passages[i], query_terms)
    
    # Sort passages by score (simple bubble sort for top N)
    for i in range(min(num_results, num_passages)):
        var max_idx = i
        for j in range(i + 1, num_passages):
            if passages[j].score > passages[max_idx].score:
                max_idx = j
        
        # Swap
        if max_idx != i:
            let temp_text = passages[i].text
            let temp_page = passages[i].page
            let temp_start = passages[i].start_pos
            let temp_score = passages[i].score
            
            passages[i].text = passages[max_idx].text
            passages[i].page = passages[max_idx].page
            passages[i].start_pos = passages[max_idx].start_pos
            passages[i].score = passages[max_idx].score
            
            passages[max_idx].text = temp_text
            passages[max_idx].page = temp_page
            passages[max_idx].start_pos = temp_start
            passages[max_idx].score = temp_score
    
    # Display results
    print("\nResults for: \"" + query + "\"")
    print()
    
    let results_to_show = min(num_results, num_passages)
    
    for i in range(results_to_show):
        if passages[i].score > 0.0:
            print("[" + String(i + 1) + "] Score: " + String(passages[i].score)[:4] + " (page " + String(passages[i].page) + ")")
            
            # Clean up passage text for display
            var display_text = String("")
            var line_len = 0
            for j in range(min(300, len(passages[i].text))):
                let c = passages[i].text[j]
                if c == '\n' or c == '\t':
                    display_text += " "
                    line_len += 1
                else:
                    display_text += c
                    line_len += 1
                
                # Word wrap at ~70 chars
                if line_len > 70 and c == ' ':
                    display_text += "\n    "
                    line_len = 0
            
            if len(passages[i].text) > 300:
                display_text += "..."
            
            print("    \"" + display_text + "\"")
            print()