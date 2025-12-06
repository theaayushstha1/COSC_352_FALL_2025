# pdfsearch_simd_cli.py
import sys
from pdfsearch_simd_core import search_simd

def main():
    if len(sys.argv) != 4:
        print("Usage: ./pdfsearch_simd <pdf_file> <query> <num_results>")
        sys.exit(1)

    pdf_file = sys.argv[1]
    query = sys.argv[2]
    n = int(sys.argv[3])

    passages_json = "passages.json"  # from pdf_extractor.py
    results = search_simd(pdf_file, passages_json, query, n)

    print(f'\nResults for: "{query}"\n')
    for i, r in enumerate(results, start=1):
        score = f"{r['score']:.3f}"
        page = r["page"]
        text = r["text"]
        snippet = (text[:180] + "...") if len(text) > 180 else text
        print(f"[{i}] Score: {score} (page {page})")
        print(f'    "{snippet}"\n')

if __name__ == "__main__":
    main()
