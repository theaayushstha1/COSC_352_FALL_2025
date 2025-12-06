from collections import List
from tokenizer import tokenize

# ------------------------------------------------------------
# Scoring
# ------------------------------------------------------------

# Scoring:
# - Base score: +1 for each DISTINCT query token that appears in the passage
# - Extra bonus for repeated occurrences of each query token
# - Extra phrase bonus if the full query tokens appear consecutively
fn score_passage(query_tokens: List[String], passage_tokens: List[String]) -> Int:
    var score = 0

    var qn = len(query_tokens)
    var pn = len(passage_tokens)

    # Distinct token overlap + frequency bonus
    var seen = List[Bool]()
    var i = 0
    while i < qn:
        seen.append(False)
        i = i + 1

    i = 0
    while i < qn:
        var qt = query_tokens[i]
        var j = 0
        var count = 0
        while j < pn:
            if qt == passage_tokens[j]:
                count = count + 1
            j = j + 1

        # If token appears, +1 for presence and + (count - 1) for repeats
        if count > 0 and not seen[i]:
            seen[i] = True
            score = score + 1 + (count - 1)

        i = i + 1

    # Phrase bonus: query tokens appear as a consecutive sequence
    if qn > 1 and pn >= qn:
        var start = 0
        while start <= pn - qn:
            var all_match = True
            var k = 0
            while k < qn:
                if passage_tokens[start + k] != query_tokens[k]:
                    all_match = False
                    break
                k = k + 1

            if all_match:
                # Bonus proportional to phrase length, doubled
                score = score + (qn * 2)
                break

            start = start + 1

    return score


# ------------------------------------------------------------
# Snippet builder
# ------------------------------------------------------------

fn make_snippet(text: String, max_chars: Int) -> String:
    var n = len(text)
    if n <= max_chars:
        return text

    var words = text.split(" ")

    var snippet = String("")
    var current_len = 0
    var first = True

    for w_slice in words:
        if len(w_slice) == 0:
            continue

        var w = String(w_slice)
        var added_len = len(w)
        if not first:
            added_len = added_len + 1   # space

        if current_len + added_len > max_chars:
            break

        if first:
            snippet = w
            current_len = len(w)
            first = False
        else:
            snippet = snippet + " " + w
            current_len = current_len + added_len

    snippet = snippet + "..."
    return snippet


# ------------------------------------------------------------
# Main ranking function used by main.mojo
# ------------------------------------------------------------

fn rank_passages(
    query: String,
    ids: List[String],
    texts: List[String],
    pages: List[Int],
    top_n: Int
) -> None:

    var query_tokens = tokenize(query)
    var n = len(ids)

    # Compute scores for each passage
    var scores = List[Int]()
    var i = 0
    while i < n:
        var passage_tokens = tokenize(texts[i])
        var s = score_passage(query_tokens, passage_tokens)
        scores.append(s)
        i = i + 1

    # Build indices list 0..n-1
    var indices = List[Int]()
    i = 0
    while i < n:
        indices.append(i)
        i = i + 1

    # Selection sort indices by scores, highest first
    var m = len(indices)
    var a = 0
    while a < m:
        var best = a
        var b = a + 1
        while b < m:
            if scores[indices[b]] > scores[indices[best]]:
                best = b
            b = b + 1

        if best != a:
            var tmp = indices[a]
            indices[a] = indices[best]
            indices[best] = tmp

        a = a + 1

    # Print results
    print("Results for: \"" + query + "\"\n")

    var k = 0
    while k < m and k < top_n:
        var idx = indices[k]
        var rank_str = String(k + 1)
        var score_str = String(scores[idx])
        var page_str = String(pages[idx])

        print("[" + rank_str + "] Score: " + score_str + " (page " + page_str + ")")
        var snippet = make_snippet(texts[idx], 160)
        print("    " + snippet)
        print("")

        k = k + 1


