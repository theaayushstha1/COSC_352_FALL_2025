def strip_tags(text):
    # Remove HTML tags from a string by skipping characters between '<' and '>'
    result = ''
    in_tag = False
    # Iterate over each character in the text and entering or exiting tags
    for c in text:
        if c == '<':
            in_tag = True  
        elif c == '>':
            in_tag = False  
        elif not in_tag:
            result += c  
    return result.strip()

def find_all_tables(html):
    # Find all <table>...</table> blocks in the HTML source
    tables = []
    pos = 0
    # Finding the tables and their positions in the html string
    while True:
        table_start = html.find('<table', pos)  
        if table_start == -1:
            break  
        table_end = html.find('</table>', table_start)  
        if table_end == -1:
            break  
        table_html = html[table_start:table_end+8]  
        tables.append(table_html)
        pos = table_end + 8  
    return tables

def parse_table(table_html):
    # Parse a single table's HTML and extract rows and columns as a list of lists
    rows = []
    pos = 0
    while True:
        tr_start = table_html.find('<tr', pos)  
        if tr_start == -1:
            break  
        tr_end = table_html.find('</tr>', tr_start)  
        if tr_end == -1:
            break  
        tr_html = table_html[tr_start:tr_end]  
        # Find all <td> (table data) and <th> (table header) cells in this row
        cols = []
        col_pos = 0
        while True:
            td_start = tr_html.find('<td', col_pos)
            th_start = tr_html.find('<th', col_pos)
            # Determine which comes first: <td> or <th>
            if td_start == -1 and th_start == -1:
                break  
            if td_start == -1 or (th_start != -1 and th_start < td_start):
                tag_start = th_start
                tag = '<th'
            else:
                tag_start = td_start
                tag = '<td'
            tag_end = tr_html.find('>', tag_start)  
            if tag_end == -1:
                break  
            cell_start = tag_end + 1
            cell_end = tr_html.find('</', cell_start)  
            if cell_end == -1:
                break  
            cell = tr_html[cell_start:cell_end]  
            cols.append(strip_tags(cell))  
            col_pos = cell_end  
        if cols:
            rows.append(cols)  
        pos = tr_end + 5  
    return rows

def write_csv(rows, filename):
    # Write a list of rows (list of lists) to a CSV file
    with open(filename, 'w', encoding='utf-8') as f:
        for row in rows:
            csv_row = []
            for cell in row:
                # Escape double quotes by doubling them
                cell = cell.replace('"', '""')
                # If cell contains a comma or quote, wrap it in quotes
                if ',' in cell or '"' in cell:
                    cell = f'"{cell}"'
                csv_row.append(cell)
            f.write(','.join(csv_row) + '\n')  # Write the row as CSV

def html_tables_to_csv(html_file):
    # Main function: reads HTML file, extracts all tables, writes each to a CSV file
    with open(html_file, 'r', encoding='utf-8') as f:
        html = f.read()
    tables = find_all_tables(html)  # Get all tables in the HTML
    if not tables:
        print("No tables found.")
        return
    for idx, table_html in enumerate(tables):
        rows = parse_table(table_html)  # Parse each table into rows
        if rows:
            csv_file = f'output_table_{idx+1}.csv'  
            write_csv(rows, csv_file) 
            print(f"Table {idx+1} written to {csv_file}")

# Example usage:
# html_tables_to_csv('Comparison_of_programming_languages.html')

# To use with any HTML file:
if __name__ == "__main__":
    html_tables_to_csv('Comparison_of_programming_languages.html')