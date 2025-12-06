# Project 9 – Mojo PDF Search Tool  
**Student:** Amit Bhattarai  
**Course:** COSC 352 – Fall 2025  

This project implements a command-line tool that searches the **Morgan 2030** PDF for the top **N most relevant passages** to a user query.  

---

## 📌 Overview  
The system consists of:

### 1. `pdf_extract.py` (Python)  
- Extracts text from the PDF (allowed by assignment).  
- Splits each page into readable passages.  
- Saves all passages to `passages.tsv`.

### 2. `pdfsearch.mojo` (Mojo – core of the project)  
Implements the full search algorithm:  
- Tokenization & stopword removal  
- Term Frequency + IDF scoring  
- Length normalization  
- SIMD-accelerated scoring (using Mojo’s `SIMD[Float64, 4]`)  
- Ranks passages and prints the top N

### 3. `run_pdfsearch.sh`  
A wrapper script enabling the exact required interface:  
./run_pdfsearch.sh morgan2030.pdf "your query" 3

---

## 📌 How to Run  
From inside `project9`:

```bash
./run_pdfsearch.sh ../../morgan2030.pdf "student success" 3
Requires:
PyPDF2 installed (Python)
Mojo installed 
The Morgan 2030 PDF available EOF
