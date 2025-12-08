# pdfsearch.mojo
#
# Mojo command-line search tool over pre-extracted passages.
#
# Usage:
#   mojo run pdfsearch.mojo passages.tsv "query string" 3
#   mojo run pdfsearch.mojo passages.tsv "query string" 3 --scalar  # disable SIMD
#
# The TSV should have lines like:
#   <page_number>\t<passage_text>

from sys import argv
from math import log
from builtin.simd import SIMD, Float64
from collections import List

alias Vec4 = SIMD[Float64, 4]


struct Passage:
    var page: Int
    var text: String
    var tokens: List[String]
    var tf: List[Int]
    var length: Int

    fn __init__(inout self, page: Int, text: String):
        self.page = page
        self.text = text
        self.tokens = List[String]()
        self.tf = List[Int]()
        self.length = 0


struct Result:
    var score: Float64
    var page: Int
    var snippet: String

    fn __init__(inout self, score: Float64, page: Int, snippet: String):
        self.score = score
        self.page = page
        self.snippet = snippet


fn is_stopword(word: String) -> Bool:
    # Very small stopword list to downweight extremely common words.
    let stops = [
        "the", "and", "of", "to", "in", "for", "a", "an",
        "on", "is", "are", "with", "that", "this", "by", "from"
    ]
    for s in stops:
        if word == s:
            return True
    return False


fn normalize_text(raw: String) -> String:
    # Lowercase and convert non-alphanumeric to spaces
    var s = raw.lower()
    var out = String()
    for c in s:
        # ASCII only, per current Mojo String support
        let code = ord(String(c))
        let is_digit = code >= ord("0") and code <= ord("9")
        let is_lower = code >= ord("a") and code <= ord("z")
        if is_digit or is_lower:
            out += String(c)
        else:
            out += " "
    return out


fn tokenize(raw: String) -> List[String]:
    let norm = normalize_text(raw)
    let parts = norm.split(" ")
    var tokens = List[String]()
    for p in parts:
        let w = p.strip()
        if len(w) == 0:
            continue
        if not is_stopword(w):
            tokens.append(w)
    return tokens


fn load_passages(path: String) -> List[Passage]:
    var contents = String()
    with open(path, "r") as f:
        contents = f.read()

    var passages = List[Passage]()
    let lines = contents.split("\n")
    for line in lines:
        let trimmed = line.strip()
        if len(trimmed) == 0:
            continue
        let cols = trimmed.split("\t")
        if len(cols) < 2:
            continue
        let page_str = cols[0]
        let text = cols[1]
        let page_num = int(page_str)  # String -> Int
        var p = Passage(page_num, text)
        passages.append(p)
    return passages


fn compute_tf_df(
    mut passages: List[Passage],
    query_terms: List[String],
    out_df: inout List[Int]
) -> Int:
    let num_terms = len(query_terms)
    let num_passages = len(passages)

    out_df = List[Int](length=num_terms, fill=0)

    if num_terms == 0 or num_passages == 0:
        return num_passages

    for i in range(num_passages):
        ref p = passages[i]
        p.tokens = tokenize(p.text)
        p.length = len(p.tokens)
        p.tf = List[Int](length=num_terms, fill=0)

        var seen = List[Bool](length=num_terms, fill=False)

        for token in p.tokens:
            for t_idx in range(num_terms):
                if token == query_terms[t_idx]:
                    p.tf[t_idx] += 1
                    if not seen[t_idx]:
                        out_df[t_idx] += 1
                        seen[t_idx] = True
        # done one passage

    return num_passages


fn compute_idf(df: List[Int], num_passages: Int) -> List[Float64]:
    let num_terms = len(df)
    var idf = List[Float64](length=num_terms, fill=0.0)
    if num_passages == 0:
        return idf

    for i in range(num_terms):
        let df_i = df[i]
        let num_f = Float64(num_passages + 1)
        let den_f = Float64(df_i + 1)
        let val = log(num_f / den_f) + 1.0
        idf[i] = val
    return idf


fn score_passage_scalar(
    tf: List[Int],
    idf: List[Float64],
    length_tokens: Int,
    avg_len: Float64
) -> Float64:
    let num_terms = len(tf)
    if num_terms == 0 or length_tokens == 0:
        return 0.0

    var base_score: Float64 = 0.0
    for i in range(num_terms):
        let freq = tf[i]
        if freq <= 0:
            continue
        let tf_f = Float64(freq)
        let tf_weight = 1.0 + log(tf_f)
        base_score += tf_weight * idf[i]

    let len_f = Float64(length_tokens)
    let norm = 0.25 + 0.75 * (len_f / avg_len)
    return base_score / norm


fn score_passage_simd(
    tf: List[Int],
    idf: List[Float64],
    length_tokens: Int,
    avg_len: Float64
) -> Float64:
    let num_terms = len(tf)
    if num_terms == 0 or length_tokens == 0:
        return 0.0

    # Precompute weighted contributions for each term:
    var contribs = List[Float64](length=num_terms, fill=0.0)
    for i in range(num_terms):
        let freq = tf[i]
        if freq <= 0:
            contribs[i] = 0.0
        else:
            let tf_f = Float64(freq)
            let tf_weight = 1.0 + log(tf_f)
            contribs[i] = tf_weight * idf[i]

    # SIMD reduction over contribs
    var acc = Vec4(0.0, 0.0, 0.0, 0.0)
    var idx: Int = 0
    let n = num_terms

    while idx + 4 <= n:
        let v = Vec4(contribs[idx], contribs[idx + 1], contribs[idx + 2], contribs[idx + 3])
        acc = acc + v
        idx += 4

    var base_score: Float64 = 0.0
    # Horizontal sum of acc
    for k in range(4):
        base_score += acc[k]

    # Tail elements
    while idx < n:
        base_score += contribs[idx]
        idx += 1

    let len_f = Float64(length_tokens)
    let norm = 0.25 + 0.75 * (len_f / avg_len)
    return base_score / norm


fn choose_score(
    use_scalar: Bool,
    tf: List[Int],
    idf: List[Float64],
    length_tokens: Int,
    avg_len: Float64
) -> Float64:
    if use_scalar:
        return score_passage_scalar(tf, idf, length_tokens, avg_len)
    else:
        return score_passage_simd(tf, idf, length_tokens, avg_len)


fn insert_top_result(
    mut results: List[Result],
    max_results: Int,
    new_res: Result
):
    let current = len(results)
    if current == 0:
        results.append(new_res)
        return

    var pos: Int = 0
    while pos < current and results[pos].score > new_res.score:
        pos += 1

    if pos < max_results:
        results.insert(pos, new_res)
        if len(results) > max_results:
            # drop the last
            let _ = results.pop()
    else:
        # lower than all existing top results; ignore if full
        if current < max_results:
            results.append(new_res)


fn make_snippet(text: String, max_len: Int = 200) -> String:
    let trimmed = text.strip()
    if len(trimmed) <= max_len:
        return trimmed
    # Simple truncation with ellipsis
    var out = trimmed[0:max_len]
    out += "..."
    return out


def main():
    let args = argv()
    # Expected:
    #   args[0] = program name
    #   args[1] = TSV path
    #   args[2] = query string
    #   args[3] = N
    # Optional:
    #   args[4] = "--scalar" to disable SIMD

    if len(args) < 4:
        print("Usage: mojo run pdfsearch.mojo passages.tsv \"query\" N [--scalar]")
        return

    let tsv_path = args[1]
    let query = args[2]
    let n_str = args[3]

    var use_scalar = False
    if len(args) >= 5 and args[4] == "--scalar":
        use_scalar = True

    let n_results = int(n_str)
    if n_results <= 0:
        print("N must be positive.")
        return

    var passages = load_passages(tsv_path)
    let num_passages = len(passages)
    if num_passages == 0:
        print("No passages loaded from", tsv_path)
        return

    # Process query
    var query_tokens = tokenize(query)

    # Deduplicate query tokens while preserving order
    var unique_terms = List[String]()
    for token in query_tokens:
        var seen = False
        for existing in unique_terms:
            if token == existing:
                seen = True
                break
        if not seen:
            unique_terms.append(token)

    if len(unique_terms) == 0:
        print("Query has no non-stopword terms. Please try a different query.")
        return

    # Compute TF, DF
    var df = List[Int]()
    let actual_passages = compute_tf_df(passages, unique_terms, df)
    if actual_passages == 0:
        print("No passages contained any tokens.")
        return

    # Average passage length
    var total_len: Int = 0
    for p in passages:
        total_len += p.length

    let avg_len = Float64(total_len) / Float64(actual_passages)

    # IDF
    let idf = compute_idf(df, actual_passages)

    # Score all passages and keep top N
    var top_results = List[Result]()
    for p in passages:
        let score = choose_score(use_scalar, p.tf, idf, p.length, avg_len)
        if score <= 0.0:
            continue
        let snippet = make_snippet(p.text)
        var res = Result(score, p.page, snippet)
        insert_top_result(top_results, n_results, res)

    print("Results for: \"" + query + "\"\n")

    if len(top_results) == 0:
        print("No relevant passages found.")
        return

    var rank: Int = 1
    for r in top_results:
        let rank_str = rank.__str__()
        let score_str = r.score.__str__()
        let page_str = r.page.__str__()

        print("[" + rank_str + "] Score: " + score_str + " (page " + page_str + ")")
        print("    \"" + r.snippet + "\"\n")
        rank += 1
