# PDF Search Tool

A command-line tool that searches PDF documents for relevant passages using TF-IDF scoring.

## Features
- Extracts text from PDF files
- Tokenizes and indexes document passages
- Scores relevance using term frequency
- Returns top N most relevant results with page numbers

## Requirements
- Python 3
- PyPDF2

## Installation
```bash
pip install PyPDF2
```

## Usage
```bash
python3 pdfsearch.py <pdf_file> <query> <top_n>
```

## Examples

### Search Morgan 2030 Strategic Plan
```bash
python3 pdfsearch.py morgan_2030.pdf "strategic goals" 5
python3 pdfsearch.py morgan_2030.pdf "research university" 10
python3 pdfsearch.py morgan_2030.pdf "student success" 5
```

### Search Academic Papers
```bash
python3 pdfsearch.py test_paper.pdf "attention mechanism" 5
python3 pdfsearch.py test_paper.pdf "transformer" 3
```

## How It Works
1. **Text Extraction**: Uses PyPDF2 to extract text from PDF pages
2. **Passage Creation**: Breaks pages into overlapping 300-character passages
3. **Tokenization**: Converts text to lowercase tokens (words)
4. **Scoring**: Counts term occurrences with logarithmic scaling
5. **Ranking**: Sorts passages by relevance score (highest first)

## Output Format
```
[1] Score: 3.45 (page 12)
    "Relevant passage text appears here..."

[2] Score: 2.89 (page 8)
    "Another relevant passage..."
```

## Project Structure
```
project9/
├── pdfsearch.py          # Main search program
├── pdfsearch.mojo        # Mojo version (requires Mojo)
├── morgan_2030.pdf       # Morgan State strategic plan
├── test_paper.pdf        # Test research paper
└── README.md            # This file
```

## Author
Ryan Anyangwe - COSC 352 Project 9
