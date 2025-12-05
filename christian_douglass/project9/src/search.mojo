# Project 9 – Morgan 2030 PDF Search in Mojo

# NOTE: This is a conceptual Mojo implementation. It assumes a Mojo
# toolchain is available. Core ranking logic uses only Mojo stdlib.

from sys import argv

# NOTE ON PERFORMANCE / SIMD PLAN
# -------------------------------
# The current implementation uses a straightforward scalar tokenizer
# implemented in `tokenize`. On a full Mojo toolchain, this function is
# the primary hotspot we would target for SIMD acceleration:
#   - Load slices of the input string into SIMD vectors (e.g. u8 lanes).
#   - Convert ASCII A–Z to lowercase in parallel.
#   - Classify characters (alphanumeric vs separator) in parallel.
# A SIMD-accelerated `tokenize_simd` would produce the same tokens but
# process many characters per instruction. We could then benchmark
# `tokenize` (scalar) vs `tokenize_simd` (SIMD) over all pages in
# `pages.txt` and report the speedup factor in the README.

fn to_lower(s: String) -> String:
    var out = String()
    for c in s:
        out.push(c.lower())
    return out

fn tokenize(text: String) -> List[String]:
    # Scalar baseline tokenizer.
    # On a SIMD-enabled Mojo toolchain, this would be the reference
    # implementation we compare against a SIMD-accelerated version
    # that lowercases and classifies characters in vectorized chunks.
    var tokens = List[String]()
    var current = String()
    for c in text:
        if c.is_alphanumeric():
            current.push(c.lower())
        else:
            if current.size > 0:
                tokens.push(current)
                current = String()
    if current.size > 0:
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
        # Simple IDF with +1 smoothing
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
            # Diminishing returns via sqrt on frequency
            let freq_part = sqrt(f.as(Float64))
            let idf_weight = idf.get(qt, 0.0)
            score += freq_part * idf_weight
    # Normalize by length so longer passages don't dominate
    return score / sqrt(tokens.size.as(Float64))


fn extract_snippet(page_text: String, query: String, max_chars: Int = 300) -> String:
    let lower = to_lower(page_text)
    let q = to_lower(query)
    let idx = lower.find(q)
    if idx < 0:
        # fall back to start of page
        if page_text.size <= max_chars:
            return page_text
        return page_text[0:max_chars]
    var start = idx - max_chars // 2
    if start < 0:
        start = 0
    var end = start + max_chars
    if end > page_text.size:
        end = page_text.size
    return page_text[start:end]


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
        print("Usage: mojo search.mojo <pages_txt_file> <query> <top_n>")
        return 1

    let pages_file = String(argv[1])
    let query = String(argv[2])
    let top_n = Int(argv[3])

    var pages = List[String]()
    with open(pages_file, "r") as f:
        for line in f:
            # Each line in pages_file is one cleaned page of text
            pages.push(String(line))

    let results = rank_passages(pages, query, top_n)

    for p in results:
        print("Page ", p.page, " (score=", p.score, ")")
        print(extract_snippet(p.text, query))
        print("\n---\n")

    return 0


if __name__ == "__main__":
    main()
