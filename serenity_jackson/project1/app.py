import sys
import csv
import os
from bs4 import BeautifulSoup

def extract_and_write_tables(html_file_path):
    # Read and parse the HTML file
    with open(html_file_path, 'r', encoding='utf-8') as file:
        soup = BeautifulSoup(file, 'html.parser')

    # Find all tables
    tables = soup.find_all('table')
    if not tables:
        print("No <table> elements found.")
        return

    base_filename = os.path.splitext(os.path.basename(html_file_path))[0]
    output_dir = os.path.dirname(html_file_path) or '.'

    for index, table in enumerate(tables, start=1):
        rows = table.find_all('tr')
        data = []

        for row in rows:
            cells = row.find_all(['td', 'th'])
            data.append([cell.get_text(strip=True) for cell in cells])

        # Define output CSV filename
        csv_filename = os.path.join(output_dir, f"{base_filename}_table_{index}.csv")

        # Write the data to the CSV file
        with open(csv_filename, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerows(data)

        print(f"✅ Saved Table {index} to: {csv_filename}")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python html_tables_to_files.py path/to/file.html")
        sys.exit(1)

    html_file_path = sys.argv[1]
    extract_and_write_tables(html_file_path)

