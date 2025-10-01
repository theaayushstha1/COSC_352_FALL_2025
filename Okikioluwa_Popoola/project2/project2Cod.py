import sys
import urllib.request
import urllib.parse
import re
import html
import os

def fetch_html(url):
    """Fetch HTML content from URL."""
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
        
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8')
    except Exception as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        sys.exit(1)

def clean_text(text):
    """Clean and normalize text content."""
    if not text:
        return ""
    text = html.unescape(text)
    text = re.sub(r'\s+', ' ', text.strip())
    return text

def escape_csv_field(field):
    """Escape CSV field if it contains special characters."""
    field = str(field)
    if ',' in field or '"' in field or '\n' in field:
        field = field.replace('"', '""')
        field = f'"{field}"'
    return field 

def extract_tables(html_content):
    """Extract all tables from HTML content using regex parsing."""
    tables = []
    table_pattern = r'<table[^>]*?>(.*?)</table>'
    table_matches = re.findall(table_pattern, html_content, re.DOTALL | re.IGNORECASE)
    
    for table_html in table_matches:
        rows = []
        tr_pattern = r'<tr[^>]*?>(.*?)</tr>'
        tr_matches = re.findall(tr_pattern, table_html, re.DOTALL | re.IGNORECASE)
        
        for tr_html in tr_matches:
            cells = []
            cell_pattern = r'<(?:td|th)[^>]*?>(.*?)</(?:td|th)>'
            cell_matches = re.findall(cell_pattern, tr_html, re.DOTALL | re.IGNORECASE)
            
            for cell_html in cell_matches:
                # Remove any remaining HTML tags from cell content
                cell_text = re.sub(r'<[^>]+>', '', cell_html)
                cell_text = clean_text(cell_text)
                cells.append(cell_text)
            
            if cells:
                rows.append(cells)
        
        if rows:
            tables.append(rows)
    
    return tables

def save_table_as_csv(table, table_num):
    """Save a single table to CSV file."""
    filename = f"table_{table_num}.csv"
    
    try:
        with open(filename, 'w', encoding='utf-8') as f:
            for row in table:
                csv_row = ','.join(escape_csv_field(cell) for cell in row)
                f.write(csv_row + '\n')
        print(f"Saved table {table_num} to {filename}")
        print(f"File saved at: {os.path.abspath(filename)}")  # Show full path
    except Exception as e:
        print(f"Error saving table {table_num}: {e}", file=sys.stderr)

def main():
    """Main function to execute the program."""
    if len(sys.argv) != 2:
        # If no URL provided, use a default
        url = "https://en.wikipedia.org/wiki/Comparison_of_programming_languages"
        print(f"No URL provided. Using default: {url}")
    else:
        url = sys.argv[1]
    
    # Auto-add http:// if no scheme provided
    parsed_url = urllib.parse.urlparse(url)
    if not parsed_url.scheme:
        url = 'http://' + url
    
    print(f"Fetching tables from: {url}")
    html_content = fetch_html(url)
    tables = extract_tables(html_content)
    
    if not tables:
        print("No tables found in the HTML content", file=sys.stderr)
        sys.exit(1)
    
    print(f"Found {len(tables)} table(s)")
    
    for i, table in enumerate(tables, 1):
        save_table_as_csv(table, i)
    
    print("Conversion completed successfully")
    print(f"Files saved in: {os.getcwd()}")  # Show current working directory

if __name__ == "__main__":
    main()