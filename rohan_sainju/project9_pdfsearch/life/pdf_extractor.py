"""
PDF text extraction utility
Uses PyPDF2 to extract text with page information
"""
import sys
try:
    from PyPDF2 import PdfReader
except ImportError:
    print("PyPDF2 not installed. Install with: pip install PyPDF2")
    sys.exit(1)

def extract_text_from_pdf(pdf_path):
    """
    Extract text from PDF file with page numbers
    
    Returns:
        List of tuples: [(page_num, text), ...]
    """
    try:
        reader = PdfReader(pdf_path)
        pages_text = []
        
        for page_num, page in enumerate(reader.pages, start=1):
            text = page.extract_text()
            if text.strip():
                pages_text.append((page_num, text))
        
        return pages_text
    
    except FileNotFoundError:
        print(f"Error: File '{pdf_path}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading PDF: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python pdf_extractor.py <pdf_file>")
        sys.exit(1)
    
    pages = extract_text_from_pdf(sys.argv[1])
    for page_num, text in pages:
        print(f"=== Page {page_num} ===")
        print(text[:200])
        print()
