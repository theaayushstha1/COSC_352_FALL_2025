# Project 9 – Morgan 2030 PDF Search (Mojo)

This project implements a command-line tool in **Mojo** that searches the Morgan 2030 PDF document for passages relevant to a user's query.

The system takes:

- A single Morgan 2030 PDF file
- A search string (one or more keywords)
- A number of results to return (top N)

and returns the top N most relevant passages ranked by a custom relevance score.

Core search and ranking logic is implemented with Mojo's standard libraries. Python is used **only** for PDF text extraction.

## How it Works

1. A small Python helper (`src/pdf_extract.py`) uses `pypdf` to extract page text from the Morgan 2030 PDF and writes a `pages.txt` file with **one cleaned page per line**.
2. The Mojo program (`src/search.mojo`) reads `pages.txt`, tokenizes each page, computes IDF-style weights, and scores pages based on:
	- How often query terms appear (with diminishing returns using `sqrt` of frequency)
	- How rare the terms are across the document (IDF weighting)
	- Length-normalized scores so longer pages do not automatically win
3. The tool prints the **top N pages** with:
	- Page number
	- Relevance score
	- A short snippet of text that includes the query terms

## How to Run

From the repository root:

```bash
cd christian_douglass/project9/src

# 1. (One time) install the Python dependency for PDF extraction
pip install pypdf

# 2. Extract pages from the Morgan 2030 PDF into a pages file
python pdf_extract.py /path/to/Morgan_2030.pdf ../pages.txt

# 3. Run the Mojo search tool over the extracted pages
#    Adjust the 'mojo' command to match your Mojo toolchain.
mojo run search.mojo ../pages.txt "climate change goals" 5
```

This will output the top 5 most relevant pages, including their page numbers, scores, and short surrounding snippets.

## Files

- `src/pdf_extract.py` – Python helper that reads a PDF and writes a `pages.txt` file with one cleaned page of text per line.
- `src/search.mojo` – Mojo program implementing tokenization, IDF computation, passage scoring, and ranking using only the Mojo standard library.
- `README.md` – This documentation and usage guide.
