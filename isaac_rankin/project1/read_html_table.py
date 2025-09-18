import sys
import csv
import urllib.request
import re

def fetch_html(source):
    req = urllib.request.Request(source)
    req.add_header('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
    with urllib.request.urlopen(req) as response:
        return response.read().decode('utf-8', errors='ignore')
        


def tokenize_html(html):
    tokens = []
    i = 0

    # each character
    while i < len(html):
        if html[i] == '<':  # if the character is the start of a tag, find the end and append that to the tokens list
            end = html.find('>', i)
            if end != -1:
                tag = html[i:end+1].lower()
                tokens.append(('TAG', tag))
                i = end + 1
            else:
                i += 1
        else:               # Look for the next tag start and save everything before it as TEXT
            start = html.find('<', i)
            if start == -1:
                text = html[i:]
                i = len(html)
            else:
                text = html[i:start]
                i = start
            
            text = re.sub(r'\s+', ' ', text).strip()
            if text:
                tokens.append(('TEXT', text))
    
    return tokens


def extract_tables(tokens):
    tables = []

    current_table = None
    current_row = None
    current_cell = ''

    in_table = False
    in_row = False
    in_cell = False
    
    for token_type, token_value in tokens:
        if token_type == 'TAG':     
            tag_lower = token_value.lower()

            # if the tag is the start of a table, create a new group, else add it to the list of all tables
            if tag_lower == '<table>' or tag_lower.startswith('<table '):
                in_table = True
                current_table = []
            elif tag_lower == '</table>' and in_table:
                if current_table:
                    tables.append(current_table)
                in_table = False
                current_table = None

            # if the tag is a row add the row data to the current table
            elif tag_lower == '<tr>' or tag_lower.startswith('<tr '):
                if in_table:
                    in_row = True
                    current_row = []
            elif tag_lower == '</tr>' and in_row:
                if current_row:
                    current_table.append(current_row)
                in_row = False
                current_row = None

            # if the tag is data, add a data cell to the row
            elif (tag_lower.startswith('<td') or tag_lower.startswith('<th')) and in_row:
                in_cell = True
                current_cell = ''
            elif (tag_lower == '</td>' or tag_lower == '</th>') and in_cell:
                current_row.append(current_cell.strip())
                in_cell = False
                current_cell = ''

            # Add text into the data cell
        elif token_type == 'TEXT' and in_cell:
            current_cell += token_value + ' '
    
    return tables


def save_tables_csv(tables):

    if not tables:
        print("No tables found")
        return
    
    file_name = 'table_data.csv'

    f = open(file_name, "w+")
    f.close()
    
    for i, table in enumerate(tables):
        if not table:
            continue
            
        with open(file_name, 'a', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for row in table:
                clean_row = [cell.strip() for cell in row]
                writer.writerow(clean_row)
            writer.writerow('\n')
        
        print(f"Saved {len(table)} rows to {file_name}")


def main():
    if len(sys.argv) != 2:
        print("Usage: python read_html_table.py <URL|FILENAME>")
        sys.exit(1)
    
    source = sys.argv[1]
    
    try:
        # Fetch HTML
        html = fetch_html(source)
        print(f"Fetched HTML ({len(html)} chars)")
        
        # Tokenize
        tokens = tokenize_html(html)
        print(f"Tokenized into {len(tokens)} tokens")
        
        # Extract tables
        tables = extract_tables(tokens)
        print(f"Found {len(tables)} tables")
        
        # Save to CSV
        save_tables_csv(tables)
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()