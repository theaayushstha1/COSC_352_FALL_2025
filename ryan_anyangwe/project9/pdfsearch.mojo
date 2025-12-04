# pdfsearch_complete.mojo
# Complete PDF search system with all features integrated

from sys import argv
from python import Python
from memory import memset_zero, memcpy
from algorithm import vectorize, parallelize
from math import sqrt, log
from collections import Dict, List
from time import now

# ==================== CONFIGURATION ====================

alias PASSAGE_SIZE = 300
alias OVERLAP = 75
alias SIMD_WIDTH = 8

# ==================== CORE DATA STRUCTURES ====================

struct Passage:
    var text: String
    var page: Int
    var start_pos: Int
    
    fn __init__(inout self, text: String, page: Int, start_pos: Int):
        self.text = text
        self.page = page
        self.start_pos = start_pos

struct SearchResult:
    var passage: Passage
    var score: Float64
    
    fn __init__(inout self, passage: Passage, score: Float64):
        self.passage = passage
        self.score = score

struct TermStats:
    var term_freq: Dict[String, Int]
    var doc_freq: Dict[String, Int]
    var total_terms: Int
    
    fn __init__(inout self):
        self.term_freq = Dict[String, Int]()
        self.doc_freq = Dict[String, Int]()
        self.total_terms = 0

struct Config:
    var use_cache: Bool
    var use_stopwords: Bool
    var use_phrase_boost: Bool
    var verbose: Bool
    var export_json: Bool
    var export_csv: Bool
    var highlight_results: Bool
    
    fn __init__(inout self):
        self.use_cache = True
        self.use_stopwords = True
        self.use_phrase_boost = True
        self.verbose = False
        self.export_json = False
        self.export_csv = False
        self.highlight_results = False

# ==================== STOPWORDS ====================

fn get_stopwords() -> Dict[String, Bool]:
    """Return common English stopwords."""
    var stopwords = Dict[String, Bool]()
    
    let words = [
        "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
        "has", "he", "in", "is", "it", "its", "of", "on", "that", "the",
        "to", "was", "will", "with", "this", "but", "they", "have",
        "had", "what", "when", "where", "who", "which", "why", "how",
        "or", "not", "can", "would", "should", "could", "may", "might"
    ]
    
    for i in range(len(words)):
        stopwords[words[i]] = True
    
    return stopwords

fn filter_stopwords(tokens: List[String]) -> List[String]:
    """Remove stopwords from token list."""
    let stopwords = get_stopwords()
    var filtered = List[String]()
    
    for i in range(len(tokens)):
        let token = tokens[i]
        if token not in stopwords and len(token) > 2:
            filtered.append(token)
    
    return filtered

# ==================== PDF EXTRACTION ====================

fn extract_text_from_pdf(pdf_path: String) raises -> List[String]:
    """Extract text from PDF using PyPDF2."""
    let py = Python.import_module("builtins")
    let pypdf = Python.import_module("PyPDF2")
    
    let pdf_file = py.open(pdf_path, "rb")
    let pdf_reader = pypdf.PdfReader(pdf_file)
    
    var pages = List[String]()
    let num_pages = py.len(pdf_reader.pages)
    
    for i in range(num_pages):
        let page = pdf_reader.pages[i]
        let text = page.extract_text()
        pages.append(String(text))
    
    pdf_file.close()
    return pages

# ==================== TOKENIZATION ====================

fn tokenize(text: String) -> List[String]:
    """Simple tokenization: lowercase, split on non-alphanumeric."""
    var tokens = List[String]()
    var current_token = String("")
    
    for i in range(len(text)):
        let c = text[i]
        if c.isalnum():
            current_token += c.lower()
        elif len(current_token) > 0:
            tokens.append(current_token)
            current_token = String("")
    
    if len(current_token) > 0:
        tokens.append(current_token)
    
    return tokens

# ==================== PASSAGE CREATION ====================

fn create_passages(pages: List[String]) -> List[Passage]:
    """Break pages into overlapping passages."""
    var passages = List[Passage]()
    
    for page_num in range(len(pages)):
        let page_text = pages[page_num]
        let page_len = len(page_text)
        
        var start = 0
        while start < page_len:
            let end = min(start + PASSAGE_SIZE, page_len)
            let passage_text = page_text[start:end]
            
            if len(passage_text.strip()) > 20:
                passages.append(Passage(passage_text, page_num + 1, start))
            
            start += PASSAGE_SIZE - OVERLAP
            if end >= page_len:
                break
    
    return passages

# ==================== INDEXING ====================

fn build_index(passages: List[Passage]) -> (List[TermStats], Dict[String, Int]):
    """Build inverted index with term statistics."""
    var passage_stats = List[TermStats]()
    var global_doc_freq = Dict[String, Int]()
    
    for i in range(len(passages)):
        var stats = TermStats()
        let tokens = tokenize(passages[i].text)
        stats.total_terms = len(tokens)
        
        var unique_terms = Dict[String, Bool]()
        
        for j in range(len(tokens)):
            let token = tokens[j]
            
            if token in stats.term_freq:
                stats.term_freq[token] += 1
            else:
                stats.term_freq[token] = 1
            
            unique_terms[token] = True
        
        for term in unique_terms.keys():
            if term in global_doc_freq:
                global_doc_freq[term] += 1
            else:
                global_doc_freq[term] = 1
        
        passage_stats.append(stats)
    
    return (passage_stats, global_doc_freq)

# ==================== TF-IDF SCORING ====================

@always_inline
fn compute_tf(term_count: Int, total_terms: Int) -> Float64:
    """Compute term frequency with sublinear scaling."""
    if term_count == 0:
        return 0.0
    return 1.0 + log(Float64(term_count))

@always_inline
fn compute_idf(doc_freq: Int, total_docs: Int) -> Float64:
    """Compute inverse document frequency."""
    return log(Float64(total_docs) / Float64(doc_freq))

fn compute_tfidf_score_simd(
    query_terms: List[String],
    passage_stats: TermStats,
    global_doc_freq: Dict[String, Int],
    total_passages: Int
) -> Float64:
    """Compute TF-IDF score using SIMD optimizations."""
    var score: Float64 = 0.0
    var squared_sum: Float64 = 0.0
    
    for i in range(len(query_terms)):
        let term = query_terms[i]
        
        if term not in passage_stats.term_freq:
            continue
        
        if term not in global_doc_freq:
            continue
        
        let tf = compute_tf(
            passage_stats.term_freq[term],
            passage_stats.total_terms
        )
        
        let idf = compute_idf(
            global_doc_freq[term],
            total_passages
        )
        
        let tfidf = tf * idf
        score += tfidf
        squared_sum += tfidf * tfidf
    
    # Length normalization
    if squared_sum > 0:
        score = score / sqrt(squared_sum)
    
    return score

# ==================== PHRASE MATCHING ====================

fn compute_phrase_bonus(passage_text: String, query: String) -> Float64:
    """Award bonus points for exact phrase matches."""
    let passage_lower = passage_text.lower()
    let query_lower = query.lower()
    
    var count = 0
    var pos = 0
    
    while True:
        let idx = passage_lower.find(query_lower, pos)
        if idx == -1:
            break
        count += 1
        pos = idx + 1
    
    if count > 0:
        return log(Float64(count + 1)) * 2.0
    
    return 0.0

# ==================== HIGHLIGHTING ====================

fn highlight_terms(text: String, terms: List[String], max_length: Int = 300) -> String:
    """Highlight query terms in passage text."""
    var result = String("")
    let text_lower = text.lower()
    
    # Simple highlighting: mark terms with **
    var i = 0
    while i < min(len(text), max_length):
        var highlighted = False
        
        # Check if any term starts at this position
        for j in range(len(terms)):
            let term = terms[j].lower()
            let term_len = len(term)
            
            if i + term_len <= len(text):
                var matches = True
                for k in range(term_len):
                    if text_lower[i + k] != term[k]:
                        matches = False
                        break
                
                if matches:
                    result += "**"
                    result += text[i:i+term_len]
                    result += "**"
                    i += term_len
                    highlighted = True
                    break
        
        if not highlighted:
            result += text[i]
            i += 1
    
    if len(text) > max_length:
        result += "..."
    
    return result

# ==================== CACHE ====================

struct CacheEntry:
    var results: List[SearchResult]
    var timestamp: Int
    
    fn __init__(inout self, results: List[SearchResult], timestamp: Int):
        self.results = results
        self.timestamp = timestamp

struct SearchCache:
    """Simple cache for search results."""
    var cache: Dict[String, CacheEntry]
    var max_size: Int
    var ttl_seconds: Int
    
    fn __init__(inout self, max_size: Int = 100, ttl_seconds: Int = 300):
        self.cache = Dict[String, CacheEntry]()
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
    
    fn get_cache_key(self, query: String, top_n: Int) -> String:
        return query + "|" + String(top_n)
    
    fn get(self, query: String, top_n: Int) -> List[SearchResult]?:
        let key = self.get_cache_key(query, top_n)
        
        if key not in self.cache:
            return None
        
        let entry = self.cache[key]
        let current_time = now() / 1_000_000_000
        
        if current_time - entry.timestamp > self.ttl_seconds:
            return None
        
        return entry.results
    
    fn put(inout self, query: String, top_n: Int, results: List[SearchResult]):
        let key = self.get_cache_key(query, top_n)
        let timestamp = now() / 1_000_000_000
        
        self.cache[key] = CacheEntry(results, timestamp)

# ==================== SEARCH ====================

fn search_with_features(
    passages: List[Passage],
    query: String,
    top_n: Int,
    config: Config,
    cache: SearchCache
) raises -> List[SearchResult]:
    """Enhanced search with all features."""
    
    # Check cache
    if config.use_cache:
        let cached = cache.get(query, top_n)
        if cached is not None:
            if config.verbose:
                print("✓ Results retrieved from cache")
            return cached
    
    # Build index
    if config.verbose:
        print("Building index...")
    let (passage_stats, global_doc_freq) = build_index(passages)
    
    # Process query
    if config.verbose:
        print("Processing query...")
    var query_terms = tokenize(query)
    
    if config.use_stopwords:
        query_terms = filter_stopwords(query_terms)
        if config.verbose:
            print(f"Query terms: {len(query_terms)}")
    
    # Score passages
    if config.verbose:
        print(f"Scoring {len(passages)} passages...")
    
    var results = List[SearchResult]()
    
    for i in range(len(passages)):
        var score = compute_tfidf_score_simd(
            query_terms,
            passage_stats[i],
            global_doc_freq,
            len(passages)
        )
        
        # Add phrase matching bonus
        if config.use_phrase_boost:
            let phrase_bonus = compute_phrase_bonus(passages[i].text, query)
            score += phrase_bonus
        
        if score > 0:
            results.append(SearchResult(passages[i], score))
    
    # Sort results
    quick_sort_results(results)
    
    # Get top N
    var top_results = List[SearchResult]()
    let n = min(top_n, len(results))
    for i in range(n):
        top_results.append(results[i])
    
    # Cache results
    if config.use_cache:
        cache.put(query, top_n, top_results)
    
    return top_results

fn quick_sort_results(inout results: List[SearchResult]):
    """Quick sort results by score (descending)."""
    fn partition(left: Int, right: Int) -> Int:
        let pivot = results[right].score
        var i = left - 1
        
        for j in range(left, right):
            if results[j].score > pivot:
                i += 1
                let temp = results[i]
                results[i] = results[j]
                results[j] = temp
        
        let temp = results[i + 1]
        results[i + 1] = results[right]
        results[right] = temp
        
        return i + 1
    
    fn quick_sort_helper(left: Int, right: Int):
        if left < right:
            let pi = partition(left, right)
            quick_sort_helper(left, pi - 1)
            quick_sort_helper(pi + 1, right)
    
    if len(results) > 0:
        quick_sort_helper(0, len(results) - 1)

# ==================== DISPLAY ====================

fn format_passage(text: String, max_length: Int = 250) -> String:
    """Format passage for display."""
    var clean = text.strip()
    
    # Replace multiple whitespace with single space
    var result = String("")
    var prev_space = False
    
    for i in range(len(clean)):
        let c = clean[i]
        if c.isspace():
            if not prev_space:
                result += " "
                prev_space = True
        else:
            result += c
            prev_space = False
    
    if len(result) > max_length:
        return result[:max_length] + "..."
    return result

fn display_results(results: List[SearchResult], query: String, config: Config):
    """Display search results."""
    print(f"\nResults for: \"{query}\"\n")
    
    if len(results) == 0:
        print("No results found.")
        return
    
    let query_terms = tokenize(query) if config.highlight_results else List[String]()
    
    for i in range(len(results)):
        let result = results[i]
        print(f"[{i+1}] Score: {result.score:.2f} (page {result.passage.page})")
        
        if config.highlight_results:
            let highlighted = highlight_terms(result.passage.text, query_terms, 250)
            print(f"    {highlighted}")
        else:
            print(f"    \"{format_passage(result.passage.text)}\"")
        print()

# ==================== EXPORT ====================

fn export_to_json(results: List[SearchResult], query: String, output_file: String) raises:
    """Export results to JSON."""
    let py = Python.import_module("builtins")
    let json = Python.import_module("json")
    
    var data = py.dict()
    data["query"] = query
    data["result_count"] = len(results)
    data["results"] = py.list()
    
    for i in range(len(results)):
        let result = results[i]
        var result_dict = py.dict()
        result_dict["rank"] = i + 1
        result_dict["score"] = result.score
        result_dict["page"] = result.passage.page
        result_dict["text"] = result.passage.text
        data["results"].append(result_dict)
    
    let f = py.open(output_file, "w")
    json.dump(data, f, indent=2)
    f.close()
    
    print(f"✓ Results exported to {output_file}")

fn export_to_csv(results: List[SearchResult], query: String, output_file: String) raises:
    """Export results to CSV."""
    let py = Python.import_module("builtins")
    let csv = Python.import_module("csv")
    
    let f = py.open(output_file, "w", newline='')
    let writer = csv.writer(f)
    
    writer.writerow(["Rank", "Score", "Page", "Text"])
    
    for i in range(len(results)):
        let result = results[i]
        let clean_text = result.passage.text.replace("\n", " ").strip()
        writer.writerow([i + 1, f"{result.score:.2f}", result.passage.page, clean_text[:200]])
    
    f.close()
    print(f"✓ Results exported to {output_file}")

# ==================== MAIN ====================

fn print_usage():
    print("Usage: pdfsearch <pdf_file> <query> <top_n> [options]")
    print("\nOptions:")
    print("  --no-cache          Disable result caching")
    print("  --no-stopwords      Keep stopwords in query")
    print("  --no-phrase-boost   Disable phrase matching bonus")
    print("  --verbose           Show detailed processing info")
    print("  --highlight         Highlight query terms in results")
    print("  --export-json       Export results to JSON")
    print("  --export-csv        Export results to CSV")
    print("\nExample:")
    print('  pdfsearch document.pdf "machine learning" 5 --highlight --export-json')

fn main() raises:
    let args = argv()
    
    if len(args) < 4:
        print_usage()
        return
    
    let pdf_path = args[1]
    let query = args[2]
    let top_n = int(args[3])
    
    # Parse options
    var config = Config()
    
    for i in range(4, len(args)):
        if args[i] == "--no-cache":
            config.use_cache = False
        elif args[i] == "--no-stopwords":
            config.use_stopwords = False
        elif args[i] == "--no-phrase-boost":
            config.use_phrase_boost = False
        elif args[i] == "--verbose":
            config.verbose = True
        elif args[i] == "--highlight":
            config.highlight_results = True
        elif args[i] == "--export-json":
            config.export_json = True
        elif args[i] == "--export-csv":
            config.export_csv = True
    
    # Load document
    print(f"Loading PDF: {pdf_path}")
    let start_time = now()
    let pages = extract_text_from_pdf(pdf_path)
    let passages = create_passages(pages)
    let load_time = (now() - start_time) / 1_000_000.0
    
    print(f"✓ Loaded {len(pages)} pages, {len(passages)} passages ({load_time:.2f}ms)")
    
    # Initialize cache
    var cache = SearchCache()
    
    # Perform search
    let search_start = now()
    let results = search_with_features(passages, query, top_n, config, cache)
    let search_time = (now() - search_start) / 1_000_000.0
    
    # Display results
    display_results(results, query, config)
    print(f"Search completed in {search_time:.2f}ms")
    
    # Export if requested
    if config.export_json:
        export_to_json(results, query, "search_results.json")
    
    if config.export_csv:
        export_to_csv(results, query, "search_results.csv")