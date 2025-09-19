#!/usr/bin/env python3
"""
Extract HTML tables from a URL and save them as CSV files.
Usage: python extract_tables.py <URL>
Uses only Python standard library (no BeautifulSoup dependency).
"""

import sys
import csv
import re
from urllib.parse import urlparse
from urllib.request import urlopen, Request
from html.parser import HTMLParser
import html

class TableExtractor(HTMLParser):
    """
    HTML parser to extract table data from HTML content.
    """
    
    def __init__(self):
        super().__init__()
        self.tables = []
        self.current_table = None
        self.current_row = None
        self.current_cell = None
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.cell_text = []
        
        # Track nested tables (ignore inner tables)
        self.table_depth = 0
        
    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.table_depth += 1
            if self.table_depth == 1:  # Only process outermost tables
                self.in_table = True
                self.current_table = []
                
        elif tag == 'tr' and self.in_table and self.table_depth == 1:
            self.in_row = True
            self.current_row = []
            
        elif tag in ['td', 'th'] and self.in_row and self.table_depth == 1:
            self.in_cell = True
            self.cell_text = []
            
            # Handle colspan and rowspan attributes
            colspan = 1
            rowspan = 1
            for attr_name, attr_value in attrs:
                if attr_name == 'colspan':
                    try:
                        colspan = int(attr_value)
                    except (ValueError, TypeError):
                        colspan = 1
                elif attr_name == 'rowspan':
                    try:
                        rowspan = int(attr_value)
                    except (ValueError, TypeError):
                        rowspan = 1
            
            self.current_cell = {
                'text': '',
                'colspan': colspan,
                'rowspan': rowspan
            }
    
    def handle_endtag(self, tag):
        if tag == 'table':
            if self.table_depth == 1 and self.in_table:
                # End of outermost table
                if self.current_table:
                    processed_table = self._process_table_spans(self.current_table)
                    if processed_table:
                        self.tables.append(processed_table)
                self.in_table = False
                self.current_table = None
            self.table_depth -= 1
            
        elif tag == 'tr' and self.in_row and self.table_depth == 1:
            if self.current_row is not None:
                self.current_table.append(self.current_row)
            self.in_row = False
            self.current_row = None
            
        elif tag in ['td', 'th'] and self.in_cell and self.table_depth == 1:
            if self.current_cell is not None:
                # Clean up the cell text
                text = ' '.join(self.cell_text).strip()
                text = re.sub(r'\s+', ' ', text)  # Replace multiple whitespace with single space
                text = html.unescape(text)  # Decode HTML entities
                self.current_cell['text'] = text
                self.current_row.append(self.current_cell)
            self.in_cell = False
            self.current_cell = None
            self.cell_text = []
    
    def handle_data(self, data):
        if self.in_cell and self.table_depth == 1:
            # Only add text data if we're in a cell of the outermost table
            self.cell_text.append(data.strip())
    
    def _process_table_spans(self, raw_table):
        """
        Process colspan and rowspan attributes to create a proper 2D grid.
        """
        if not raw_table:
            return []
        
        # First pass: determine maximum columns needed
        max_cols = 0
        for row in raw_table:
            col_count = sum(cell['colspan'] for cell in row)
            max_cols = max(max_cols, col_count)
        
        if max_cols == 0:
            return []
        
        # Create the final table grid
        result = []
        row_spans = {}  # Track cells that span multiple rows
        
        for row_idx, row in enumerate(raw_table):
            result_row = [''] * max_cols
            col_idx = 0
            
            # First, place any rowspan cells from previous rows
            for span_col, (text, remaining_rows) in list(row_spans.items()):
                if span_col < max_cols:
                    result_row[span_col] = text
                if remaining_rows <= 1:
                    del row_spans[span_col]
                else:
                    row_spans[span_col] = (text, remaining_rows - 1)
            
            # Then place current row cells
            for cell in row:
                # Find next available column
                while col_idx < max_cols and result_row[col_idx] != '':
                    col_idx += 1
                
                if col_idx >= max_cols:
                    break
                
                # Place cell text
                text = cell['text']
                colspan = min(cell['colspan'], max_cols - col_idx)
                rowspan = cell['rowspan']
                
                # Fill columns for colspan
                for c in range(colspan):
                    if col_idx + c < max_cols:
                        result_row[col_idx + c] = text
                
                # Set up rowspan for future rows
                if rowspan > 1:
                    for c in range(colspan):
                        if col_idx + c < max_cols:
                            row_spans[col_idx + c] = (text, rowspan - 1)
                
                col_idx += colspan
            
            result.append(result_row)
        
        return result

def extract_tables_from_url(url):
    """
    Extract all tables from a given URL and return them as a list of 2D lists.
    """
    try:
        # Create request with headers to avoid blocking
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        
        # Actually make the HTTP request
        request = Request(url, headers=headers)
        with urlopen(request) as response:
            content = response.read()
            
            # Try to get encoding from Content-Type header
            content_type = response.headers.get('Content-Type', '')
            encoding = 'utf-8'  # default
            if 'charset=' in content_type:
                encoding = content_type.split('charset=')[1].split(';')[0].strip()
        
        # Decode the content
        try:
            html_content = content.decode(encoding)
        except UnicodeDecodeError:
            # Fallback to utf-8 with error handling
            html_content = content.decode('utf-8', errors='replace')
        
        # Parse HTML and extract tables
        parser = TableExtractor()
        parser.feed(html_content)
        
        if not parser.tables:
            print("No tables found on the page.", file=sys.stderr)
            return []
        
        print(f"Found {len(parser.tables)} table(s)", file=sys.stderr)
        return parser.tables
        
    except Exception as e:
        print(f"Error fetching or parsing URL: {e}", file=sys.stderr)
        return []

def save_table_to_csv(table_data, filename):
    """
    Save a 2D list to CSV file.
    """
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
            for row in table_data:
                writer.writerow(row)
        return True
    except Exception as e:
        print(f"Error saving {filename}: {e}", file=sys.stderr)
        return False

def generate_base_filename(url):
    """
    Generate a base filename from URL, removing unsafe characters.
    """
    parsed = urlparse(url)
    # Use domain and path to create a meaningful filename
    base = parsed.netloc + parsed.path
    # Replace unsafe characters
    safe_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_."
    filename = ''.join(c if c in safe_chars else '_' for c in base)
    # Remove multiple underscores and leading/trailing underscores
    filename = '_'.join(filter(None, filename.split('_')))
    # Limit length
    if len(filename) > 50:
        filename = filename[:50]
    # Fallback if filename is empty or too short
    if len(filename) < 3:
        filename = "tables"
    return filename

def main():
    # Check command line arguments
    if len(sys.argv) != 2:
        print("Usage: python extract_tables.py <URL>", file=sys.stderr)
        print("Example: python extract_tables.py https://example.com/page-with-tables", file=sys.stderr)
        sys.exit(1)
    
    url = sys.argv[1]
    
    # Validate URL format
    if not url.startswith(('http://', 'https://')):
        print("Error: URL must start with http:// or https://", file=sys.stderr)
        sys.exit(1)
    
    print(f"Extracting tables from: {url}", file=sys.stderr)
    
    # Extract tables
    tables = extract_tables_from_url(url)
    
    if not tables:
        print("No tables were successfully extracted.", file=sys.stderr)
        sys.exit(1)
    
    # Generate base filename from URL
    base_filename = generate_base_filename(url)
    
    # Save each table as a CSV file
    saved_files = []
    for i, table in enumerate(tables):
        if len(tables) == 1:
            filename = f"{base_filename}.csv"
        else:
            filename = f"{base_filename}_{i+1}.csv"
        
        if save_table_to_csv(table, filename):
            saved_files.append(filename)
            print(f"Saved table {i+1} to: {filename}", file=sys.stderr)
        else:
            print(f"Failed to save table {i+1}", file=sys.stderr)
    
    if saved_files:
        print(f"\nSuccessfully extracted {len(saved_files)} table(s) to CSV files:", file=sys.stderr)
        for filename in saved_files:
            print(f"  - {filename}", file=sys.stderr)
    else:
        print("No tables were successfully saved.", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()