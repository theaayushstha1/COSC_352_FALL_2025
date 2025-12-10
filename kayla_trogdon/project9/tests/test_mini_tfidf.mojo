from math import log, sqrt

fn main():
    print("=" * 60)
    print("Mini TF-IDF Test - Simple Example")
    print("=" * 60)
    print()
    
    print("Query: research excellence")
    print()
    print("Analyzing passages...")
    print()
    
    # Manually count query term occurrences in each passage
    # Passage 1: "research" appears 2 times, "excellence" appears 1 time
    var score1 = calculate_tfidf_score(2, 1, 18)  # 18 words total
    
    # Passage 2: "research" appears 0 times, "excellence" appears 0 times
    var score2 = calculate_tfidf_score(0, 0, 17)  # 17 words total
    
    # Passage 3: "research" appears 2 times, "excellence" appears 1 time
    var score3 = calculate_tfidf_score(2, 1, 13)  # 13 words total
    
    # Passage 4: "research" appears 1 time, "excellence" appears 0 times
    var score4 = calculate_tfidf_score(1, 0, 15)  # 15 words total
    
    # Print results
    print("RESULTS (sorted by relevance):")
    print("-" * 60)
    print()
    
    print("Passage 1 Score:", score1)
    print("Text: Morgan State University focuses on research excellence...")
    print("  - 'research' appears 2 times")
    print("  - 'excellence' appears 1 time")
    print()
    
    print("Passage 2 Score:", score2)
    print("Text: Students at Morgan engage in leadership development...")
    print("  - 'research' appears 0 times")
    print("  - 'excellence' appears 0 times")
    print()
    
    print("Passage 3 Score:", score3)
    print("Text: Research grants support faculty and student projects...")
    print("  - 'research' appears 2 times")
    print("  - 'excellence' appears 1 time")
    print()
    
    print("Passage 4 Score:", score4)
    print("Text: The university campus provides excellent facilities...")
    print("  - 'research' appears 1 time")
    print("  - 'excellence' appears 0 times")
    print()
    
    print("=" * 60)
    print("RANKING: Passage 1 and Passage 3 should be HIGHEST")
    print("(Both contain 'research' twice and 'excellence' once)")
    print("=" * 60)


fn calculate_tfidf_score(research_count: Int, excellence_count: Int, passage_length: Int) -> Float64:
    """Calculate TF-IDF score given term counts."""
    
    var score: Float64 = 0.0
    
    # TF for "research" with diminishing returns (log)
    if research_count > 0:
        var tf_research = log(1.0 + Float64(research_count))
        var idf_research = 1.5  # Assume moderate frequency across docs
        score += tf_research * idf_research
    
    # TF for "excellence" with diminishing returns (log)
    if excellence_count > 0:
        var tf_excellence = log(1.0 + Float64(excellence_count))
        var idf_excellence = 1.5  # Assume moderate frequency across docs
        score += tf_excellence * idf_excellence
    
    # Normalize by passage length (prevent long passages from dominating)
    if passage_length > 0:
        score = score / sqrt(Float64(passage_length))
    
    return score