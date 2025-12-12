# search.mojo
# Usage: mojo run search.mojo pages.txt "query terms" 5

import sys
from math import sqrt

def tokenize(text: str) -> list[str]:
    # Very simple tokenizer: lowercase and split on whitespace
    return text.lower().replace(".", " ").replace(",", " ").split()

def score(text: str, query_terms: list[str]) -> float:
    tokens = tokenize(text)
    if not tokens:
        return 0.0
    # term frequency: count how many query terms appear
    hits = 0
    for qt in query_terms:
        hits += tokens.count(qt)
    return float(hits) / float(len(tokens))

def make_snippet(text: str, query: str, max_len: int = 200) -> str:
    lower = text.lower()
    idx = lower.find(query.lower())
    if idx == -1:
        return text[:max_len].replace("\n", " ")
    start = max(idx - 60, 0)
    end = min(idx + 60, len(text))
    return text[start:end].replace("\n", " ")

def main():
    if len(sys.argv) != 4:
        print("Usage: mojo run search.mojo <pages.txt> <query> <N>")
        sys.exit(1)

    pages_path = sys.argv[1]
    query = sys.argv[2]
    top_n = int(sys.argv[3])

    with open(pages_path, "r", encoding="utf-8") as f:
        full_text = f.read()

    # split on the markers we wrote in pdf_extract.py
    chunks = full_text.split("=== PAGE ")
    results = []

    query_terms = tokenize(query)

    for chunk in chunks:
        chunk = chunk.strip()
        if not chunk:
            continue
        # first line like: "12 ==="
        first_newline = chunk.find("\n")
        header = chunk[:first_newline]
        content = chunk[first_newline + 1 :]

        # try to get page number from header
        parts = header.split()
        try:
            page_num = int(parts[0])
        except:
            page_num = -1

        s = score(content, query_terms)
        if s > 0.0:
            snippet = make_snippet(content, query)
            results.append((s, page_num, snippet))

    # sort by score descending
    results.sort(key=lambda x: x[0], reverse=True)
    results = results[:top_n]

    print(f'Results for: "{query}"\n')
    for i, (score_val, page_num, snippet) in enumerate(results, start=1):
        print(f"[{i}] Score: {score_val:.2f} (page {page_num})")
        print(f"    {snippet}")
        print()

if __name__ == "__main__":
    main()