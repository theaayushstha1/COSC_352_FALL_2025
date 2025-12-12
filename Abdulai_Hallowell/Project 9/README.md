# PDF Search Engine – Project 9 (Mojo)

This project is a command-line tool written in **Mojo** that searches the **Morgan 2030 PDF** for passages relevant to a user’s query. The program extracts text from the PDF, breaks it into passages, computes TF-IDF–style relevance scores, and prints the top-ranked results.

## How to Run

### 1. Install Dependencies
You must have **pixi**, **Mojo**, and **PyPDF2** installed.

```bash
pixi run pip install PyPDF2
```

### 2. Run the Search Tool

Inside the project folder:

```
mojo pdfsearch.mojo "<PDF_FILE>" "<QUERY>" <TOP_N>
```

Example:

```bash
mojo pdfsearch.mojo "AttachmentE. Transformation Morgan 2030-1.pdf" "transformation" 3
```

## Input Requirements

The program expects:

1. A single PDF file  
2. A search string (one or more keywords)  
3. The number of results to return (Top N)

## Output Format

The program prints:

- A header showing the selected PDF, query, and N  
- The top N passages ranked by TF-IDF relevance  
- The page number where each passage appears  
- A snippet (first ~250 characters) of the relevant text  

## Relevance Ranking Logic

- TF-IDF scoring  
- Repeated occurrences increase score with diminishing returns  
- Rare terms across passages get higher weight  
- Score normalized by passage length  
- Passages created from PDF paragraphs longer than 50 characters  

## Files in This Project

| File | Description |
|------|-------------|
| `pdfsearch.mojo` | Main search engine implementation |
| `AttachmentE. Transformation Morgan 2030-1.pdf` | The PDF being searched |
| `pixi.toml` | Pixi environment setup |
| `pixi.lock` | Environment lock file |

## Limitations

- Follows project constraints (no ML, no embeddings, no advanced IR libraries)  
- Uses allowed Python library **PyPDF2** only for PDF extraction  
- No SIMD implementation included (baseline version)

## Example Test

```
mojo pdfsearch.mojo "AttachmentE. Transformation Morgan 2030-1.pdf" "strategic plan" 5
```

If results appear with page numbers and scores, everything is working.

