"""
HTML Table to CSV Converter 

Setup and Running Instructions:
1. Download the HTML file:
   - Using curl: `curl -L https://en.wikipedia.org/wiki/Comparison_of_programming_languages -o input.html`
   - Or save from a browser: Open the URL, right-click, "Save As" -> "input.html" (HTML Only).
   - Place input.html in the same directory as this script (e.g., project1).
2. Run the script:
   - `python3 chinonso_egeolu_project1.py input.html`
3. Find the output:
   - CSV files (table_1.csv, table_2.csv, etc.) are saved in the script's directory (e.g., project1).
   - Open in a spreadsheet: `open table_1.csv` (macOS) or use Excel/Google Sheets.
4. Example output:
   - Table 1 (X rows, Y columns) saved to 'table_1.csv'
   - Conversion complete! N tables processed.


"""

import sys

def read_file(file_path):
    """Read the HTML file into a string."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found. Download the HTML page first.")
        sys.exit(1)
    except UnicodeDecodeError:
        print(f"Error: Could not decode '{file_path}' as UTF-8. Try saving with UTF-8 encoding.")
        sys.exit(1)

def extract_tables(html):
    """
    Parse HTML to extract tables using a stack to track tag hierarchy.
    Returns a list of tables, where each table is a list of rows, and each row is a list of cell strings.
    """
    tables = []
    current_table = []
    current_row = []
    stack = []  # Stack to track open tags: (tag_name, content_buffer)
    cell_content = []
    in_cell = False

    i = 0
    while i < len(html):
        if html[i] == '<':
            # Handle tag start
            if i + 1 < len(html) and html[i + 1] == '/':
                # Closing tag
                tag_start = i + 2
                while i < len(html) and html[i] != '>':
                    i += 1
                tag_name = html[tag_start:i].lower().split()[0]  # Get tag name (ignore attributes)
                i += 1  # Move past '>'
                
                # Pop tags from stack until matching tag is found
                while stack and stack[-1][0] != tag_name:
                    if stack[-1][0] in ('th', 'td'):
                        # End of cell: save content
                        if in_cell:
                            current_row.append(''.join(cell_content).strip())
                            cell_content = []
                            in_cell = False
                        stack.pop()
                    else:
                        # Append nested tag content to cell
                        if in_cell:
                            cell_content.append(stack[-1][1])
                        stack.pop()
                
                if stack and stack[-1][0] == tag_name:
                    if tag_name == 'table' and current_table:
                        tables.append(current_table)
                        current_table = []
                    elif tag_name == 'tr' and current_row:
                        current_table.append(current_row)
                        current_row = []
                    elif tag_name in ('th', 'td'):
                        if in_cell:
                            current_row.append(''.join(cell_content).strip())
                            cell_content = []
                            in_cell = False
                    stack.pop()
            else:
                # Opening tag
                tag_start = i + 1
                while i < len(html) and html[i] != '>':
                    i += 1
                tag_full = html[tag_start:i].lower()
                tag_name = tag_full.split()[0]  # Get tag name (ignore attributes)
                i += 1  # Move past '>'
                
                # Push tag onto stack
                stack.append((tag_name, ''))
                
                if tag_name == 'table':
                    current_table = []
                elif tag_name == 'tr':
                    current_row = []
                elif tag_name in ('th', 'td'):
                    in_cell = True
                    cell_content = []
        elif in_cell and stack and stack[-1][0] in ('th', 'td'):
            # Collect text content within a cell
            cell_content.append(html[i])
            i += 1
        else:
            i += 1

    # Handle any remaining table
    if current_table:
        tables.append(current_table)

    return tables

def write_csv(tables):
    """
    Write each table to a separate CSV file without using csv module.
    Wraps all cell content in quotes to handle commas and special characters.
    """
    for table_idx, table in enumerate(tables, 1):
        if not table:
            continue

        # Normalize row lengths (pad with empty strings)
        max_cols = max(len(row) for row in table if row)
        for row in table:
            while len(row) < max_cols:
                row.append('')

        csv_file = f"table_{table_idx}.csv"
        try:
            with open(csv_file, 'w', encoding='utf-8') as f:
                for row in table:
                    # Quote all fields (escape quotes by doubling) and join with commas
                    quoted_row = ['"' + cell.replace('"', '""') + '"' for cell in row]
                    f.write(','.join(quoted_row) + '\n')
            print(f"Table {table_idx} ({len(table)} rows, {max_cols} columns) saved to '{csv_file}'")
        except IOError as e:
            print(f"Error writing '{csv_file}': {e}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 chinonso_egeolu_project1.py <html_file>")
        print("Example: python3 chinonso_egeolu_project1.py input.html")
        sys.exit(1)

    html_file = sys.argv[1]
    html_content = read_file(html_file)
    tables = extract_tables(html_content)

    if not tables:
        print("No tables found in the HTML file.")
        return

    write_csv(tables)
    print(f"\nConversion complete! {len(tables)} tables processed.")

if __name__ == "__main__":
    main()