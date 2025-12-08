from python import Python
from collections import List
from math import sqrt, log
from sys import argv

# Passage structure to hold text segments with metadata
struct Passage:
    var text: String
    var page: Int
    var score: Float64
    
    fn __init__(inout self, text: String, page: Int):
        self.text = text
        self.page = page
        self.score = 0.0

# Common English stop words to filter out
fn is_stopword(word: String) -> Bool:
    """Check if a word is a common stopword"""
    let stopwords = List[String](
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for",
        "of", "with", "by", "from", "as", "is", "was", "are", "were", "been",
        "be", "have", "has", "had", "do", "does", "did", "will", "would",
        "could", "should", "may", "might", "must", "can", "this", "that",
        "these", "those", "it", "its", "they", "them", "their", "then",
        "than", "so", "if", "when", "where", "why", "how", "all", "each",
        "some", "such", "no", "not", "only", "own", "same", "just", "more"
    )
    
    for i in range(len(stopwords)):
        if word == stopwords[i]:
            return True
    return False

# Tokenize text into lowercase words
fn tokenize(text: String) -> List[String]:
    """Convert text to lowercase tokens (words)"""
    var tokens = List[String]()
    var current_word = String("")
    
    for i in range(len(text)):
        let c = text[i]
        let ord_c = ord(c)
        
        # Check if character is alphanumeric
        if (ord_c >= ord('a') and ord_c <= ord('z')) or \
           (ord_c >= ord('A') and ord_c <= ord('Z')) or \
           (ord_c >= ord('0') and ord_c <= ord('9')):
            # Convert to lowercase
            if ord_c >= ord('A') and ord_c <= ord('Z'):
                current_word += chr(ord_c + 32)
            else:
                current_word += c
        else:
            if len(current_word) > 0:
                tokens.append(current_word)
                current_word = String("")
    
    if len(current_word) > 0:
        tokens.append(current_word)
    
    return tokens

# Calculate term frequency with sublinear scaling
fn calculate_tf(term: String, tokens: List[String]) -> Float64:
    """Calculate TF with sublinear scaling: 1 + log(count)"""
    var count: Float64 = 0.0
    
    for i in range(len(tokens)):
        if tokens[i] == term:
            count += 1.0
    
    # Sublinear TF scaling: 1 + log(tf) if tf > 0, else 0
    if count > 0:
        return 1.0 + log(count)
    return 0.0

# Calculate inverse document frequency
fn calculate_idf(term: String, all_passages: List[Passage]) -> Float64:
    """Calculate IDF: log(N / df)"""
    var doc_count: Float64 = 0.0
    let total_docs = Float64(len(all_passages))
    
    for i in range(len(all_passages)):
        let tokens = tokenize(all_passages[i].text)
        var found = False
        for j in range(len(tokens)):
            if tokens[j] == term:
                found = True
                break
        if found:
            doc_count += 1.0
    
    # IDF formula: log(N / df)
    if doc_count > 0:
        return log(total_docs / doc_count)
    return 0.0

# Count unique non-stopword terms in a token list
fn count_unique_terms(tokens: List[String]) -> Int:
    """Count unique non-stopword terms"""
    var unique_terms = List[String]()
    
    for i in range(len(tokens)):
        let token = tokens[i]
        if is_stopword(token):
            continue
        
        # Check if already in unique list
        var is_unique = True
        for j in range(len(unique_terms)):
            if unique_terms[j] == token:
                is_unique = False
                break
        
        if is_unique:
            unique_terms.append(token)
    
    return len(unique_terms)

# Calculate relevance score using TF-IDF
fn calculate_relevance(query_terms: List[String], passage: Passage, 
                       idf_scores: List[Float64]) -> Float64:
    """Calculate TF-IDF relevance score between query and passage"""
    let passage_tokens = tokenize(passage.text)
    var score: Float64 = 0.0
    
    # Calculate TF-IDF score for each query term
    for i in range(len(query_terms)):
        let term = query_terms[i]
        if is_stopword(term):
            continue
        
        let tf = calculate_tf(term, passage_tokens)
        let idf = idf_scores[i]
        let tfidf = tf * idf
        
        score += tfidf
    
    # Normalize by passage length (sqrt of unique term count)
    let unique_count = count_unique_terms(passage_tokens)
    if unique_count > 0:
        score = score / sqrt(Float64(unique_count))
    
    return score

# Extract text from PDF using Python's pypdf library
fn extract_pdf_text(filepath: String) raises -> List[Passage]:
    """Extract text from PDF and create passages"""
    var passages = List[Passage]()
    
    try:
        let pypdf = Python.import_module("pypdf")
        let reader = pypdf.PdfReader(filepath)
        let num_pages = len(reader.pages).__int__()
        
        print("Extracting text from", num_pages, "pages...")
        
        # Extract text from each page
        for page_num in range(num_pages):
            let page = reader.pages[page_num]
            let text_obj = page.extract_text()
            let text = String(text_obj)
            
            # Only add non-empty pages
            if len(text.strip()) > 0:
                passages.append(Passage(text, page_num + 1))
        
    except:
        print("Error: Could not read PDF file.")
        print("Make sure pypdf is installed: pip install pypdf")
        raise Error("PDF extraction failed")
    
    return passages

# Sort passages by score (bubble sort for simplicity)
fn sort_passages_by_score(inout passages: List[Passage]):
    """Sort passages in descending order by score"""
    let n = len(passages)
    
    for i in range(n):
        for j in range(n - i - 1):
            if passages[j].score < passages[j + 1].score:
                # Swap passages
                let temp_text = passages[j].text
                let temp_page = passages[j].page
                let temp_score = passages[j].score
                
                passages[j].text = passages[j + 1].text
                passages[j].page = passages[j + 1].page
                passages[j].score = passages[j + 1].score
                
                passages[j + 1].text = temp_text
                passages[j + 1].page = temp_page
                passages[j + 1].score = temp_score

# Main entry point
fn main() raises:
    # Parse command line arguments
    let args = argv()
    
    if len(args) < 4:
        print("Usage: mojo mojo_search.mojo <pdf_file> <query> <num_results>")
        print('Example: mojo mojo_search.mojo document.pdf "gradient descent" 3')
        return
    
    let pdf_path = args[1]
    let query = args[2]
    let num_results = atol(args[3])
    
    # Extract passages from PDF
    var passages = extract_pdf_text(pdf_path)
    
    if len(passages) == 0:
        print("Error: No text extracted from PDF")
        return
    
    print("Indexing", len(passages), "passages...")
    
    # Tokenize and filter query
    let query_tokens = tokenize(query)
    var filtered_query = List[String]()
    
    for i in range(len(query_tokens)):
        if not is_stopword(query_tokens[i]):
            filtered_query.append(query_tokens[i])
    
    if len(filtered_query) == 0:
        print("Error: Query contains only stopwords")
        return
    
    # Pre-calculate IDF for all query terms
    print("Calculating IDF scores...")
    var idf_scores = List[Float64]()
    
    for i in range(len(filtered_query)):
        let term = filtered_query[i]
        let idf = calculate_idf(term, passages)
        idf_scores.append(idf)
    
    # Score all passages
    print("Ranking passages by relevance...")
    for i in range(len(passages)):
        passages[i].score = calculate_relevance(filtered_query, passages[i], idf_scores)
    
    # Sort passages by score
    sort_passages_by_score(passages)
    
    # Display results
    print()
    print('Results for: "' + query + '"')
    print("=" * 70)
    
    let results_to_show = min(num_results, len(passages))
    var found_results = False
    
    for i in range(results_to_show):
        let p = passages[i]
        if p.score > 0:
            found_results = True
            
            # Format score to 2 decimal places
            let score_str = String(p.score)
            var formatted_score = score_str
            let dot_pos = score_str.find(".")
            if dot_pos >= 0 and len(score_str) > dot_pos + 3:
                formatted_score = score_str[:dot_pos + 3]
            
            print()
            print("[" + String(i + 1) + "] Score: " + formatted_score + 
                  " (page " + String(p.page) + ")")
            
            # Show snippet (first 200 chars)
            var snippet = p.text.strip()
            
            # Replace newlines with spaces
            snippet = snippet.replace("\n", " ")
            snippet = snippet.replace("\r", " ")
            
            # Truncate if too long
            if len(snippet) > 200:
                snippet = snippet[:197] + "..."
            
            print('    "' + snippet + '"')
    
    if not found_results:
        print()
        print("No relevant passages found for query terms.")