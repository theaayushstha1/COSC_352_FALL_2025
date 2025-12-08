from python import Python
from utils import split, lower
from math import log
import json

fn tokenize(text: String) -> List[String]:
    let mut out = List[String]()
    var word = String()
    for c in text:
        if c.is_alphanumeric():
            word.push(c.lower())
        else:
            if word.size() > 0:
                out.append(word)
            word = String()
    if word.size() > 0:
        out.append(word)
    return out

fn compute_idf(pages: List[String], terms: List[String]) -> Dict[String, Float64]:
    let N = pages.size()
    var idf = Dict[String, Float64]()
    for term in terms:
        var df = 0
        for page in pages:
            let words = tokenize(page)
            if term in words:
                df += 1
        if df == 0:
            df = 1
        idf[term] = log((N + 1) / df)
    return idf

# -----------------------------
# Score a passage
# -----------------------------
fn score_passage(page_text: String,
                 terms: List[String],
                 idf: Dict[String, Float64]) -> Float64:

    let words = tokenize(page_text)
    let mut counts = Dict[String, Int]()
    for t in terms:
        counts[t] = 0

    for w in words:
        if w in counts:
            counts[w] += 1

    var score: Float64 = 0.0
    for t in terms:
        let tf = counts[t]
        if tf > 0:
            # log-scaled term frequency
            score += (1 + log(tf)) * idf[t]
    return score

fn main():
    let args = Python.sys.argv
    if args.len() < 4:
        print("Usage: pdfsearch pages.json \"query\" N")
        return

    # Load page texts
    let json_text = open(args[1]).read()
    let pages = json.loads(json_text).as[List[String]]()

    let query = args[2].lower()
    let n = Int(args[3])

    let terms = tokenize(query)
    let idf = compute_idf(pages, terms)

    # Score each page
    var scored = List[(Float64, Int)]()
    for i in range(pages.size()):
        let s = score_passage(pages[i], terms, idf)
        if s > 0:
            scored.append((s, i))

    # Sort by decreasing score
    scored.sort(by = (a, b) -> b[0] <=> a[0])

    print(f"Results for: \"{query}\"")
    print()

    for (rank, (score, page_idx)) in enumerate(scored[:n]):
        print(f"[{rank+1}] Score: {score:.2f} (page {page_idx+1})")
        let snippet = pages[page_idx][0:200].replace("\n", " ")
        print(f"    \"{snippet}...\"")
        print()
