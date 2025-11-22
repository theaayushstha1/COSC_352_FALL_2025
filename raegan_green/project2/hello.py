#!/usr/bin/env python3
import sys
import urllib.request
import urllib.parse
import re
import html

def fetch_html(url):
    try:
        req = urllib.request.Request(url)
        req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
        
        with urllib.request.urlopen(req) as response:
            return response.read().decode('utf-8')
    except Exception as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        sys.exit(1)

def clean_text(text):
    if not text:
        return ""
    text = html.unescape(text)
    text = re.sub(r'\s+', ' ', text.strip())
    return text

def escape_csv_field(field):
    field = str(field)
    if ',' in field or '"' in field or '\n' in field:
        field = field.replace('"', '""')
        field = f'"{field}"'
    return field

def extract_tables(html_content):
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
                cell_text = re.sub(r'<[^>]+>', '', cell_html)
                cell_text = clean_text(cell_text)
                cells.append(cell_text)
            
            if cells:
                rows.append(cells)
        
        if rows:
            tables.append(rows)
    
    return tables

def save_table_as_csv(table, table_num):
    filename = f"table_{table_num}.csv"
    
    with open(filename, 'w') as f:
        for row in table:
            csv_row = ','.join(escape_csv_field(cell) for cell in row)
            f.write(csv_row + '\n')

def main():
    if len(sys.argv) != 2:
        print("Usage: python hello.py <url>", file=sys.stderr)
        sys.exit(1)
    
    url = sys.argv[1]
    parsed_url = urllib.parse.urlparse(url)
    if not parsed_url.scheme:
        url = 'http://' + url
    
    print(f"Fetching tables from: {url}")
    html_content = fetch_html(url)
    tables = extract_tables(html_content)
    
    for i, table in enumerate(tables, 1):
        save_table_as_csv(table, i)

if __name__ == "__main__":
    main()