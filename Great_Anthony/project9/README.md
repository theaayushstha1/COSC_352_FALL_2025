# Project 9: PDF Search Engine

A command-line tool that searches PDF documents for passages relevant to a user's query using TF-IDF ranking.

## Architecture

- **Bash CLI** (`pdfsearch.sh`): Command-line interface and PDF text extraction
- **Mojo Core** (`search_engine.mojo`): TF-IDF search algorithm implementation

## Requirements

- Mojo compiler
- `pdftotext` (from poppler-utils)

## Installation
```bash
# Install poppler-utils for PDF extraction
sudo apt-get install poppler-utils
```

## Usage
```bash
./pdfsearch.sh document.pdf "search query" 3
```

Example:
```bash
./pdfsearch.sh paper.pdf "gradient descent optimization" 5
```

## How It Works

1. Extracts text from PDF using `pdftotext`
2. Splits text into passages (paragraphs)
3. Ranks passages using TF-IDF algorithm:
   - **Term Frequency**: Sublinear scaling (1 + log(tf)) for diminishing returns
   - **Inverse Document Frequency**: Rare terms score higher
   - **Length Normalization**: Prevents bias toward longer passages

## Features

- ✅ Pure Mojo search algorithm
- ✅ TF-IDF relevance ranking
- ✅ Page number tracking
- ✅ Configurable result count
