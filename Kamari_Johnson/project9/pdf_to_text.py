import sys
import pdfplumber

def main():
    pdf = sys.argv[1]
    txt = sys.argv[2]

    with pdfplumber.open(pdf) as pdf_file, open(txt, "w", encoding="utf-8") as out:
        for page_idx, page in enumerate(pdf_file.pages, start=1):
            out.write(f"===PAGE {page_idx}===\n")
            text = page.extract_text()
            if text:
                out.write(text)
            out.write("\n\n")

if __name__ == "__main__":
    main()