import urllib.request
import csv
import re

# Fetch URL
url = input("Enter a URL: ").strip()

# Fetch HTML from URL
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 Windows NT 10.0; Win64; x64'})
html = urllib.request.urlopen(req).read().decode('utf-8')

# """Remove HTML tags using regex."""
def strip_tags(text):
    return re.sub(r'<[^>]+>', '', text).strip()

# Parse the table
def parse_table(html):
    # Combat case sensitivity
    html_lower = html.lower()

    # Find start of table tage using indices
    start_index = html_lower.find('<table')
    if start_index == -1:
        return []

    # Find end of table tag
    table_tag_end = html_lower.find('>', start_index)
    if table_tag_end == -1:
        return []

    # Find end of table
    end_index = html_lower.find('</table>', table_tag_end)
    if end_index == -1:
        return []

    # Extract table 
    table_html = html[table_tag_end + 1:end_index]

    # Split rows
    rows_raw = re.findall(r'<tr.*?>.*?</tr>', table_html, re.DOTALL | re.IGNORECASE)

    table = []
    for row_html in rows_raw:
        # Extract cells (th or td)
        cells_raw = re.findall(r'<t[dh].*?>(.*?)</t[dh]>', row_html, re.DOTALL | re.IGNORECASE)
        # Clean HTML from each cell
        cleaned_cells = [strip_tags(cell) for cell in cells_raw]
        if cleaned_cells:
            table.append(cleaned_cells)

    return table

def create_csv(table, filename='extracted_table.csv'):
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(table)

def main():
    table = parse_table(html)
    if not table:
        print("There is no table to extract.")
        return
    create_csv(table)
    print("Table found and extracted to extracted_table.csv.")

if __name__ == '__main__':
    main()