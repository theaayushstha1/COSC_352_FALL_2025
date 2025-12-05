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

## Performance and SIMD Plan

The current implementation uses a clear **scalar baseline** for text processing, which is sufficient for correctness and ranking quality. On a full Mojo installation, the main performance hotspot is the `tokenize` function in `src/search.mojo`, which walks each page's text character by character.

To satisfy the SIMD performance requirement, the next step would be to introduce a `tokenize_simd` variant that:

- Loads the input string in fixed-size chunks into SIMD vector types.
- Converts ASCII `A–Z` to lowercase in parallel within each vector.
- Classifies characters as alphanumeric vs separators in parallel, to decide where tokens begin and end.

Both `tokenize` (scalar) and `tokenize_simd` would produce identical token lists for each page. We can then benchmark them on the actual `pages.txt` file by timing a full pass over all pages:

1. Time the scalar baseline by running `tokenize` over every page and recording the total elapsed time.
2. Time the SIMD version by running `tokenize_simd` over every page with the same input.
3. Compute and report the speedup factor, e.g. `scalar_time / simd_time`, in this README.

This design keeps the Mojo standard-library based search logic unchanged while providing a clear and measurable path to SIMD acceleration for text processing.

## Files

- `src/pdf_extract.py` – Python helper that reads a PDF and writes a `pages.txt` file with one cleaned page of text per line.
- `src/search.mojo` – Mojo program implementing tokenization, IDF computation, passage scoring, and ranking using only the Mojo standard library.
- `README.md` – This documentation and usage guide.
