import sys
from pypdf import PdfReader

def main():
    if len(sys.argv) != 3:
        print("Usage: python pdf_extract.py <input.pdf> <output.txt>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    out_path = sys.argv[2]

    reader = PdfReader(pdf_path)

    with open(out_path, "w", encoding="utf-8") as out:
        for page_num, page in enumerate(reader.pages, start=1):
            text = page.extract_text() or ""
            out.write(f"=== PAGE {page_num} ===\n")
            out.write(text)
            out.write("\n\n")

if __name__ == "__main__":
    main()