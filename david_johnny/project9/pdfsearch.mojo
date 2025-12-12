import math
from sys import argv


let STOP_WORDS = [
    "a", "an", "and", "are", "as", "at", "be", "by", "for", "from",
    "has", "he", "in", "is", "it", "its", "of", "on", "that", "the",
    "to", "was", "will", "with", "the", "this", "but", "they", "have",
    "had", "what", "when", "where", "who", "which", "why", "how"
]

fn to_lower(s: String) -> String:
    var out = String()
    for c in s:
        out.push(c.lower())
    return out

fn is_stop_word(word: String) -> Bool:
    for sw in STOP_WORDS:
        if word == sw:
            return True
    return False

fn tokenize(text: String) -> List[String]:
    var tokens = List[String]()
    var current = String()
    var prev_char = ""
    
    for i in range(text.size):
        let c = text[i]
        
        if c.is_alphanumeric():
            current.push(c.lower())
        elif c == "'" or c == "-":
            if current.size > 0 and i + 1 < text.size:
                let next_c = text[i + 1]
                if next_c.is_alphanumeric():
                    current.push(c)
                else:
                    if current.size >= 2 and not is_stop_word(current):
                        tokens.push(current)
                    current = String()
            elif current.size > 0:
                if current.size >= 2 and not is_stop_word(current):
                    tokens.push(current)
                current = String()
        else:
            if current.size >= 2 and not is_stop_word(current):
                tokens.push(current)
            current = String()
    
    if current.size >= 2 and not is_stop_word(current):
        tokens.push(current)
    
    return tokens

struct Passage:
    page: Int
    text: String
    score: Float64


fn compute_idf(pages_tokens: List[List[String]]) -> Dict[String, Float64]:
    let num_docs = pages_tokens.size
    var df = Dict[String, Int]()
    for tokens in pages_tokens:
        var seen = Set[String]()
        for t in tokens:
            if not seen.contains(t):
                seen.insert(t)
                df[t] = df.get(t, 0) + 1
    var idf = Dict[String, Float64]()
    for (term, d) in df.items():
        idf[term] = log((num_docs + 1).as(Float64) / (d.as(Float64) + 1.0)) + 1.0
    return idf


fn score_passage(tokens: List[String], query_terms: List[String], idf: Dict[String, Float64]) -> Float64:
    if tokens.size == 0:
        return 0.0
    var tf = Dict[String, Int]()
    for t in tokens:
        tf[t] = tf.get(t, 0) + 1

    var score: Float64 = 0.0
    for qt in query_terms:
        let f = tf.get(qt, 0)
        if f > 0:
            let freq_part = sqrt(f.as(Float64))
            let idf_weight = idf.get(qt, 0.0)
            score += freq_part * idf_weight
    return score / sqrt(tokens.size.as(Float64))


fn find_best_snippet_position(page_text: String, query_terms: List[String], window_size: Int) -> Int:
    let lower_text = to_lower(page_text)
    var best_pos = 0
    var best_score = 0
    
    for start in range(0, page_text.size - window_size + 1, 20):
        let end = min(start + window_size, page_text.size)
        let window = lower_text[start:end]
        
        var window_score = 0
        var last_match_pos = -100
        
        for qt in query_terms:
            let idx = window.find(qt)
            if idx >= 0:
                window_score += 2
                
                if last_match_pos >= 0 and (idx - last_match_pos) < 50:
                    window_score += 1
                
                last_match_pos = idx
        
        if window_score > best_score:
            best_score = window_score
            best_pos = start
    
    return best_pos


fn extract_snippet(page_text: String, query_terms: List[String], max_chars: Int = 300) -> String:
    if page_text.size == 0:
        return "[Empty page]"
    
    if page_text.size <= max_chars:
        return highlight_terms(page_text, query_terms)
    
    let best_pos = find_best_snippet_position(page_text, query_terms, max_chars)
    
    var start = best_pos
    var end = min(start + max_chars, page_text.size)
    
    if start > 0:
        for i in range(start, max(0, start - 30), -1):
            if page_text[i] == " " or page_text[i] == "\n":
                start = i + 1
                break
    
    if end < page_text.size:
        for i in range(end, min(page_text.size, end + 30)):
            if page_text[i] == " " or page_text[i] == "\n" or page_text[i] == ".":
                end = i
                break
    
    var snippet = page_text[start:end]
    
    if start > 0:
        snippet = "..." + snippet
    if end < page_text.size:
        snippet = snippet + "..."
    
    return highlight_terms(snippet, query_terms)


fn highlight_terms(text: String, query_terms: List[String]) -> String:
    var result = text
    let lower_text = to_lower(text)
    
    for qt in query_terms:
        let qt_lower = to_lower(qt)
        var highlighted = String()
        var pos = 0
        
        while pos < result.size:
            let idx = lower_text[pos:].find(qt_lower)
            if idx < 0:
                highlighted += result[pos:]
                break
            
            highlighted += result[pos:pos + idx]
            highlighted += "**"
            highlighted += result[pos + idx:pos + idx + qt.size]
            highlighted += "**"
            
            pos = pos + idx + qt.size
        
        result = highlighted
    
    return result


fn rank_passages(pages: List[String], query: String, top_n: Int) -> List[Passage]:
    let q_tokens = tokenize(query)
    if q_tokens.size == 0:
        return List[Passage]()

    var pages_tokens = List[List[String]]()
    for p in pages:
        pages_tokens.push(tokenize(p))

    let idf = compute_idf(pages_tokens)

    var scored = List[Passage]()
    for i in range(pages.size):
        let tokens = pages_tokens[i]
        let s = score_passage(tokens, q_tokens, idf)
        if s > 0.0:
            scored.push(Passage(page=i + 1, text=pages[i], score=s))

    # sort by descending score
    scored.sort(key = fn(p: Passage) -> Float64:
        return -p.score
    )

    if scored.size <= top_n:
        return scored
    return scored[0:top_n]


fn main() -> Int:
    if argv.size != 4:
        print("Usage: mojo pdfsearch.mojo <pages_txt_file> <query> <top_n>")
        return 1

    let pages_file = String(argv[1])
    let query = String(argv[2])
    let top_n = Int(argv[3])

    var pages = List[String]()
    with open(pages_file, "r") as f:
        for line in f:
            pages.push(String(line))

    print("Searching", pages.size, "pages for:", query)
    print("Using improved tokenization (stop words filtered, min 2 chars)\n")

    let q_tokens = tokenize(query)
    print("Query tokens:", " ".join(q_tokens), "\n")

    let results = rank_passages(pages, query, top_n)

    if results.size == 0:
        print("No results found.")
        return 0

    print("Found", results.size, "relevant pages:\n")
    
    for p in results:
        print("─" * 60)
        print("Page", p.page, "│ Score:", format(p.score, ".4f"))
        print("─" * 60)
        print(extract_snippet(p.text, q_tokens, 350))
        print("\n")

    return 0


if __name__ == "__main__":
    main()