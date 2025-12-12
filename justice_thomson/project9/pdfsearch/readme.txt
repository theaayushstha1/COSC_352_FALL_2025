# PDF Search Engine - TF-IDF Implementation in Mojo

A high-performance PDF search engine built with Mojo that uses TF-IDF (Term Frequency-Inverse Document Frequency) scoring to find the most relevant passages in PDF documents.

## Features

- 🔍 **Smart Search**: Uses TF-IDF algorithm to rank passages by relevance
- 📄 **PDF Support**: Extracts and searches through PDF documents
- ⚡ **Fast**: Written in Mojo for high performance
- 🐳 **Dockerized**: Easy deployment with Docker
- 📊 **Configurable**: Specify how many top results to return

## Prerequisites

Choose one of the following:

### Option 1: Docker (Recommended)
- Docker installed on your system

### Option 2: Local Installation
- [Pixi](https://pixi.sh/) package manager
- Mojo 0.26.1 or higher

## Quick Start with Docker

### 1. Build the Docker Image

```bash
docker build -t mojo-pdfsearch .
```

### 2. Run a Search

```bash
docker run --rm mojo-pdfsearch
```

This runs the default search: `morgan2030.pdf` with query `"R1 university"` returning top 3 results.

### 3. Custom Search

```bash
docker run --rm -v $(pwd):/app mojo-pdfsearch \
  pixi run mojo pdfsearch.mojo your-file.pdf "your query" 5
```

Replace:
- `your-file.pdf` - Your PDF file name
- `"your query"` - Search terms (in quotes)
- `5` - Number of top results to return

## Using the Makefile

For convenience, use the included Makefile:

```bash
# Build the image
make build

# Run with defaults
make run

# Run with custom parameters
make run PDF=document.pdf QUERY="machine learning" N=5

# Open interactive shell
make shell

# Clean up
make clean
```

## Local Installation (Without Docker)

### 1. Install Dependencies

```bash
# Install pixi if you haven't already
curl -fsSL https://pixi.sh/install.sh | bash

# Install project dependencies
pixi install
```

### 2. Run the Program

```bash
pixi shell
mojo pdfsearch.mojo morgan2030.pdf "R1 university" 3
```

## Usage

```bash
mojo pdfsearch.mojo <pdf_file> <query> <num_results>
```

### Parameters

- `<pdf_file>` - Path to the PDF file to search
- `<query>` - Search query (wrap in quotes if multiple words)
- `<num_results>` - Number of top results to display

### Examples

```bash
# Search for "R1 university" in morgan2030.pdf, show top 3 results
mojo pdfsearch.mojo morgan2030.pdf "R1 university" 3

# Search for "machine learning" in research.pdf, show top 10 results
mojo pdfsearch.mojo research.pdf "machine learning" 10

# Single word search
mojo pdfsearch.mojo document.pdf innovation 5
```

## How It Works

1. **PDF Extraction**: Reads and extracts text from all pages of the PDF
2. **Passage Segmentation**: Splits content into passages (paragraphs > 50 characters)
3. **Text Normalization**: Converts text to lowercase, removes special characters
4. **Query Processing**: Tokenizes and normalizes the search query
5. **TF-IDF Scoring**:
   - **TF (Term Frequency)**: How often a term appears in a passage
   - **IDF (Inverse Document Frequency)**: How unique a term is across all passages
   - **Normalization**: Adjusts for passage length
6. **Ranking**: Sorts passages by relevance score
7. **Display**: Shows top N results with scores and page numbers

## Output Format

```
Extracting PDF: morgan2030.pdf
Total pages: 40
Extracted 245 passages

Query terms: ['r1', 'university']

Top results:

[ 1 ] Score: 0.8523 (page 5)
Morgan State University is recognized as an R1 university by the Carnegie 
Classification of Institutions of Higher Education...

[ 2 ] Score: 0.7341 (page 12)
The university's research programs have expanded significantly since achieving
R1 status...

Search complete!
```

## Project Structure

```
pdfsearch/
├── Dockerfile              # Docker configuration
├── docker-compose.yml      # Docker Compose configuration
├── Makefile               # Build and run shortcuts
├── pixi.toml              # Pixi dependencies
├── pixi.lock              # Locked dependencies
├── pdfsearch.mojo         # Main search program
├── morgan2030.pdf         # Example PDF
└── README.md              # This file
```

## Docker Commands Reference

```bash
# Build image
docker build -t mojo-pdfsearch .

# Run with defaults
docker run --rm mojo-pdfsearch

# Run with your PDF (mount current directory)
docker run --rm -v $(pwd):/app mojo-pdfsearch \
  pixi run mojo pdfsearch.mojo myfile.pdf "query" 10

# Interactive shell
docker run --rm -it -v $(pwd):/app mojo-pdfsearch bash

# Remove image
docker rmi mojo-pdfsearch
```

## Docker Compose Commands

```bash
# Build
docker-compose build

# Run
docker-compose run --rm mojo-pdfsearch \
  pixi run mojo pdfsearch.mojo document.pdf "search terms" 5

# Shell
docker-compose run --rm mojo-pdfsearch bash
```

## Troubleshooting

### "No module named 'PyPDF2'" Error
Make sure you've run `pixi install` or rebuilt the Docker image:
```bash
docker build --no-cache -t mojo-pdfsearch .
```

### PDF File Not Found
Ensure your PDF is in the same directory and mounted correctly:
```bash
docker run --rm -v $(pwd):/app mojo-pdfsearch \
  pixi run mojo pdfsearch.mojo ./myfile.pdf "query" 3
```

### Permission Errors (Linux)
Run with your user ID:
```bash
docker run --rm --user $(id -u):$(id -g) -v $(pwd):/app mojo-pdfsearch \
  pixi run mojo pdfsearch.mojo document.pdf "query" 5
```

### Low Scores or No Results
- Try different search terms
- Use more specific queries
- Check that your PDF contains searchable text (not scanned images)
- Increase the number of results to see lower-scored matches

## Performance Tips

- **Larger PDFs**: The program processes all pages, so very large PDFs may take longer
- **Query Length**: Shorter, more specific queries often work better
- **Result Count**: Request only the number of results you need

## Technical Details

### TF-IDF Formula

```
TF(t, d) = 1 + log(frequency of term t in document d)
IDF(t) = log(total documents / documents containing term t)
Score(d) = Σ(TF(t, d) × IDF(t)) / √(document length)
```

### Dependencies

- **Mojo**: 0.26.1+ (high-performance systems programming language)
- **PyPDF2**: 3.0.1+ (PDF text extraction)
- **Python**: 3.10+ (for PyPDF2 integration)

## License

This project is part of COSC_352_FALL_2025 coursework.

## Author

Justice Thomson (jutho18@morgan.edu)

## Acknowledgments

- Built with [Mojo](https://www.modular.com/mojo) by Modular
- PDF processing via [PyPDF2](https://pypdf2.readthedocs.io/)
- Environment management with [Pixi](https://pixi.sh/)