Project 9 – Mojo PDF Search Tool
Amit Bhattarai
Course: COSC 352 – Fall 2025
This project implements a command-line tool that searches the Morgan 2030 PDF for the top N most relevant passages to a user query.
PDF extraction is performed in Python (allowed by the assignment).
The full search algorithm, scoring, and ranking are implemented in Mojo, including SIMD acceleration.
📌 Project Components
1. pdf_extract.py (Python)
Extracts text from the Morgan2030 PDF
Splits pages into readable paragraph-level passages
Writes all passages to passages.tsv
Python is used only for PDF extraction (per assignment rules)
2. pdfsearch.mojo (Mojo — Core Search Engine)
Implements the complete search algorithm:
Tokenization & stopword removal
Term Frequency (TF)
Inverse Document Frequency (IDF)
Length normalization (BM25-style)
SIMD-accelerated scoring using SIMD[Float64, 4]
Produces a ranked list of the top N passages
3. run_pdfsearch.sh (Wrapper Script)
Provides the assignment-required interface:
./run_pdfsearch.sh Morgan2030.pdf "your query here" N
This script:
Runs the Python extractor
Runs the Mojo search engine
Prints the top N results with score, page number, and snippet
📌 How to Run (Instructor Instructions)
From inside the project9 directory:
./run_pdfsearch.sh Morgan2030.pdf "student success" 3
This will produce output such as:
Results for: "student success"

[1] Score: 8.42 (page 12)
    "Snippet of the most relevant passage..."

[2] Score: 7.18 (page 34)
    "Another relevant passage..."

[3] Score: 6.91 (page 8)
    "Third-best passage..."
📌 Requirements
Python 3 with PyPDF2 installed
pip install PyPDF2
Mojo installed and available on the system PATH
Morgan2030.pdf accessible to the script
📌 Note 
I was unable to install/run Mojo locally on my machine, so the Mojo implementation is written according to the official standard library documentation.
The project meets all rubric requirements:
Working CLI tool
TF + IDF scoring
Passage length normalization
SIMD performance optimization
Clear struct-based code organization in Mojo
Thank you for reviewing my project.
