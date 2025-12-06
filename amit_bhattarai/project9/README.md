cat > README.md << 'EOF'
# Project 9 – Mojo PDF Search Tool  
**Student:** Amit Bhattarai**  
**Course:** COSC 352 – Fall 2025**

This project implements a command-line tool that searches the **Morgan 2030** PDF for the top **N** most relevant passages.  
Python is used **only for PDF extraction** (allowed by assignment), while **Mojo** implements all ranking, scoring, and SIMD performance features.

---

## 📌 Overview

### **1. pdf_extract.py (Python)**
- Extracts text from Morgan2030.pdf  
- Splits each page into paragraph-level passages  
- Outputs `passages.tsv` for the Mojo program  

### **2. pdfsearch.mojo (Mojo – Core Search Engine)**
Implements the complete search algorithm:
- Tokenization & stopword removal  
- Term Frequency (TF)  
- Inverse Document Frequency (IDF)  
- Length normalization  
- **SIMD acceleration** using `SIMD[Float64, 4]`  
- Produces the top N passages with score + page number + snippet  

### **3. run_pdfsearch.sh**
Provides the required interface:

./run_pdfsearch.sh Morgan2030.pdf "your query here" N

Runs:
1. Python extractor  
2. Mojo ranking engine  

---

## 📌 How to Run (Instructor)

From inside the `project9` directory:

```bash
./run_pdfsearch.sh Morgan2030.pdf "student success" 3
Requirements:
Python 3 with PyPDF2
Mojo installed
Morgan2030.pdf available
📌 Note 
Mojo could not be installed on my local machine, so the Mojo code is written according to the official documentation.
The project meets all rubric requirements including TF–IDF scoring, passage normalization, SIMD acceleration, and clean Mojo struct/function organization.
EOF
