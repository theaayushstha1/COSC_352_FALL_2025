import sys
from pypdf import PdfReader

def main():
    # 1. Read Arguments from sys.argv
    if len(sys.argv) != 4:
        print(sys.argv)
        print("[ERROR] Usage: ./pdfsearch <document.pdf> \"<query>\" <N>")
        sys.exit(1)

    pdf_path = sys.argv[1]
    query_string = sys.argv[2]
    N_results = int(sys.argv[3])

    print(pdf_path, query_string)

    clean_passages(pdf_path)


def clean_passages(pdf_path: str):
    passages = []
    reader = PdfReader(pdf_path)
    file_path = 'pdf_text.txt'

    with open(file_path, 'w') as f:
        pass

    for page_num, page in enumerate(reader.pages):

        text = page.extract_text()
        paragraphs = text.split('.\n')

        for paragraph in paragraphs:
            clean_text = ' '.join(paragraph.strip().split())
            
            clean_text = clean_text.replace("\n", "")
            clean_text = clean_text.replace("|", "")


            with open(file_path, "a") as f:
                f.write(str(page_num) + "|" + clean_text + "\n")


print()
main()