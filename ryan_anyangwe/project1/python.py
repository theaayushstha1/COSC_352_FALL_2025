#!/usr/bin/env python3
"""
read_html_table.py - Extract tables from HTML pages and convert to CSV

This program reads HTML tables from a given URL or local file and converts
them to CSV format that can be loaded into a spreadsheet.

Usage:
    python read_html_table.py <URL|FILENAME> [output_filename]

Examples:
    python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages
    python read_html_table.py comparison_page.html programming_languages.csv
"""

import sys
import csv
import urllib.request
import urllib.error
from html.parser import HTMLParser
from urllib.parse import urlparse

class HTMLTableParser(HTMLParser):
    """HTML parser to extract table data from HTML documents"""
    
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_tag = ""
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = ""
        self.table_count = 0
    
    def handle_starttag(self, tag, attrs):
        self.current_tag = tag
        
        if tag == "table":
            self.in_table = True
            self.current_table = []
            self.table_count += 1
        
        elif self.in_table and tag == "tr":
            self.in_row = True
            self.current_row = []
        
        elif self.in_table and tag in ["td", "th"]:
            self.in_cell = True
            self.current_cell = ""
    
    def handle_endtag(self, tag):
        if tag == "table" and self.in_table:
            self.in_table = False
            if self.current_table:
                self.tables.append(self.current_table)
        
        elif self.in_table and tag == "tr":
            self.in_row = False
            if self.current_row:
                self.current_table.append(self.current_row)
        
        elif self.in_table and tag in ["td", "th"]:
            self.in_cell = False
            # Clean up cell content and add to current row
            cell_content = self.current_cell.strip().replace('\n', ' ').replace('\r', ' ')
            self.current_row.append(cell_content)
    
    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

def fetch_html_content(source):
    """Fetch HTML content from URL or read from local file"""
    try:
        # Check if it's a URL
        if urlparse(source).scheme in ('http', 'https'):
            print(f"Fetching HTML from URL: {source}")
            with urllib.request.urlopen(source) as response:
                return response.read().decode('utf-8')
        else:
            # Assume it's a local file
            print(f"Reading HTML from file: {source}")
            with open(source, 'r', encoding='utf-8') as file:
                return file.read()
    except urllib.error.URLError as e:
        print(f"Error accessing URL: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print(f"File not found: {source}")
        sys.exit(1)
    except Exception as e:
        print(f"Error reading source: {e}")
        sys.exit(1)

def write_table_to_csv(table_data, filename):
    """Write table data to CSV file"""
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            for row in table_data:
                writer.writerow(row)
        print(f"Successfully wrote table to {filename}")
    except Exception as e:
        print(f"Error writing to CSV file: {e}")
        sys.exit(1)

def main():
    # Check command line arguments
    if len(sys.argv) < 2:
        print("Usage: python read_html_table.py <URL|FILENAME> [output_filename]")
        print("Example: python read_html_table.py https://en.wikipedia.org/wiki/Comparison_of_programming_languages")
        sys.exit(1)
    
    source = sys.argv[1]
    output_filename = sys.argv[2] if len(sys.argv) > 2 else "output.csv"
    
    # Fetch HTML content
    html_content = fetch_html_content(source)
    
    # Parse HTML to extract tables
    parser = HTMLTableParser()
    parser.feed(html_content)
    
    # Display available tables
    print(f"Found {len(parser.tables)} table(s) in the document")
    
    if not parser.tables:
        print("No tables found in the HTML document")
        sys.exit(1)
    
    # Let user choose which table to export (default to first table)
    table_index = 0
    if len(parser.tables) > 1:
        print("\nMultiple tables found. Please select which table to export:")
        for i, table in enumerate(parser.tables):
            print(f"{i + 1}: Table with {len(table)} rows and {len(table[0]) if table else 0} columns")
        
        try:
            choice = input(f"Enter table number (1-{len(parser.tables)}, default 1): ").strip()
            table_index = int(choice) - 1 if choice else 0
            if table_index < 0 or table_index >= len(parser.tables):
                print("Invalid choice, using first table")
                table_index = 0
        except ValueError:
            print("Invalid input, using first table")
            table_index = 0
    
    # Get selected table
    selected_table = parser.tables[table_index]
    
    # Display table info
    print(f"\nSelected table: {len(selected_table)} rows, {len(selected_table[0]) if selected_table else 0} columns")
    
    # Preview first few rows
    print("\nPreview of table data:")
    for i, row in enumerate(selected_table[:3]):
        preview = " | ".join(str(cell)[:30] + "..." if len(str(cell)) > 30 else str(cell) for cell in row[:5])
        print(f"Row {i + 1}: {preview}")
        if i == 2 and len(selected_table) > 3:
            print("... (more rows available)")
            break
    
    # Write to CSV
    write_table_to_csv(selected_table, output_filename)
    
    print(f"\nCSV file '{output_filename}' has been created successfully!")
    print("You can now open this file in any spreadsheet application.")

if __name__ == "__main__":
    main()
