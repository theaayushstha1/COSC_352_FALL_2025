#!/usr/bin/env python3
# src/search_fallback.py
import sys
import math
import re
from pathlib import Path
from collections import Counter, defaultdict

_TOKEN_RE = re.compile(r"[A-Za-z0-9']+")
_STOPWORDS = {
    'the','and','is','in','to','a','of','for','on','that','this','with','as','an','are','be','by','it','from'
}

def tokenize(text):
    return _TOKEN_RE.findall(text.lower())

def filter_tokens(tokens):
    return [t for t in tokens if t not in _STOPWORDS]

def read_passages(path):
    passages = []
    path = Path(path)
    if not path.exists():
        raise FileNotFoundError(f"Passage file not found: {path}")
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.rstrip('\n')
            if not line:
                continue
            # allow format: page|id|text  or page|text
            parts = line.split('|', 2)
            if len(parts) == 3:
                page_s, pid_s, text = parts
                try:
                    page = int(page_s)
                    pid = int(pid_s)
                except:
                    page = None
                    pid = None
            elif len(parts) == 2:
                page = int(parts[0])
                pid = None
                text = parts[1]
            else:
                continue
            passages.append({'page': page, 'id': pid, 'text': text})
    return passages

def build_index(passages):
    P = len(passages)
    doc_freq = defaultdict(int)
    passage_tokens = []
    for i, p in enumerate(passages):
        tokens = filter_tokens(tokenize(p['text']))
        passage_tokens.append(tokens)
        unique = set(tokens)
        for t in unique:
            doc_freq[t] += 1
    return passage_tokens, doc_freq, P

def compute_idf(df, P):
    idf = {}
    for term, dfc in df.items():
        idf[term] = math.log((P + 1) / (dfc + 1)) + 1.0
    return idf

def score_passage(tokens, query_terms, idf):
    # build tf for passage but only for terms in query
    tf = Counter(tokens)
    raw = 0.0
    for t in query_terms:
        tf_t = tf.get(t, 0)
        if tf_t <= 0:
            continue
        tf_scaled = 1.0 + math.log(tf_t)
        idf_t = idf.get(t, math.log(1 + 1.0))  # fallback
        raw += tf_scaled * idf_t
    # normalize by length
    length = max(1, len(tokens))
    score = raw / math.sqrt(length)
    return score

def make_snippet(text, query_terms, width=120):
    lowered = text.lower()
    idx = None
    for t in query_terms:
        i = lowered.find(t)
        if i >= 0:
            idx = i
            break
    if idx is None:
        # return beginning truncated
        return (text[:width] + '...') if len(text) > width else text
    start = max(0, idx - width//4)
    end = min(len(text), start + width)
    snippet = text[start:end]
    if start > 0:
        snippet = '...' + snippet
    if end < len(text):
        snippet = snippet + '...'
    return snippet.replace('\n', ' ')

def main():
    if len(sys.argv) < 3:
        print("Usage: python src/search_fallback.py <passages.txt> \"query string\" [top_n]")
        sys.exit(1)
    passages_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3]) if len(sys.argv) > 3 else 5

    passages = read_passages(passages_path)
    if not passages:
        print("No passages found. Run the extractor first.")
        sys.exit(1)

    passage_tokens, df, P = build_index(passages)
    idf = compute_idf(df, P)

    qtokens = filter_tokens(tokenize(query))
    if not qtokens:
        print("Query contained only stopwords or nothing meaningful after tokenization.")
        sys.exit(1)
    # unique query terms
    qterms = list(dict.fromkeys(qtokens))

    scores = []
    for i, tokens in enumerate(passage_tokens):
        sc = score_passage(tokens, qterms, idf)
        scores.append((sc, i))

    # sort descending
    scores.sort(key=lambda x: x[0], reverse=True)
    print(f'Results for: "{query}"\n')
    printed = 0
    for rank, (score, idx) in enumerate(scores[:top_n], start=1):
        if score <= 0:
            continue
        p = passages[idx]
        snippet = make_snippet(p['text'], qterms)
        page_info = f"(page {p['page']})" if p.get('page') is not None else ""
        print(f"[{rank}] Score: {score:.2f} {page_info}")
        print(f"    \"{snippet}\"\n")
        printed += 1
    if printed == 0:
        print("No relevant passages found.")

if __name__ == "__main__":
    main()