from math import log, sqrt

# ============================================================================
# TEXT CLEANING (Pure Mojo - No character iteration)
# ============================================================================

fn to_lowercase(text: String) -> String:
    """Convert text to lowercase."""
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
    
    # Collapse spaces
    for _ in range(10):
        cleaned = cleaned.replace("  ", " ")
    
    return cleaned


# ============================================================================
# STOPWORDS
# ============================================================================

fn is_stopword(word: String) -> Bool:
    """Check if word is a common stopword."""
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


# ============================================================================
# TERM COUNTING
# ============================================================================

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
    """Calculate TF with log scaling."""
    if term_count == 0:
        return 0.0
    return log(1.0 + Float64(term_count))


fn calculate_idf(total_passages: Int, passages_containing_term: Int) -> Float64:
    """Calculate IDF - rare terms get higher weight."""
    if passages_containing_term == 0:
        return 0.0
    var ratio = Float64(total_passages) / Float64(passages_containing_term)
    return log(ratio)


fn normalize_by_length(score: Float64, passage_length: Int) -> Float64:
    """Normalize by sqrt of passage length."""
    if passage_length == 0:
        return 0.0
    return score / sqrt(Float64(passage_length))


# ============================================================================
# MAIN - Simple test to verify module loads
# ============================================================================

fn main():
    """Simple test to verify module loads."""
    print("=" * 60)
    print("✅ utils.mojo loaded successfully!")
    print("=" * 60)
    print()
    print("Available functions:")
    print("  - to_lowercase()")
    print("  - clean_text()")
    print("  - is_stopword()")
    print("  - count_term()")
    print("  - calculate_tf_with_diminishing_returns()")
    print("  - calculate_idf()")
    print("  - normalize_by_length()")
    print()
    print("Ready to import into tfidf.mojo!")