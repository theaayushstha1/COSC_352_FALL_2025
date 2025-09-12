# HTML Table to CSV Converter

This project provides a Python program that reads in tables from an HTML page (either from the web or from a saved local file) and converts them into CSV files. The generated CSV files can be opened in any spreadsheet program such as Microsoft Excel, LibreOffice, or Google Sheets.

## Files
- `read_html_table.py` — Python script that parses tables from an HTML page.
- `table_1.csv`, `table_2.csv`, … — CSV files generated from the HTML tables.
- `README.md` — Documentation and usage instructions.

## Requirements
- Python 3 (no external libraries required — only standard Python modules are used).

## Usage
Run the script with a URL or a local HTML file:

### Example with a Wikipedia URL
```bash
python3 read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages

