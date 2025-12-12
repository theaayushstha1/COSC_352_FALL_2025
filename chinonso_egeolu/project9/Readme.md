# Project 9: PDF Search Tool

Command-line PDF search using TF-IDF ranking.

## Usage

```bash
./pdfsearch.py <pdf_file> <query> <num_results>
```

**Example:**
```bash
./pdfsearch.py Morgan_2030.pdf "gradient descent" 3
```

## How It Works

**Passage Definition:** 3-4 consecutive sentences grouped together for context.

**Relevance Ranking (TF-IDF):**
1. **Term Frequency** - More mentions = higher score (with diminishing returns)
2. **Inverse Document Frequency** - Rare terms contribute more
3. **Length Normalization** - Prevents long passages from unfair advantage

**Common Words:** Stop words filtered out during tokenization.

## Docker

```bash
docker build -t pdf-search .
docker run --rm -v "$(pwd)/Morgan_2030.pdf:/app/Morgan_2030.pdf" pdf-search Morgan_2030.pdf "machine learning" 5
```

## Requirements

- No external search libraries ✓
- No ML/embeddings ✓
- Python only for PDF extraction (PyPDF2) ✓

## Author

Chinonso Egeolu