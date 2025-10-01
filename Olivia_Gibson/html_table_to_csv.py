"""
html_table_to_csv.py

Reads HTML tables from a local HTML file and writes each table to a CSV file.
No external libraries used — only built-in Python modules.

Author: [Your Name]
Date: [Today's Date]

Usage:
    python html_table_to_csv.py comparison.html

Output:
    Creates CSV files named table_1.csv, table_2.csv, etc., in the current directory.
"""

import sys

def extract_tables(html):
    tables = []
    pos = 0
    while True:
        start_table = html.find("<table", pos)
        if start_table == -1:
            break
        end_table = html.find("</table>", start_table)
        table_html = html[start_table:end_table + 8]
        tables.append(table_html)
        pos = end_table + 8
    return tables

def extract_rows(table_html):
    rows = []
    pos = 0
    while True:
        start_row = table_html.find("<tr", pos)
        if start_row == -1:
            break
        end_row = table_html.find("</tr>", start_row)
        row_html = table_html[start_row:end_row + 5]
        cells = extract_cells(row_html)
        rows.append(cells)
        pos = end_row + 5
    return rows

def extract_cells(row_html):
    cells = []
    pos = 0
    while True:
        start_td = row_html.find("<td", pos)
        start_th = row_html.find("<th", pos)
        if start_td == -1 and start_th == -1:
            break
        if start_td != -1 and (start_td < start_th or start_th == -1):
            start = start_td
            end_tag = "</td>"
        else:
            start = start_th
            end_tag = "</th>"
        end = row_html.find(end_tag, start)
        cell_html = row_html[start:end + len(end_tag)]
        cell_text = strip_tags(cell_html)
        cells.append(cell_text.strip())
        pos = end + len(end_tag)
    return cells

def strip_tags(html):
    text = ""
    in_tag = False
    for char in html:
        if char == "<":
            in_tag = True
        elif char == ">":
            in_tag = False
        elif not in_tag:
            text += char
    return text

def write_csv(table, index):
    filename = f"table_{index}.csv"
    with open(filename, "w", encoding="utf-8") as f:
        for row in table:
            line = ",".join(f'"{cell}"' for cell in row)
            f.write(line + "\n")
    print(f"✅ Saved: {filename}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python html_table_to_csv.py [local HTML file]")
        return

    filepath = sys.argv[1]
    try:
        with open(filepath, "r", encoding="utf-8") as file:
            html = file.read()
    except FileNotFoundError:
        print(f"❌ File not found: {filepath}")
        return

    tables_html = extract_tables(html)
    for i, table_html in enumerate(tables_html, start=1):
        rows = extract_rows(table_html)
        write_csv(rows, i)

if __name__ == "__main__":
    main()
