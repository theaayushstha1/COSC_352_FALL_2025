# PDF Search Tool

This project is a basic command-line tool that searches a PDF and returns the most relevant passages for a search query.

The assignment originally wanted Mojo, but Mojo doesn’t actually run in the setup I’m using. It doesn’t run natively on Windows, and the normal installer doesn’t work inside WSL either. Because of that, the whole thing was done in WSL using Python instead. The tool works the same way the assignment describes, just written in Python.

All the code is in `extract_text.py`.

## How to run

python3 extract_text.py <pdf> "<query>" <n>

Example:

python3 extract_text.py Morgan2030.pdf "strategic goals" 3

## What it does

Reads the PDF  
Splits the text into passages  
Scores each passage  
Prints the top matches  

## Requirements

Python 3  
pymupdf (fitz)

Install:

pip install --break-system-packages pymupdf

## Notes

Mojo doesn’t run on Windows by itself.  
Mojo also doesn’t install cleanly in WSL (no supported packages).  
So the project was completed in Python inside WSL, which handles the PDF search correctly.
