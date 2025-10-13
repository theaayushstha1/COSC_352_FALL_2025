import urllib.request
from html.parser import HTMLParser
import csv

# Custom HTML parser to extract table data
class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = ""

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
        if tag == "table":
            self.in_table = False
            self.tables.append(self.current_table)
        elif tag == "tr":
            self.in_row = False
            self.current_table.append(self.current_row)
        elif tag in ("td", "th"):
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())

    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

# Fetch HTML with User-Agent header to avoid 403 error
def fetch_html(url):
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req) as response:
        return response.read().decode()

# Write extracted table to CSV
def write_csv(table, filename):
    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in table:
            writer.writerow(row)

# Main execution
def main():
    url = "https://en.wikipedia.org/wiki/Comparison_of_programming_languages"
    html = fetch_html(url)
    parser = TableParser()
    parser.feed(html)

    if parser.tables:
        for i, table in enumerate(parser.tables[:5], start=1):  # Save first 5 tables
            filename = f"test_table_{i}.csv"
            write_csv(table, filename)
            print(f"✅ Saved: {filename}")
    else:
        print("⚠️ No tables found on the page.")

if __name__ == "__main__":
    main()
