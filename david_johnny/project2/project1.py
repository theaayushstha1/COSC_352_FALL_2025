import urllib.request
from html.parser import HTMLParser
import sys
import csv

def read_link(url):
    try:
        # Add a fake browser User-Agent
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                                 "AppleWebKit/537.36 (KHTML, like Gecko) "
                                 "Chrome/115.0 Safari/537.36"}
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req) as response:
            html = response.read().decode('utf-8')
        return html
    except Exception as e:
        print("Error fetching URL:", e)
        return ""

class TableParser(HTMLParser):
    def __init__(self, target_class=None):
        super().__init__()
        self.target_class = target_class
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = ""

    def handle_starttag(self, tag, attrs):
        if tag == "table":
            # Convert attrs list -> dict for easy lookup
            attr_dict = dict(attrs)
            table_class = attr_dict.get("class", "")
            if self.target_class is None or self.target_class in table_class.split():
                self.in_table = True
                self.current_table = []
        elif tag == "tr" and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ("td", "th") and self.in_row:
            self.in_cell = True
            self.current_cell = ""

    def handle_endtag(self, tag):
        if tag == "table" and self.in_table:
            self.in_table = False
            self.tables.append(self.current_table)
        elif tag == "tr" and self.in_row:
            self.in_row = False
            self.current_table.append(self.current_row)
        elif tag in ("td", "th") and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())
            self.current_cell = ""

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

if len(sys.argv) < 2:
    print("Usage: python project1.py <URL>")
    sys.exit(1)

url = sys.argv[1]
html_content = read_link(url)

if html_content:
    # Allow configuring which table class to filter for via the TABLE_CLASS env var:
    # - If TABLE_CLASS is unset -> default to 'wikitable' (preserve previous behavior)
    # - If TABLE_CLASS is set to an empty string -> parse all tables (no class filter)
    import os
    table_class_env = os.environ.get("TABLE_CLASS", None)
    if table_class_env is None:
        target_class = "wikitable"
    elif table_class_env == "":
        target_class = None
    else:
        target_class = table_class_env

    parser = TableParser(target_class=target_class)
    parser.feed(html_content)

    print("Wikitable tables found:", len(parser.tables))

    import os

    # Allow controlling output directory from environment. If OUTPUT_DIR is set,
    # write CSVs there; otherwise write to current working directory.
    output_dir = os.environ.get("OUTPUT_DIR", ".")
    os.makedirs(output_dir, exist_ok=True)

    for idx, table in enumerate(parser.tables):
        print(f"Table {idx+1}:")
        for row in table:
            print(" | ".join(row))
        print("-" * 40)
        # Write each table to a CSV file
        csv_filename = f"table_{idx+1}.csv"
        out_path = os.path.join(output_dir, csv_filename)
        with open(out_path, "w", newline='', encoding='utf-8') as csvfile:
            writer = csv.writer(csvfile)
            writer.writerows(table)
        print(f"Saved Table {idx+1} to {out_path}")
else:
    print("No HTML content retrieved.")
#TO TEST PROGRAM RUN: python project1.py "https://en.wikipedia.org/wiki/Deltora_Quest_(TV_series)" OR python project1.py "https://en.wikipedia.org/wiki/List_of_programming_languages"
#The quotation marks were necessary to since powershell kept misinterpreting the parentheses in the URL.
#Also chose Deltora Quest since it 1. Has a table similar to the programming languages page and 2. Was a random show with a wikipage i thought of
