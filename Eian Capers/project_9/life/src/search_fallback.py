import sys
import json
from difflib import SequenceMatcher

def main():
    if len(sys.argv) != 4:
        print("Usage: python search_fallback.py <passages.txt> <query> <top_n>")
        return

    passages_file = sys.argv[1]
    query = sys.argv[2]
    k = int(sys.argv[3])  # this is safe now

    # Load passages
    with open(passages_file, "r") as f:
        passages = f.readlines()

    # Score passages
    scored = []
    for p in passages:
        score = SequenceMatcher(None, query.lower(), p.lower()).ratio()
        scored.append((score, p.strip()))

    # Sort top K
    scored.sort(reverse=True, key=lambda x: x[0])
    top = scored[:k]

    # Print results
    for i, (s, text) in enumerate(top, 1):
        print(f"[{i}] Score: {s:.4f}")
        print(f"    {text}\n")

if __name__ == "__main__":
    main()
