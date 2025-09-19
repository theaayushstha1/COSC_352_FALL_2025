#!/usr/bin/env python3
"""
URL Table to CSV Extractor
Extracts HTML tables from a URL and prints them as CSV format
Uses only Python built-in libraries
"""

import urllib.request
import urllib.parse
import html.parser
import csv
import sys
import os
from io import StringIO
from urllib.parse import urlparse


class TableExtractor(html.parser.HTMLParser):
    """HTML parser to extract table data"""
    
    def __init__(self):
        super().__init__()
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = []
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.cell_tag = None
    
    def handle_starttag(self, tag, attrs):
        if tag.lower() == 'table':
            self.in_table = True
            self.current_table = []
        elif tag.lower() == 'tr' and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag.lower() in ['td', 'th'] and self.in_row:
            self.in_cell = True
            self.current_cell = []
            self.cell_tag = tag.lower()
    
    def handle_endtag(self, tag):
        if tag.lower() == 'table' and self.in_table:
            if self.current_table:
                self.tables.append(self.current_table)
            self.in_table = False
        elif tag.lower() == 'tr' and self.in_row:
            if self.current_row:
                self.current_table.append(self.current_row)
            self.in_row = False
        elif tag.lower() in ['td', 'th'] and self.in_cell:
            cell_text = ''.join(self.current_cell).strip()
            self.current_row.append(cell_text)
            self.in_cell = False
            self.cell_tag = None
    
    def handle_data(self, data):
        if self.in_cell:
            self.current_cell.append(data)


def fetch_url(url):
    """Fetch content from URL"""
    try:
        # Add user agent to avoid being blocked
        req = urllib.request.Request(url, headers={
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        
        with urllib.request.urlopen(req, timeout=30) as response:
            # Try to decode with different encodings
            content = response.read()
            
            # Try UTF-8 first
            try:
                return content.decode('utf-8')
            except UnicodeDecodeError:
                # Try common alternative encodings
                for encoding in ['latin1', 'iso-8859-1', 'cp1252']:
                    try:
                        return content.decode(encoding)
                    except UnicodeDecodeError:
                        continue
                
                # If all else fails, decode with errors ignored
                return content.decode('utf-8', errors='ignore')
                
    except urllib.error.URLError as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        return None


def clean_cell_data(text):
    """Clean and normalize cell data"""
    if not text:
        return ""
    
    # Replace common HTML entities manually
    replacements = {
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&quot;': '"',
        '&#39;': "'",
        '&nbsp;': ' ',
        '&mdash;': '—',
        '&ndash;': '–',
    }
    
    for entity, replacement in replacements.items():
        text = text.replace(entity, replacement)
    
    # Remove extra whitespace and normalize
    text = ' '.join(text.split())
    
    return text


def generate_filename(url, table_index):
    """Generate a filename based on URL and table index"""
    # Parse the URL to get the domain
    try:
        parsed_url = urlparse(url)
        domain = parsed_url.netloc.replace('www.', '')
        
        # Clean domain name for filename (remove invalid characters)
        safe_domain = ''.join(c for c in domain if c.isalnum() or c in '.-_')
        
        # Create filename
        filename = f"{safe_domain}_table_{table_index}.csv"
        
        # If filename is too generic or empty, use a default
        if not safe_domain or safe_domain in ['.', '-', '_']:
            filename = f"table_{table_index}.csv"
            
        return filename
        
    except Exception:
        return f"table_{table_index}.csv"


def save_table_to_file(table_data, filename):
    """Save table data to CSV file"""
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile, quoting=csv.QUOTE_MINIMAL)
            
            for row in table_data:
                # Clean each cell
                cleaned_row = [clean_cell_data(cell) for cell in row]
                writer.writerow(cleaned_row)
        
        return True
    except Exception as e:
        print(f"Error saving file {filename}: {e}", file=sys.stderr)
        return False


def table_to_csv(table_data):
    """Convert table data to CSV format for display"""
    if not table_data:
        return ""
    
    output = StringIO()
    writer = csv.writer(output, quoting=csv.QUOTE_MINIMAL)
    
    for row in table_data:
        # Clean each cell
        cleaned_row = [clean_cell_data(cell) for cell in row]
        writer.writerow(cleaned_row)
    
    return output.getvalue()


def extract_tables_from_url(url):
    """Main function to extract tables from URL"""
    print(f"Fetching content from: {url}")
    
    # Fetch HTML content
    html_content = fetch_url(url)
    if html_content is None:
        return
    
    # Parse HTML and extract tables
    parser = TableExtractor()
    try:
        parser.feed(html_content)
    except Exception as e:
        print(f"Error parsing HTML: {e}", file=sys.stderr)
        return
    
    # Check if any tables were found
    if not parser.tables:
        print("No tables found on the webpage.")
        return
    
    print(f"\nFound {len(parser.tables)} table(s):")
    print("=" * 50)
    
    saved_files = []
    
    # Print each table as CSV and save to file
    for i, table in enumerate(parser.tables, 1):
        if not table:  # Skip empty tables
            continue
            
        print(f"\n--- TABLE {i} ---")
        print(f"Rows: {len(table)}, Columns: {len(table[0]) if table else 0}")
        
        # Generate filename and save to file
        filename = generate_filename(url, i)
        if save_table_to_file(table, filename):
            saved_files.append(filename)
            print(f"Saved to: {filename}")
        
        print()
        
        # Also display the CSV content
        csv_output = table_to_csv(table)
        print(csv_output.rstrip())
        
        if i < len(parser.tables):
            print("\n" + "-" * 30)
    
    # Summary of saved files
    if saved_files:
        print(f"\n{'='*50}")
        print("SUMMARY - Files saved:")
        for filename in saved_files:
            file_path = os.path.abspath(filename)
            print(f"  • {filename} ({file_path})")
        print(f"Total: {len(saved_files)} CSV file(s) created")
    else:
        print("\nNo files were saved due to errors.")


def main():
    """Main entry point"""
    if len(sys.argv) == 2:
        # URL provided as command line argument
        url = sys.argv[1]
    else:
        # Prompt for URL
        try:
            url = input("Enter URL to extract tables from: ").strip()
            if not url:
                print("No URL provided. Exiting.")
                sys.exit(1)
        except KeyboardInterrupt:
            print("\nOperation cancelled.")
            sys.exit(0)
    
    # Basic URL validation
    if not url.startswith(('http://', 'https://')):
        print("Error: URL must start with http:// or https://")
        sys.exit(1)
    
    try:
        extract_tables_from_url(url)
    except KeyboardInterrupt:
        print("\nOperation cancelled by user.")
        sys.exit(0)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()