from sys import argv
from collections import List
from pdf_loader import load_pdf
from ranking.ranking import rank_passages

fn usage():
    print("Usage: ./pdfsearch <pdf-path> \"query string\" <top-k>")

fn main() raises:
    var args = argv()
    if len(args) != 4:
        usage()
        return

    var pdf_path = String(args[1])
    var query = String(args[2])
    var k = Int(args[3])

    # Load PDF into (page, text) tuples
    var page_texts = load_pdf(pdf_path)

    # Build ids, texts, pages lists expected by rank_passages
    var ids = List[String]()
    var texts = List[String]()
    var pages = List[Int]()

    var n = len(page_texts)
    var i = 0
    while i < n:
        var tup = page_texts[i]
        var page_num = tup[0]
        var text = tup[1]

        ids.append(String(i))      # simple string id like "0", "1", ...
        pages.append(page_num)
        texts.append(text)

        i = i + 1

    # rank_passages prints the results itself
    rank_passages(query, ids, texts, pages, k)


