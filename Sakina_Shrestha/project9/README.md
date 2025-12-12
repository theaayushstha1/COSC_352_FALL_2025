# PDF Search with TF-IDF and SIMD

A command-line PDF search tool that extracts passages from PDFs, computes TF-IDF scores for user queries, and returns the top N most relevant passages. Includes both scalar (Mojo/Python) and SIMD-optimized (NumPy) implementations.

## Features

- Extract and search text passages from PDF documents
- TF-IDF scoring with relevance ranking
- Two implementations: scalar baseline and SIMD-optimized (NumPy vectorization)
- Overlapping passage extraction for better context preservation
- Stopword filtering and text normalization
- Performance benchmarking tools

## Quick Start

### 1. Setup Environment

```bash
python3 v/bin/activate
pip install -r requirements.txt-m venv .venv
source .ven
```

### 2. Extract Passages from PDF

```bash
python3 pdf_extractor.py "AttachmentE. Transformation Morgan 2030.pdf" passages.json
```

This creates `passages.json` with segmented text passages and page numbers.

### 3. Build Scalar Version (Mojo)

```bash
mojo build pdfsearch.mojo -o pdfsearch
chmod +x pdfsearch
```

### 4. Create SIMD Wrapper Script

```bash
cat > pdfsearch_simd << 'EOF'
#!/bin/bash
python3 pdfsearch_simd_cli.py "$@"
EOF
chmod +x pdfsearch_simd
```

## Usage

### Scalar Search
```bash
./pdfsearch "AttachmentE. Transformation Morgan 2030.pdf" "strategic planning" 5
```

### SIMD Search (NumPy-optimized)
```bash
./pdfsearch_simd "AttachmentE. Transformation Morgan 2030.pdf" "strategic planning" 5
```

**Command format:**
```bash
./pdfsearch[_simd] <pdf_file> "<query>" <num_results>
```

## Benchmarking

Compare performance of scalar vs SIMD implementations:

```bash
chmod +x benchmark.sh
./benchmark.sh
```

The benchmark script:
1. Runs `pdf_extractor.py` to ensure `passages.json` is up to date
2. Times multiple runs of both scalar and SIMD versions
3. Uses the query "sustainability" with 5 results on the Morgan 2030 PDF
4. Prints wall-clock times for performance comparison

## Project Structure

```
PROJECT9/
├── AttachmentE. Transformation Morgan 2030.pdf  # Main Morgan 2030 PDF document
├── benchmark.sh                                  # Performance comparison script
├── passages.json                                 # Extracted passages (auto-generated)
├── pdf_extractor.py                             # Extracts passages from PDF
├── pdfsearch                                     # Compiled Mojo executable (scalar)
├── pdfsearch_core.py                            # Scalar TF-IDF implementation (Python)
├── pdfsearch.mojo                               # Mojo CLI wrapper for scalar search
├── pdfsearch_simd                               # Shell wrapper for SIMD version
├── pdfsearch_simd_cli.py                        # Python CLI wrapper (SIMD)
├── pdfsearch_simd_core.py                       # SIMD TF-IDF with NumPy vectorization
├── pdfsearch_simd.mojo                          # Mojo SIMD implementation
├── README.md                                     # This file
└── requirements.txt                              # Python dependencies
```

## Requirements

**Python Dependencies** (`requirements.txt`):
```
PyPDF2
numpy
```

**Additional Requirements**:
- Python 3.8+
- Mojo compiler (for building scalar and SIMD executables)

## How It Works

### TF-IDF Algorithm

1. **Passage Extraction**: PDF is segmented into overlapping text chunks with page numbers preserved
2. **Tokenization**: Text is converted to lowercase and split into individual words
3. **Stopword Filtering**: Common words (the, and, is, at, etc.) are removed
4. **TF-IDF Scoring**: 
   - **Term Frequency (TF)**: Logarithmic scoring of query terms appearing in passages
   - **Inverse Document Frequency (IDF)**: Weights terms by their rarity across all passages
   - **Length Normalization**: Prevents bias toward longer passages
5. **Ranking**: Returns top N passages sorted by relevance score

### Implementation Differences

- **Scalar Version**: Uses standard Python loops for token counting and scoring
- **SIMD Version**: Uses NumPy's vectorized operations for parallel computation of:
  - Token counting across all passages simultaneously
  - TF-IDF matrix computation
  - Batch normalization

## Examples

Search Morgan 2030 document for sustainability:
```bash
./pdfsearch_simd "AttachmentE. Transformation Morgan 2030.pdf" "sustainability" 5
```

Search for strategic planning:
```bash
./pdfsearch "AttachmentE. Transformation Morgan 2030.pdf" "strategic planning" 3
```

## Performance

The SIMD version uses NumPy's vectorized operations for significant performance improvements on larger documents. Typical speedup factors depend on:
- Document size (number of passages)
- Query complexity (number of terms)
- Hardware (CPU vector instruction support)

