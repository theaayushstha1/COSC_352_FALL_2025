# Project 1 – HTML Table to CSV

**Name:** Aayush Shrestha  
**Student ID:** 00367844  

This program reads all <table> elements from a web page (or from a saved HTML file) and writes them into CSV files.  

## How to Run

From this folder, run:

    python3 read_html_table.py <URL_or_file>

### Example with saved HTML file:

    python3 read_html_table.py page.html

## Output

The program will create files like:

    table_1.csv
    table_2.csv
    table_3.csv
    table_4.csv
    table_5.csv

Each file is one table from the page.

## To consider:
- Uses only Python standard library.  
- Works with both URLs and local .html files.  
- A URL gave an error, so saved the page and used the HTML file.  

