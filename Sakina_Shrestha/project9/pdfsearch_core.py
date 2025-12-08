# pdfsearch_core.py
import json
import math
from typing import List, Dict

STOPWORDS = {
    "the","a","an","is","are","was","were","to","of","and","in","on","for",
    "with","as","by","at","that","this","it","from","or","be","we","our"
}

def tokenize(text: str) -> List[str]:
    # simple lower + alpha-only tokens
    import re
    text = text.lower()
    tokens = re.findall(r"[a-z0-9]+", text)
    return [t for t in tokens if t not in STOPWORDS]

def load_passages(json_path: str) -> List[Dict]:
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)

def build_tfidf_scores(passages: List[Dict], query: str) -> List[Dict]:
    query_terms = tokenize(query)
    if not query_terms:
        return []

    # Pre-tokenize passages
    tokenized = [tokenize(p["text"]) for p in passages]

    # Document frequencies
    import collections
    df = {term: 0 for term in set(query_terms)}
    for tokens in tokenized:
        unique = set(tokens)
        for term in df.keys():
            if term in unique:
                df[term] += 1

    N = len(passages)
    # For each passage, compute TF‑IDF
    results = []
    for idx, p in enumerate(passages):
        tokens = tokenized[idx]
        if not tokens:
            continue
        counts = collections.Counter(tokens)
        length = len(tokens)
        score = 0.0
        for term in query_terms:
            c = counts.get(term, 0)
            if c == 0:
                continue
            tf = 1.0 + math.log(c)
            # avoid div by zero
            df_term = max(df.get(term, 1), 1)
            idf = math.log(N / df_term)
            score += tf * idf
        # length normalization
        score /= math.sqrt(length)
        results.append({
            "page": p["page"],
            "text": p["text"],
            "score": score
        })

    # sort high score first
    results.sort(key=lambda r: r["score"], reverse=True)
    return results

def search(pdf_file: str, passages_json: str, query: str, k: int) -> List[Dict]:
    passages = load_passages(passages_json)
    scored = build_tfidf_scores(passages, query)
    return scored[:k]
