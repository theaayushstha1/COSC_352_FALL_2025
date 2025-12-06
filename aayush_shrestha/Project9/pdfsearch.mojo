from sys import argv
from python import Python

def main():
    args = argv()
    if args.__len__() != 4:
        print("Usage: ./pdfsearch <pdf_file> <query> <num_results>")
        return

    pdf_file = String(args[1])
    query = String(args[2])
    n = Int(String(args[3]))

    py_core = Python.import_module("pdfsearch_core")
    passages_json = "Morgan2030.json"

    results = py_core.search(pdf_file, passages_json, query, n)

    print("\nResults for: \"" + query + "\"\n")

    i = 0
    for r in results:
        score_str = String(r["score"])
        page = Int(r["page"])
        text = String(r["text"])

        print("[" + String(i + 1) + "] Score: " + score_str[0:5] +
              " (page " + String(page) + ")")

        snippet = text
        if snippet.__len__() > 180:
            snippet = snippet[0:180] + "..."
        print("    \"" + snippet + "\"")
        print("")
        i += 1
