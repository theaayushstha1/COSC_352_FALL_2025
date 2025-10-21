# Project 3 – COSC 352 Fall 2025  

**Name:** Aayush Shrestha  
**ID:** 00367844  

---

## Overview  
This project automates the process of extracting HTML tables from multiple websites and saving them as CSV files.  
It uses a **bash script** to:  
1. Accept a comma-separated list of URLs.  
2. Download the HTML pages.  
3. Call the **Docker container** (from Project 2) to parse tables using `read_html_table.py`.  
4. Save all CSV outputs in a dedicated folder.  
5. Package results into a single `.zip` file for easy submission.  

---

## Files  
- `process_tables.sh` – Main bash script.  
- `read_html_table.py` – Python script to parse HTML tables into CSV files.  
- `Dockerfile` – Defines the container image for running the Python script.  

---

## Usage  

### 1. Build and Run the Script  
```bash
./process_tables.sh "https://pypl.github.io/PYPL.html,https://www.tiobe.com/tiobe-index/,https://en.wikipedia.org/wiki/Comparison_of_programming_languages"