from collections import List
from python import Python

fn load_pdf(path: String) raises -> List[Tuple[Int, String]]:
    var pypdf = Python.import_module("pypdf")
    var reader = pypdf.PdfReader(path)

    var result = List[Tuple[Int, String]]()

    var pages = reader.pages
    var n = len(pages)
    var i = 0
    while i < n:
        var page = pages[i]
        var text = String(page.extract_text())
        result.append((i + 1, text))   # (page_number, text)
        i = i + 1

    return result.copy()


