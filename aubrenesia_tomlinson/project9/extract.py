import fitz  # PyMuPDF
import sys, json

def extract(path):
    doc = fitz.open(path)
    pages = []
    for page in doc:
        pages.append(page.get_text())
    print(json.dumps(pages))

if __name__ == "__main__":
    extract(sys.argv[1])
