# pdfsearch_simd_core.py
import json
import math
from typing import List, Dict
import numpy as np

STOPWORDS = {
    "the","a","an","is","are","was","were","to","of","and","in","on","for",
    "with","as","by","at","that","this","it","from","or","be","we","our"
}

def tokenize(text: str) -> List[str]:
    import re
    text = text.lower()
    tokens = re.findall(r"[a-z0-9]+", text)
    return [t for t in tokens if t not in STOPWORDS]

def load_passages(json_path: str) -> List[Dict]:
    with open(json_path, "r", encoding="utf-8") as f:
        return json.load(f)

def build_tfidf_scores_simd(passages: List[Dict], query: str) -> List[Dict]:
    query_terms = tokenize(query)
    if not query_terms:
        return []

    tokenized = [tokenize(p["text"]) for p in passages]

    df = {term: 0 for term in set(query_terms)}
    for tokens in tokenized:
        arr = np.array(tokens, dtype=object)
        for term in df.keys():
            if (arr == term).any():
                df[term] += 1

    N = len(passages)
    results: List[Dict] = []

    for idx, p in enumerate(passages):
        tokens = tokenized[idx]
        if not tokens:
            continue
        arr = np.array(tokens, dtype=object)
        length = len(tokens)
        score = 0.0

        for term in query_terms:
            c = int((arr == term).sum())
            if c == 0:
                continue
            tf = 1.0 + math.log(c)
            df_term = max(df.get(term, 1), 1)
            idf = math.log(N / df_term)
            score += tf * idf

        score /= math.sqrt(length)
        results.append({"page": p["page"], "text": p["text"], "score": score})

    results.sort(key=lambda r: r["score"], reverse=True)
    return results

def search_simd(pdf_file: str, passages_json: str, query: str, k: int) -> List[Dict]:
    passages = load_passages(passages_json)
    scored = build_tfidf_scores_simd(passages, query)
    return scored[:k]
