import sys
import urllib.request
import csv
from html.parser import HTMLParser
import os


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.current_table = []
        self.current_row = []
        self.current_cell = ""
        self.tables = []

    def handle_starttag(self, tag, attrs):
        if tag == "table":
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

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data


def fetch_html(source):
    """Return HTML from a URL or file path."""
    if source.startswith("http://") or source.startswith("https://"):
        # Treat as URL
        req = urllib.request.Request(
            source,
            headers={"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
        )
        with urllib.request.urlopen(req) as response:
            return response.read().decode("utf-8")
    else:
        # Treat as local file
        if not os.path.exists(source):
            raise FileNotFoundError(f"File not found: {source}")
        with open(source, "r", encoding="utf-8") as f:
            return f.read()


def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <URL or HTML file>")
        sys.exit(1)

    source = sys.argv[1]

    try:
        html = fetch_html(source)
    except Exception as e:
        print(f"Error reading source: {e}")
        sys.exit(1)

    # Save raw HTML to disk
    with open("page.html", "w", encoding="utf-8") as f:
        f.write(html)
    print("Saved page.html")

    # Parse tables
    parser = TableParser()
    parser.feed(html)

    if not parser.tables:
        print("No tables found.")
        sys.exit(0)

    for i, table in enumerate(parser.tables, start=1):
        filename = f"table_{i}.csv"
        with open(filename, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(table)
        print(f"Saved {filename}")


if __name__ == "__main__":
    main()
