# HTML Table to CSV Converter

- This program extracts tables from any HTML page (local file or online URL) and saves them as CSV files. Each table in the HTML becomes a separate CSV file that can be opened in spreadsheet software like Excel or Google Sheets.

## How It Works

1. Reads HTML content from a URL or local file.
2. Uses a custom HTML parser to identify `<table>` elements.
3. Extracts rows and cells into Python lists.
4. Saves each table into a CSV file named `table_1.csv`, `table_2.csv`, etc.

## Requirements
- I used only the standard libraries and no external libraries were used.

## Usage
- I used my computer's terminal to run the code.
- we can run the script by adding url of the website containing tables.
- Any URL should work in the place of wikipedia URL
  
### Example with a Wikipedia URL
```bash
python3 read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages

