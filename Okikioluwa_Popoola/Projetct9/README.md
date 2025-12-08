# Project 9 – PDF Search Engine

## Overview

This project implements a simple **command‑line PDF search engine** for the Morgan 2030 document (or any other PDF).
Given:

- a PDF file path  
- a text query (one or more keywords)  
- a number **N**  

the program returns the **top N most relevant passages** from the PDF, along with:

- a relevance **score**  
- the **page number**  
- a short **text snippet** from that passage  

Example:

```bash
mojo pdfsearch.mojo Morgan2030.pdf "gradient descent optimization" 3
```

Sample output format:

```text
Results for: "gradient descent optimization"

[1] Score: 8.42 (page 12)
    "Gradient descent iteratively updates parameters by moving in the
    direction of steepest descent. The learning rate controls step size
    and significantly impacts optimization convergence..."

[2] Score: 7.18 (page 34)
    "Stochastic gradient descent (SGD) approximates the true gradient
    using mini-batches, trading accuracy for computational efficiency
    in large-scale optimization problems..."

[3] Score: 6.91 (page 8)
    "For convex functions, gradient descent guarantees convergence to
    the global minimum. The descent lemma provides theoretical bounds
    on convergence rate..."
```

---

## How It Works

1. **PDF Extraction (Python / PyPDF2)**  
   - The program uses Python interop and the `PyPDF2` library to open the PDF and extract text page by page.
   - Each page is split into passages using blank lines (double newlines) as paragraph separators.
   - Very short paragraphs (length ≤ 50 characters) are ignored.

2. **Passage Definition**  
   A **passage** is defined as a paragraph‑sized block of text on a given page:

   - Page text is split on `\n\n` (blank lines).
   - Each non‑empty paragraph becomes one passage.
   - Each passage tracks:
     - `text` – the paragraph text
     - `page` – 1‑based page number
     - `score` – relevance score (computed later)

3. **Query Tokenization**  
   - The query string is converted to lowercase.
   - A regular expression `\b\w{3,}\b` is applied to keep only “word” tokens of length ≥ 3.
   - These tokens become the **query terms**.

4. **Relevance Scoring (TF–IDF‑style)**  

   For each passage:

   - Convert passage to lowercase.
   - Extract tokens with the same regex as the query.
   - For each query term:

     - **Term Frequency (TF)** with diminishing returns:  
       \[
       TF(t, p) =
       \begin{cases}
       0, & \text{if count(t, p) = 0} \\
       1 + \log(\text{count}(t, p)), & \text{otherwise}
       \end{cases}
       \]

     - **Document Frequency (DF)** is the number of passages that contain that term at least once.

     - **Inverse Document Frequency (IDF)**:  
       \[
       IDF(t) = \log \left( \frac{\text{total\_passages}}{\text{df}(t)} \right)
       \]
       (computed only if `df(t) > 0`).

     - **Raw score contribution**:  
       \[
       \text{score} \,{+}{=} TF(t, p) \times IDF(t)
       \]

   - **Length Normalization:**  
     Let `L` be the number of tokens in the passage. To prevent long passages from dominating just because they have more words, the final score is normalized:

     \[
     \text{score}(p) = \frac{\text{raw\_score}(p)}{\sqrt{L}}
     \]

5. **Sorting & Output**  

   - All passages are sorted in **descending order** of score.
   - The top `N` passages are printed with:
     - Rank `[i]`
     - Score (trimmed to ~6 characters)
     - Page number  
     - First ~250 characters of the passage as a snippet.

---

## Requirements

- **Mojo** (version used in class)
- **Python 3**
- Python packages:
  - `PyPDF2`

To install `PyPDF2`:

```bash
pip install PyPDF2
```

---

## Running the Program

From the directory containing `pdfsearch.mojo`:

```bash
mojo pdfsearch.mojo <pdf_file> "<query string>" <top_n>
```

Examples:

```bash
mojo pdfsearch.mojo Morgan2030.pdf "equity and student success" 5
mojo pdfsearch.mojo Morgan2030.pdf "climate resilience" 3
```

---

## Design Notes / Discussion

### What is a “passage”?

In this implementation, a passage is a **paragraph**:

- We split on blank lines in the extracted text.
- This gives us coherent chunks of text that are big enough to have context, but not so long that everything on a page merges together.

### Handling common words

- Very short tokens (length < 3) are dropped automatically by the regex.
- This avoids scoring on tiny noise words like “a”, “an”, “to”, etc.
- For an even better system, we could add a full stopword list, but for this project the length filter plus IDF already reduce their impact.

### Performance & Bottlenecks

Main bottlenecks:

1. **PDF text extraction** (PyPDF2) – I/O heavy and outside Mojo’s control.
2. **Text tokenization** and repeated scanning of passages to:
   - check if they contain a query term (for DF)
   - count term frequencies (for TF)

Right now the implementation uses straightforward scalar loops and Python’s `re` for simplicity and clarity.

### SIMD (Future Work)

The assignment mentions SIMD; a natural next step would be to:

- Move tokenization from Python’s regex into native Mojo code.
- Use a SIMD type (e.g., operating on 16 bytes at a time) to:
  - Vectorize lowercase conversion (A–Z → a–z).
  - Vectorize “is this a word character?” checks.
- Keep the same TF–IDF scoring logic, but speed up the preprocessing.

This project focuses on **correctness and ranking quality** first, with a clear path to SIMD optimization in the tokenization stage.

---

## Files in This Project

- `pdfsearch.mojo` – main Mojo program (CLI + search logic)
- `Morgan2030.pdf` – the PDF used for testing (renamed from the provided case study)
- `life/pixi.toml`, `life/pixi.lock` – environment placeholders used by the course tooling
- `README.md` – this documentation

