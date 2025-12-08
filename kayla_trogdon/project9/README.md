# Project 9: Mojo-BAsed PDF Search Engine

## Overview
Tf-IDF search engine for Morgan 2030 document

## Installations:

### Option 1: Using Pixi (Recommended)
bash
# Install Pixi
curl -fsSL https://pixi.sh/install.sh | sh
# Install dependencies
pixi install
# Run
./run.sh "research excellence" 5

### Option 2: Using pip (Standard Python)
bash
# Install Python dependencies
pip install -r requirements.txt
# Extract PDF
python src/extract_pdf.py
# Run search
python src/extract_pdf.py search "research excellence" 5


## How to Run
./run.sh "your search query" 5
-- ./run.sh "research excellence" 5
-- ./run.sh "student leadership" 10

## Components 
1. **PDF Extraction**: Extract text from PDF and split into searchable passages
2. **Query Processing**: Clean query text and remove common stopwords
3. **TF-IDF Scoring**: Calculate relevance scores for each passage
   - **TF (Term Frequency)**: How often terms appear (with diminishing returns)
   - **IDF (Inverse Document Frequency)**: Rare terms weighted higher
   - **Length Normalization**: Prevents long passages from dominating
4. **Ranking**: Sort by score and return top N results

### Core Files:
**`run.sh`** - Main entry point  
Command-line interface that orchestrates PDF extraction and search.

**`src/extract_pdf.py`** - PDF extraction + TF-IDF search engine (WORKING)  
- Extracts text from PDF using pypdf
- Splits text into 39 searchable passages
- Implements complete TF-IDF algorithm in Python
- Handles stopword filtering and text cleaning

### Data Files
**`data/Morgan_2030.pdf`** - Source document (40 pages, 8.8MB)  
Morgan State University's 2030 strategic plan document.

**`data/passages.json`** - Extracted passages (39 total)  
Preprocessed text data ready for searching.

### Mojo Implementation Files (Non-Functional)
**`src/utils.mojo`** - Utility functions (WORKING)  
Text processing functions: lowercase, clean_text, stopword filtering, TF-IDF math.  
✅ Compiles and runs successfully - demonstrates Mojo syntax.

**`src/tfidf.mojo`** - Full TF-IDF search engine (NON-FUNCTIONAL)  
Complete implementation with Python interop for JSON loading.  
⚠️ Crashes due to Mojo Python interop bug.

**`src/search.mojo`** - Pure Mojo search (NON-FUNCTIONAL)  
TF-IDF implementation without Python dependencies.  
⚠️ Crashes on String.find() operations in GitHub Codespaces.

**`src/test_load.mojo`** - JSON loading test  
Debugging script to isolate Python interop issues.

### Test Files
**`tests/test_mini_tfidf.mojo`** - Mini TF-IDF example  
Simplified 4-passage demo showing TF-IDF math with hardcoded data.

**`tests/sample_passages.txt`** - Test data  
Sample text for testing the mini TF-IDF implementation.

**`tests/life.mojo`** - Hello World test  
Simple "Hello World" program to verify Mojo installation.

### Configuration Files
**`pixi.toml`** - Dependency management  
Specifies Mojo and Python dependencies (similar to deps.edn from Project 8).

**`pixi.lock`** - Lock file  
Auto-generated dependency versions (similar to package-lock.json).

**`.gitignore`** - Git exclusions  
Ignores build artifacts, cache files, and temporary data.

**`.gitattributes`** - Git configuration  
Specifies how Git handles different file types.

## Dependencies
- **Python 3.x** with pypdf library
- **Mojo 24.5.0** (for demonstration files)
- **Pixi** package manager
```bash
# Install dependencies
pixi add pypdf
pixi add max
```