from math import sqrt, log
from sys import argv
from python import Python
from collections import Dict, List

# Constants
alias SIMD_WIDTH = 16
alias MIN_PASSAGE_LENGTH = 50
alias MAX_DISPLAY_LENGTH = 250
alias SENTENCES_PER_PASSAGE = 4
alias WORDS_PER_PASSAGE = 200

struct SearchResult:
    """Represents a search result with relevance score and metadata."""
    var score: Float64
    var page_num: Int
    var text: String
    var position: Int
    
    fn __init__(inout self, score: Float64, page: Int, txt: String, pos: Int):
        self.score = score
        self.page_num = page
        self.text = txt
        self.position = pos

fn normalize_text(text: String) -> String:
    """Convert text to lowercase for case-insensitive matching."""
    var result = String("")
    for i in range(len(text)):
        var c = text[i]
        var ord_c = ord(c)
        if 65 <= ord_c <= 90:  # A-Z
            result += chr(ord_c + 32)
        else:
            result += c
    return result

fn is_alnum(c: String) -> Bool:
    """Check if character is alphanumeric."""
    if len(c) != 1:
        return False
    var o = ord(c)
    return (48 <= o <= 57) or (65 <= o <= 90) or (97 <= o <= 122)

fn is_space(c: String) -> Bool:
    """Check if character is whitespace."""
    return c == " " or c == "\n" or c == "\t" or c == "\r"

fn tokenize(text: String) -> List[String]:
    """Split text into normalized words."""
    var tokens = List[String]()
    var current = String("")
    var normalized = normalize_text(text)
    
    for i in range(len(normalized)):
        var c = normalized[i]
        if is_alnum(c):
            current += c
        elif len(current) > 0:
            tokens.append(current)
            current = String("")
    
    if len(current) > 0:
        tokens.append(current)
    
    return tokens

fn is_stopword(word: String) -> Bool:
    """Check if word is a common stopword."""
    var stops = List[String]()
    # Common stopwords
    var stoplist = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", 
                    "for", "of", "with", "is", "was", "are", "were", "be", "been",
                    "have", "has", "had", "will", "would", "can", "could", "this",
                    "that", "it", "as", "by", "from"]
    
    for i in range(len(stoplist)):
        if word == stoplist[i]:
            return True
    return False

fn count_term_occurrences(text: String, term: String) -> Int:
    """
    Count word occurrences using SIMD optimization for single chars.
    Uses word boundary checking to avoid partial matches.
    """
    if len(term) == 0 or len(text) == 0:
        return 0
    
    var count = 0
    var text_norm = normalize_text(text)
    var term_norm = normalize_text(term)
    
    # SIMD optimization for single character terms
    if len(term_norm) == 1:
        var target = ord(term_norm)
        var i = 0
        
        # Process in SIMD-width chunks
        while i + SIMD_WIDTH <= len(text_norm):
            @parameter
            fn process_chunk[width: Int](offset: Int):
                for j in range(width):
                    if ord(text_norm[offset + j]) == target:
                        count += 1
            
            process_chunk[SIMD_WIDTH](i)
            i += SIMD_WIDTH
        
        # Handle remainder
        while i < len(text_norm):
            if ord(text_norm[i]) == target:
                count += 1
            i += 1
        
        return count
    
    # Standard matching for multi-character terms with word boundaries
    var i = 0
    while i <= len(text_norm) - len(term_norm):
        var match = True
        
        # Check if term matches at position i
        for j in range(len(term_norm)):
            if text_norm[i + j] != term_norm[j]:
                match = False
                break
        
        if match:
            # Verify word boundaries
            var start_ok = (i == 0) or not is_alnum(text_norm[i - 1])
            var end_ok = (i + len(term_norm) >= len(text_norm)) or \
                        not is_alnum(text_norm[i + len(term_norm)])
            
            if start_ok and end_ok:
                count += 1
                i += len(term_norm)
            else:
                i += 1
        else:
            i += 1
    
    return count

fn count_words(text: String) -> Int:
    """Count words in text."""
    var count = 0
    var in_word = False
    
    for i in range(len(text)):
        var c = text[i]
        if is_space(c):
            in_word = False
        elif not in_word:
            count += 1
            in_word = True
    
    return count

fn calculate_tfidf_score(passage_text: String, passage_len: Int,
                         query_terms: List[String], 
                         doc_freqs: List[Int],
                         total_passages: Int) -> Float64:
    """
    Calculate TF-IDF relevance score.
    
    Scoring formula:
    - TF (Term Frequency): 1 + log(count) for sublinear scaling
    - IDF (Inverse Document Frequency): log(N / df) for rarity weighting  
    - Length normalization: divide by sqrt(passage_length)
    
    This handles:
    1. Diminishing returns for repeated terms
    2. Higher weight for rare terms
    3. Fair comparison between different passage lengths
    """
    var score: Float64 = 0.0
    var length = Float64(passage_len)
    
    if length == 0:
        return 0.0
    
    for i in range(len(query_terms)):
        var term = query_terms[i]
        
        if is_stopword(term):
            continue
        
        var term_count = count_term_occurrences(passage_text, term)
        
        if term_count > 0:
            # TF: Sublinear term frequency (diminishing returns)
            var tf = 1.0 + log(Float64(term_count))
            
            # IDF: Inverse document frequency (rare terms weighted higher)
            var df = Float64(doc_freqs[i])
            var idf = log(Float64(total_passages) / (df + 1.0))
            
            # Combined TF-IDF with length normalization
            var term_score = (tf * idf) / sqrt(length)
            score += term_score
    
    return score

fn main() raises:
    var args = argv()
    
    if len(args) < 4:
        print("Usage: mojo pdfsearch.mojo <pdf_file> <query> <num_results>")
        print('Example: mojo pdfsearch.mojo document.pdf "machine learning" 5')
        return
    
    var pdf_path = args[1]
    var query = args[2]
    var top_n = atol(args[3])
    
    print("=" * 70)
    print("PDF Search Tool - TF-IDF Ranking with SIMD Optimization")
    print("=" * 70)
    print("Query: \"" + query + "\"")
    print("Extracting text from PDF...")
    
    # Use Python to extract PDF text
    var py = Python.import_module("builtins")
    var pypdf = Python.import_module("pypdf")
    
    var reader = pypdf.PdfReader(pdf_path)
    var num_pages = len(reader.pages)
    
    print("Pages found:", num_pages)
    
    # Extract text and track page boundaries
    var full_text = String("")
    var page_positions = List[Int]()
    page_positions.append(0)
    
    for i in range(num_pages):
        var page = reader.pages[i]
        var page_text = String(page.extract_text())
        full_text += page_text
        
        if i < num_pages - 1:
            page_positions.append(len(full_text))
    
    print("Total characters:", len(full_text))
    print("Creating passages...")
    
    # Split into passages (paragraphs or ~200 word chunks)
    var passages = List[String]()
    var passage_pages = List[Int]()
    var passage_positions = List[Int]()
    
    var current_passage = String("")
    var current_page = 1
    var sentence_count = 0
    var word_count = 0
    var char_pos = 0
    var passage_start = 0
    
    for i in range(len(full_text)):
        var c = full_text[i]
        current_passage += c
        char_pos += 1
        
        # Count words
        if is_space(c) and i > 0 and is_alnum(full_text[i-1]):
            word_count += 1
        
        # Count sentences
        if (c == "." or c == "!" or c == "?"):
            if i + 1 < len(full_text) and is_space(full_text[i + 1]):
                sentence_count += 1
        
        # Determine current page
        for j in range(len(page_positions)):
            if char_pos >= page_positions[j]:
                current_page = j + 1
        
        # Split on paragraph breaks or size threshold
        var is_para_break = (c == "\n" and i + 1 < len(full_text) and 
                            full_text[i + 1] == "\n")
        var is_large = (sentence_count >= SENTENCES_PER_PASSAGE or 
                       word_count >= WORDS_PER_PASSAGE)
        
        if is_para_break or is_large:
            var trimmed = current_passage.strip()
            if len(trimmed) >= MIN_PASSAGE_LENGTH:
                passages.append(trimmed)
                passage_pages.append(current_page)
                passage_positions.append(passage_start)
                
                current_passage = String("")
                sentence_count = 0
                word_count = 0
                passage_start = char_pos
    
    # Add final passage
    var final = current_passage.strip()
    if len(final) >= MIN_PASSAGE_LENGTH:
        passages.append(final)
        passage_pages.append(current_page)
        passage_positions.append(passage_start)
    
    print("Passages created:", len(passages))
    print("Tokenizing query...")
    
    # Tokenize query and filter stopwords
    var query_terms = tokenize(query)
    var filtered_terms = List[String]()
    
    for i in range(len(query_terms)):
        if not is_stopword(query_terms[i]):
            filtered_terms.append(query_terms[i])
    
    print("Query terms:", len(filtered_terms))
    print("Computing document frequencies...")
    
    # Compute document frequency for each term
    var doc_freqs = List[Int]()
    
    for i in range(len(filtered_terms)):
        var term = filtered_terms[i]
        var df = 0
        
        for j in range(len(passages)):
            if count_term_occurrences(passages[j], term) > 0:
                df += 1
        
        doc_freqs.append(df)
    
    print("Ranking passages...")
    
    # Score all passages
    var results = List[SearchResult]()
    
    for i in range(len(passages)):
        var passage_text = passages[i]
        var word_count = count_words(passage_text)
        var score = calculate_tfidf_score(passage_text, word_count, 
                                          filtered_terms, doc_freqs, 
                                          len(passages))
        
        if score > 0.0:
            # Truncate for display
            var display = passage_text
            if len(display) > MAX_DISPLAY_LENGTH:
                display = display[:MAX_DISPLAY_LENGTH - 3] + "..."
            
            var result = SearchResult(score, passage_pages[i], display, 
                                     passage_positions[i])
            results.append(result)
    
    # Sort by score (bubble sort)
    for i in range(len(results)):
        for j in range(i + 1, len(results)):
            if results[j].score > results[i].score:
                var temp = results[i]
                results[i] = results[j]
                results[j] = temp
    
    # Display top N results
    print("\n" + "=" * 70)
    print("Results for: \"" + query + "\"")
    print("=" * 70 + "\n")
    
    if len(results) == 0:
        print("No results found.")
        return
    
    var limit = top_n if top_n < len(results) else len(results)
    
    for i in range(limit):
        var r = results[i]
        print("[" + String(i + 1) + "] Score: " + String(r.score)[:5] + 
              " (page " + String(r.page_num) + ")")
        print("    \"" + r.text + "\"")
        print()
    
    print("=" * 70)
    print("Displayed " + String(limit) + " of " + String(len(results)) + " results")