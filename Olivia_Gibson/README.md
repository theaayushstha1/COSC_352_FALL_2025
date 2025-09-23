# HTML Table to CSV Converter

This Python script reads HTML tables from a local HTML file and writes each table to a separate CSV file. It uses only built-in Python modules — no external dependencies required.

## Author
Olivia Gibson  
Project 1 — CMPE 352

## Features
- Parses multiple `<table>` elements from a single HTML file
- Converts each table into a CSV file: `table_1.csv`, `table_2.csv`, etc.
- Handles both `<td>` and `<th>` cells
- Strips HTML tags to extract clean text

## Usage

```bash
python html_table_to_csv.py comparison.html
