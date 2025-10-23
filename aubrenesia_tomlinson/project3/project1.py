import urllib.request
import csv
import re
import sys
import os

def strip_tags(text):
    return re.sub(r'<[^>]+>', '', text).strip()

def parse_table(html):
    html_lower = html.lower()
    start_index = html_lower.find('<table')
    if start_index == -1:
        return []
    table_tag_end = html_lower.find('>', start_index)
    if table_tag_end == -1:
        return []
    end_index = html_lower.find('</table>', table_tag_end)
    if end_index == -1:
        return []
    table_html = html[table_tag_end + 1:end_index]
    rows_raw = re.findall(r'<tr.*?>.*?</tr>', table_html, re.DOTALL | re.IGNORECASE)

    table = []
    for row_html in rows_raw:
        cells_raw = re.findall(r'<t[dh].*?>(.*?)</t[dh]>', row_html, re.DOTALL | re.IGNORECASE)
        cleaned_cells = [strip_tags(cell) for cell in cells_raw]
        if cleaned_cells:
            table.append(cleaned_cells)

    return table

def create_csv(table, filename):
    with open(filename, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerows(table)

def main():
    if len(sys.argv) < 3:
        print("Usage: python project1.py <url> <output_csv_path>")
        sys.exit(1)

    url = sys.argv[1]
    output_path = sys.argv[2]

    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req).read().decode('utf-8')
    except Exception as e:
        print(f"Error fetching URL: {e}")
        sys.exit(1)

    table = parse_table(html)

    if not table:
        print(f"No table found in {url}")
        return

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    create_csv(table, output_path)
    print(f"Table extracted from {url} to {output_path}")

if __name__ == '__main__':
    main()
