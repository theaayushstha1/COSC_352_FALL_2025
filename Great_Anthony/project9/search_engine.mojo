from sys import argv
from math import sqrt, log

struct Passage:
    var id: Int
    var page: Int
    var content: String
    var score: Float64
    
    fn __init__(inout self, id: Int, page: Int, content: String):
        self.id = id
        self.page = page
        self.content = content
        self.score = 0.0

fn read_file(filepath: String) raises -> String:
    """Read entire file content"""
    var content = String("")
    with open(filepath, "r") as f:
        content = f.read()
    return content

fn split_into_passages(text: String) raises -> List[Passage]:
    """Split extracted text into passages based on paragraph breaks"""
    var passages = List[Passage]()
    var current_passage = String("")
    var passage_id = 0
    var current_page = 1
    
    var lines = text.split("\n")
    
    for i in range(len(lines)):
        var line = lines[i]
        
        # Detect page breaks (form feed character)
        if line.find("\f") != -1:
            if len(current_passage.strip()) > 0:
                passages.append(Passage(passage_id, current_page, current_passage.strip()))
                passage_id += 1
                current_passage = ""
            current_page += 1
            continue
        
        var stripped_line = line.strip()
        
        # Empty line marks paragraph boundary
        if len(stripped_line) == 0:
            if len(current_passage.strip()) > 10:
                passages.append(Passage(passage_id, current_page, current_passage.strip()))
                passage_id += 1
                current_passage = ""
        else:
            if len(current_passage) > 0:
                current_passage = current_passage + " " + stripped_line
            else:
                current_passage = stripped_line
    
    # Add final passage
    if len(current_passage.strip()) > 10:
        passages.append(Passage(passage_id, current_page, current_passage.strip()))
    
    return passages

fn tokenize(text: String) raises -> List[String]:
    """Tokenize text into lowercase words"""
    var tokens = List[String]()
    var lower_text = text.lower()
    
    var words = lower_text.split()
    
    for i in range(len(words)):
        var word = words[i]
        
        # Remove punctuation
        word = word.replace(",", "")
        word = word.replace(".", "")
        word = word.replace(":", "")
        word = word.replace(";", "")
        word = word.replace("(", "")
        word = word.replace(")", "")
        word = word.replace("!", "")
        word = word.replace("?", "")
        word = word.replace("\"", "")
        word = word.replace("'", "")
        
        if len(word) > 0:
            tokens.append(word)
    
    return tokens

fn count_occurrences(term: String, tokens: List[String]) -> Int:
    """Count how many times a term appears in token list"""
    var count = 0
    var term_lower = term.lower()
    
    for i in range(len(tokens)):
        if tokens[i] == term_lower:
            count += 1
    
    return count

fn calculate_idf(term: String, passages: List[Passage]) raises -> Float64:
    """Calculate Inverse Document Frequency"""
    var doc_count = 0
    var term_lower = term.lower()
    
    for i in range(len(passages)):
        var content_lower = passages[i].content.lower()
        if content_lower.find(term_lower) != -1:
            doc_count += 1
    
    if doc_count == 0:
        return 0.0
    
    var total_docs = Float64(len(passages))
    var df = Float64(doc_count)
    
    return log(total_docs / df)

fn calculate_tf_idf(
    passage_tokens: List[String],
    query_terms: List[String],
    idf_scores: List[Float64]
) -> Float64:
    """Calculate TF-IDF score with diminishing returns and length normalization"""
    var score = Float64(0.0)
    var passage_length = Float64(len(passage_tokens))
    
    if passage_length == 0:
        return 0.0
    
    # Length normalization factor
    var length_norm = sqrt(passage_length)
    
    for i in range(len(query_terms)):
        var term = query_terms[i]
        var tf = Float64(count_occurrences(term, passage_tokens))
        
        if tf > 0:
            # Sublinear TF scaling
            var scaled_tf = 1.0 + log(tf)
            
            # Get IDF score
            var idf = idf_scores[i]
            
            # TF-IDF with length normalization
            var tf_idf = (scaled_tf / length_norm) * idf
            
            score += tf_idf
    
    return score

fn rank_passages(inout passages: List[Passage], query: String) raises:
    """Rank passages using TF-IDF algorithm"""
    var query_terms = tokenize(query)
    
    # Calculate IDF for each query term
    var idf_scores = List[Float64]()
    for i in range(len(query_terms)):
        var idf = calculate_idf(query_terms[i], passages)
        idf_scores.append(idf)
    
    # Calculate score for each passage
    for i in range(len(passages)):
        var passage_tokens = tokenize(passages[i].content)
        passages[i].score = calculate_tf_idf(passage_tokens, query_terms, idf_scores)

fn sort_passages_by_score(inout passages: List[Passage]):
    """Bubble sort passages by score (descending)"""
    var n = len(passages)
    
    for i in range(n):
        for j in range(0, n - i - 1):
            if passages[j].score < passages[j + 1].score:
                # Swap
                var temp = passages[j]
                passages[j] = passages[j + 1]
                passages[j + 1] = temp

fn main() raises:
    # Parse command-line arguments
    var args = argv()
    if len(args) != 4:
        print("Error: Expected 3 arguments")
        print("Usage: mojo search_engine.mojo <text_file> <query> <num_results>")
        return
    
    var text_file = args[1]
    var query = args[2]
    var num_results = atol(args[3])
    
    # Read extracted text
    print("Reading extracted text...")
    var text = read_file(text_file)
    
    # Split into passages
    print("Splitting into passages...")
    var passages = split_into_passages(text)
    
    if len(passages) == 0:
        print("Error: No passages found in document")
        return
    
    print("Found " + String(len(passages)) + " passages")
    
    # Rank passages
    print("Ranking passages by relevance...")
    rank_passages(passages, query)
    
    # Sort by score (descending)
    sort_passages_by_score(passages)
    
    # Display results
    print("\nResults for: \"" + query + "\"")
    print()
    
    var results_to_show = min(num_results, len(passages))
    var shown = 0
    
    for i in range(len(passages)):
        if shown >= results_to_show:
            break
        
        if passages[i].score > 0.0:
            shown += 1
            var score_str = String(passages[i].score)
            var truncated_score = score_str[:min(6, len(score_str))]
            print("[" + String(shown) + "] Score: " + truncated_score + " (page " + String(passages[i].page) + ")")
            
            # Truncate content to ~200 characters
            var display_content = passages[i].content
            if len(display_content) > 200:
                display_content = display_content[:200] + "..."
            
            print("    \"" + display_content + "\"")
            print()
    
    if shown == 0:
        print("No relevant passages found for query: \"" + query + "\"")
