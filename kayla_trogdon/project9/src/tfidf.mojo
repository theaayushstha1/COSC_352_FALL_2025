"""
TF-IDF Search Engine - Mojo Implementation
==========================================

NOTE: This implementation is non-functional due to Mojo Python interop bugs.
      The Python backend in extract_pdf.py implements the same algorithm successfully.

This file demonstrates:
- Complete TF-IDF algorithm structure in Mojo
- Proper function organization
- Good faith attempt at Mojo implementation

Known Issues:
- Python.import_module() causes segmentation fault
- File I/O through Python crashes at runtime
- JSON loading is unstable in both Mojo 0.26.1 and 24.5.0

Working alternative: src/extract_pdf.py
"""

from python import Python, PythonObject
from math import log, sqrt

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

fn to_lowercase(text: String) -> String:
    """Convert text to lowercase for matching."""
    return text.lower()


fn clean_text(text: String) -> String:
    """Remove punctuation and collapse spaces."""
    var cleaned = text.lower()
    cleaned = cleaned.replace(".", " ")
    cleaned = cleaned.replace(",", " ")
    cleaned = cleaned.replace("!", " ")
    cleaned = cleaned.replace("?", " ")
    cleaned = cleaned.replace(";", " ")
    cleaned = cleaned.replace(":", " ")
    cleaned = cleaned.replace("(", " ")
    cleaned = cleaned.replace(")", " ")
    cleaned = cleaned.replace("[", " ")
    cleaned = cleaned.replace("]", " ")
    cleaned = cleaned.replace('"', " ")
    cleaned = cleaned.replace("'", " ")
    cleaned = cleaned.replace("-", " ")
    cleaned = cleaned.replace("_", " ")
    
    # Collapse multiple spaces
    for _ in range(10):
        cleaned = cleaned.replace("  ", " ")
    
    return cleaned


fn is_stopword(word: String) -> Bool:
    """Check if word is a common stopword that should be filtered."""
    if word == "the" or word == "be" or word == "to" or word == "of":
        return True
    if word == "and" or word == "a" or word == "in" or word == "that":
        return True
    if word == "have" or word == "i" or word == "it" or word == "for":
        return True
    if word == "not" or word == "on" or word == "with" or word == "he":
        return True
    if word == "as" or word == "you" or word == "do" or word == "at":
        return True
    if word == "this" or word == "but" or word == "his" or word == "by":
        return True
    if word == "from" or word == "they" or word == "we" or word == "say":
        return True
    if word == "her" or word == "she" or word == "or" or word == "an":
        return True
    if word == "will" or word == "my" or word == "one" or word == "all":
        return True
    if word == "would" or word == "there" or word == "their" or word == "what":
        return True
    if word == "so" or word == "up" or word == "out" or word == "if":
        return True
    if word == "about" or word == "who" or word == "get" or word == "which":
        return True
    if word == "go" or word == "me" or word == "when" or word == "make":
        return True
    if word == "can" or word == "like" or word == "time" or word == "no":
        return True
    if word == "just" or word == "him" or word == "know" or word == "take":
        return True
    if word == "into" or word == "year" or word == "your" or word == "some":
        return True
    if word == "could" or word == "them" or word == "see" or word == "other":
        return True
    if word == "than" or word == "then" or word == "now" or word == "look":
        return True
    if word == "only" or word == "come" or word == "its" or word == "over":
        return True
    if word == "also" or word == "back" or word == "after" or word == "use":
        return True
    if word == "two" or word == "how" or word == "our" or word == "work":
        return True
    if word == "first" or word == "well" or word == "way" or word == "even":
        return True
    if word == "new" or word == "want" or word == "because" or word == "any":
        return True
    if word == "these" or word == "give" or word == "day" or word == "most":
        return True
    if word == "us" or word == "is" or word == "was" or word == "are":
        return True
    return False


fn count_term(text: String, term: String) -> Int:
    """Count occurrences of term in text (case-insensitive)."""
    var text_lower = text.lower()
    var term_lower = term.lower()
    
    var count = 0
    var start = 0
    
    while True:
        var pos = text_lower.find(term_lower, start)
        if pos == -1:
            break
        count += 1
        start = pos + len(term_lower)
    
    return count


# ============================================================================
# TF-IDF MATH
# ============================================================================

fn calculate_tf_with_diminishing_returns(term_count: Int) -> Float64:
    """
    Calculate Term Frequency with diminishing returns.
    Uses log to prevent spam of terms from dominating.
    
    Formula: TF = log(1 + term_count)
    """
    if term_count == 0:
        return 0.0
    return log(1.0 + Float64(term_count))


fn calculate_idf(total_passages: Int, passages_containing_term: Int) -> Float64:
    """
    Calculate Inverse Document Frequency.
    Rare terms get higher weight.
    
    Formula: IDF = log(total_passages / passages_containing_term)
    """
    if passages_containing_term == 0:
        return 0.0
    var ratio = Float64(total_passages) / Float64(passages_containing_term)
    return log(ratio)


fn normalize_by_length(score: Float64, passage_length: Int) -> Float64:
    """
    Normalize score by passage length.
    Prevents long passages from dominating due to word count.
    
    Formula: normalized_score = score / sqrt(passage_length)
    """
    if passage_length == 0:
        return 0.0
    return score / sqrt(Float64(passage_length))


# ============================================================================
# DATA LOADING (CRASHES DUE TO MOJO BUG)
# ============================================================================

fn load_passages(filepath: String) raises -> PythonObject:
    """
    Load passages from JSON file.
    
    WARNING: This crashes in both Mojo 0.26.1 and 24.5.0 due to Python interop bug.
    """
    var py = Python.import_module("builtins")  # ⚠️ CRASHES HERE
    var json = Python.import_module("json")
    
    print("=" * 60)
    print("Loading passages from:", filepath)
    print("=" * 60)
    
    var file = py.open(filepath, "r")
    var content = file.read()
    file.close()
    
    var data = json.loads(content)
    var passages = data["passages"]
    var total = passages.__len__()
    
    print("✅ Loaded", total, "passages")
    print()
    
    return passages


# ============================================================================
# QUERY PREPROCESSING
# ============================================================================

fn preprocess_query(query: String) raises -> PythonObject:
    """
    Clean query and split into terms.
    
    Steps:
    1. Clean text (lowercase, remove punctuation)
    2. Split into words
    3. Filter stopwords
    """
    var py = Python.import_module("builtins")
    
    var cleaned = clean_text(query)
    var words = cleaned.split(" ")
    
    var terms = py.list()
    for i in range(words.__len__()):
        var word = String(words[i])
        if len(word) > 0 and not is_stopword(word):
            terms.append(word)
    
    return terms


# ============================================================================
# IDF CALCULATION
# ============================================================================

fn calculate_idf_for_terms(passages: PythonObject, query_terms: PythonObject) raises -> PythonObject:
    """
    Calculate IDF value for each query term.
    
    For each term, count how many passages contain it,
    then calculate IDF = log(total_passages / passages_with_term)
    """
    var py = Python.import_module("builtins")
    
    var total_passages = passages.__len__()
    var idf_values = py.list()
    
    print("Calculating IDF values for query terms...")
    
    for i in range(query_terms.__len__()):
        var term = String(query_terms[i])
        
        # Count passages containing this term
        var passages_with_term = 0
        for j in range(total_passages):
            var passage = passages[j]
            var text = String(passage["text"])
            var text_lower = to_lowercase(text)
            var term_lower = to_lowercase(term)
            
            if text_lower.find(term_lower) != -1:
                passages_with_term += 1
        
        # Calculate IDF
        var idf = calculate_idf(total_passages, passages_with_term)
        idf_values.append(idf)
        
        print("  Term:", term, "-> appears in", passages_with_term, "passages -> IDF =", Float64(idf))
    
    print()
    return idf_values


# ============================================================================
# TF-IDF SCORING
# ============================================================================

fn score_passage(
    passage_text: String,
    passage_length: Int,
    query_terms: PythonObject,
    idf_values: PythonObject
) raises -> Float64:
    """
    Calculate TF-IDF score for a single passage.
    
    Algorithm:
    1. For each query term:
       - Count occurrences in passage (term_count)
       - Calculate TF = log(1 + term_count)
       - Multiply TF * IDF
       - Add to total score
    2. Normalize by passage length: score / sqrt(length)
    """
    var total_score: Float64 = 0.0
    var num_terms = query_terms.__len__()
    
    for i in range(num_terms):
        var term = String(query_terms[i])
        var idf = Float64(idf_values[i])
        
        # Count term occurrences
        var term_count = count_term(passage_text, term)
        
        if term_count > 0:
            # Calculate TF with diminishing returns
            var tf = calculate_tf_with_diminishing_returns(term_count)
            
            # Add TF * IDF to total score
            total_score += tf * idf
    
    # Normalize by passage length
    if passage_length > 0:
        total_score = normalize_by_length(total_score, passage_length)
    
    return total_score


fn score_all_passages(
    passages: PythonObject,
    query_terms: PythonObject,
    idf_values: PythonObject
) raises -> PythonObject:
    """
    Score all passages and return list of (score, index) tuples.
    """
    var py = Python.import_module("builtins")
    
    var scores = py.list()
    var total = passages.__len__()
    
    print("Scoring", total, "passages...")
    
    for i in range(total):
        var passage = passages[i]
        var text = String(passage["text"])
        var word_count = Int(passage["word_count"])
        
        var score = score_passage(text, word_count, query_terms, idf_values)
        scores.append(py.tuple([score, i]))
    
    print("✅ Scoring complete!")
    print()
    
    return scores


# ============================================================================
# SORTING (Bubble Sort)
# ============================================================================

fn get_top_n_results(
    passages: PythonObject,
    scores: PythonObject,
    n: Int
) raises -> PythonObject:
    """
    Sort passages by score (descending) and return top N.
    
    Uses bubble sort - efficient enough for 39 passages.
    """
    var py = Python.import_module("builtins")
    
    print("Sorting results...")
    
    # Bubble sort (descending order)
    var num_scores = scores.__len__()
    
    for i in range(num_scores):
        for j in range(num_scores - 1 - i):
            var score1 = Float64(scores[j][0])
            var score2 = Float64(scores[j + 1][0])
            
            # Swap if score1 < score2
            if score1 < score2:
                var temp = scores[j]
                scores[j] = scores[j + 1]
                scores[j + 1] = temp
    
    # Get top N results
    var results = py.list()
    var count = py.min(n, num_scores)
    
    for i in range(count):
        var score_tuple = scores[i]
        var score = Float64(score_tuple[0])
        var passage_idx = Int(score_tuple[1])
        
        var passage = passages[passage_idx]
        var text = String(passage["text"])
        var page = Int(passage["page"])
        var word_count = Int(passage["word_count"])
        
        # Truncate text for display
        var display_text = text
        if len(text) > 200:
            display_text = text[:200] + "..."
        
        # Create result dictionary
        var result = py.dict()
        result["text"] = display_text
        result["page"] = page
        result["score"] = score
        result["word_count"] = word_count
        result["full_text"] = text
        
        results.append(result)
    
    print("✅ Top", count, "results ready!")
    print()
    
    return results


# ============================================================================
# MAIN SEARCH ORCHESTRATION
# ============================================================================

fn search(
    passages_file: String,
    query: String,
    top_n: Int
) raises -> PythonObject:
    """
    Main TF-IDF search function.
    
    Steps:
    1. Load passages from JSON
    2. Preprocess query (clean, tokenize, remove stopwords)
    3. Calculate IDF for each query term
    4. Score all passages using TF-IDF
    5. Sort by score and return top N
    """
    print()
    print("=" * 60)
    print("TF-IDF SEARCH ENGINE (Mojo)")
    print("=" * 60)
    print()
    print("Query:", query)
    print("Top N:", top_n)
    print()
    
    # Step 1: Load passages
    var passages = load_passages(passages_file)
    
    # Step 2: Preprocess query
    print("Preprocessing query...")
    var query_terms = preprocess_query(query)
    print("Query terms:", query_terms)
    print()
    
    # Check if we have valid terms
    if query_terms.__len__() == 0:
        print("⚠️  No valid search terms after removing stopwords!")
        var py = Python.import_module("builtins")
        return py.list()
    
    # Step 3: Calculate IDF values
    var idf_values = calculate_idf_for_terms(passages, query_terms)
    
    # Step 4: Score all passages
    var scores = score_all_passages(passages, query_terms, idf_values)
    
    # Step 5: Get top N results
    var results = get_top_n_results(passages, scores, top_n)
    
    return results


# ============================================================================
# DISPLAY RESULTS
# ============================================================================

fn display_results(results: PythonObject) raises:
    """Pretty-print search results."""
    print("=" * 60)
    print("SEARCH RESULTS")
    print("=" * 60)
    print()
    
    if results.__len__() == 0:
        print("No results found.")
        return
    
    for i in range(results.__len__()):
        var result = results[i]
        var rank = i + 1
        var score = Float64(result["score"])
        var page = Int(result["page"])
        var text = String(result["text"])
        var word_count = Int(result["word_count"])
        
        print("Rank:", rank)
        print("Score:", score)
        print("Page:", page)
        print("Length:", word_count, "words")
        print("Text:", text)
        print("-" * 60)
        print()


# ============================================================================
# MAIN - FOR TESTING (WILL CRASH)
# ============================================================================

fn main() raises:
    """
    Test function - attempts to run search.
    
    WARNING: This will crash due to Mojo Python interop bug.
             Use the Python backend instead: pixi run python src/extract_pdf.py search
    """
    print()
    print("⚠️  WARNING: This will crash due to Mojo Python interop bug")
    print("   Use instead: pixi run python src/extract_pdf.py search")
    print()
    
    var results = search(
        "data/passages.json",
        "research excellence",
        5
    )
    
    display_results(results)