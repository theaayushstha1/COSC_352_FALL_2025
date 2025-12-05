# PDF Search Tool
**Option 1** (running with python script which implements core search algorithms) (pdfsearch.py)

**PLEASE VISIT READme.md for Option 2 which runs with mojo programming language**

CLI search engine for PDF documents using;
- word/passage querying 
- ranks query results by relevance using the TF-IDF algorithm.
- No external libraries (All core search algorithms implemented from scratch)

## Installation

```bash
# Install the required dependency
pip install pypdf

# Navigate to file location (clyde_baidoo/project9/pdfsearch.py)

# Make it executable 
chmod +x pdfsearch.py
```

## Usage
**Option 1** (running with python script which implements core search algorithms) (pdfsearch.py)
```bash
# In the terminal, run the code by:
python pdfsearch.py <pdf_filename.pdf> <query> <number_of_results>
```

### Arguments

- `<pdf_file>` - Path to the PDF file to search
- `<query>` - Search string (use quotes for multi-word queries)
- `<num_results>` - Number of top results to return

### Examples

```bash
# Search for a multi-word phrase
python pdfsearch.py document.pdf "target areas of needed improvement" 3

## Output Format

```bash
Extracting text from PDF...
Indexing 40 passages...
Calculating IDF scores...
Ranking passages by relevance...

Results for: "target areas of needed improvement"
======================================================================

[1] Score: 0.87 (page 18)
    "A ACCENTUA TING OUR URBAN MISSION Today, Morgan State University fully embraces its  designation as the State of Maryland’s preeminent  urban research institution. Accordingly, this strategic  plan..."

[2] Score: 0.31 (page 26)
    "Human resource planning is essential to the implementation of this  strategic plan and will profoundly influence the achievement of its  stated objectives. At Morgan State University, our faculty r..."

[3] Score: 0.28 (page 19)
    "STRA TEGIC  GOALS 2021–2030 A As this strategic planning process gradually unfolded, there was broad consensus that  the University’s emerging 2021–2030 strategic goals were notably consistent with..."
```

Each result shows:
- **Rank**: Position in results (1, 2, 3...)
- **Score**: Relevance score (higher is better)
- **Page**: Page number where passage appears
- **Snippet**: Preview of the relevant text (up to 200 characters)

## How It Works

### TF-IDF Ranking Algorithm

The tool uses three key components to rank passages:

#### 1. Term Frequency (TF) - Sublinear Scaling
```
TF = 1 + log(count) if count > 0, else 0
```
- Handles repeated terms with diminishing returns
- The 10th occurrence of a word contributes less than the 2nd

#### 2. Inverse Document Frequency (IDF)
```
IDF = log(total_documents / documents_containing_term)
```
- Rare terms get higher weight
- Common terms across many passages score lower

#### 3. Length Normalization
```
normalized_score = score / sqrt(unique_term_count)
```
- Prevents long passages from dominating simply by having more words
- Divides by square root of unique non-stopword terms

### Passage Definition

- **Current Implementation**: Each PDF page is treated as one passage
- **Alternative Approaches**: 
  - Split by paragraphs (double newlines)
  - Fixed-size sliding windows
  - Sentence-based chunks

### Stopword Handling

Common English words are filtered to improve relevance:
- Articles: "the", "a", "an"
- Conjunctions: "and", "or", "but"
- Prepositions: "in", "on", "at", "to", "for"
- Common verbs: "is", "was", "are", "have", "do"

This prevents common words from dominating search results.

## Algorithm Details

### Search Process

1. **Extract**: Read PDF and split into page-level passages
2. **Tokenize**: Convert all text to lowercase words, removing punctuation
3. **Index**: Pre-calculate IDF scores for all query terms
4. **Score**: Compute TF-IDF similarity for each passage
5. **Rank**: Sort passages by score (highest first)
6. **Display**: Show top N results with snippets


#

### Why TF-IDF?

TF-IDF is a proven information retrieval algorithm that:
- Naturally handles all three ranking requirements
- Is computationally efficient
- Requires no training data or machine learning
- Works well for keyword-based search

### SIMD Opportunities

Single Instruction Multiple Data (SIMD) could accelerate:
- Token counting across multiple terms simultaneously
- Parallel computation of TF scores
- Vectorized distance calculations

However, Python's GIL limits SIMD benefits. A Mojo implementation could leverage SIMD more effectively.
