# HTML Table to CSV Converter

This project reads HTML tables from a webpage or local HTML file and writes them to CSV files. It uses **pure Python** — no external libraries required.

## 🧠 Features

- Parses any HTML file with `<table>` elements
- Extracts rows and cells from each table
- Outputs each table to a separate CSV file
- Works offline with downloaded HTML files

## 📁 Files

- `html_table_to_csv.py`: Main Python script
- `comparison.html`: Sample HTML file (from Wikipedia)
- `Dockerfile`: Container configuration (see below)

## 🖥️ How to Run Locally

1. Open terminal in the project folder
2. Run the script:
   ```bash
   python html_table_to_csv.py comparison.html
