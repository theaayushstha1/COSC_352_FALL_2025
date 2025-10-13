import urllib.request
from html.parser import HTMLParser
import csv
import sys
import os
from urllib.parse import urlparse

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

def fetch_html(url):
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0"}
    )
    with urllib.request.urlopen(req) as response:
        return response.read().decode()

def write_csv(table, filename):
    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        for row in table:
            writer.writerow(row)

def sanitize_domain(url):
    domain = urlparse(url).netloc.replace("www.", "").replace(".", "_")
    return domain

def main():
    urls = [
        "https://en.wikipedia.org/wiki/List_of_countries_by_GDP_(nominal)",
        "https://www.worldometers.info/world-population/population-by-country/",
        "https://www.statista.com/?srsltid=AfmBOoqRYak3Gsm7quwJ83XNxj4flOuGWJ8qOJSBDKP3ugqmfEcpMDDW"
    ]

    os.makedirs("output", exist_ok=True)

    for url in urls:
        print(f"🔍 Processing: {url}")
        try:
            html = fetch_html(url)
            parser = TableParser()
            parser.feed(html)

            domain = sanitize_domain(url)

            if parser.tables:
                for i, table in enumerate(parser.tables[:5], start=1):
                    filename = f"output/{domain}_table_{i}.csv"
                    write_csv(table, filename)
                    print(f"✅ Saved: {filename}")
            else:
                print(f"⚠️ No tables found on {url}")
        except Exception as e:
            print(f"❌ Error processing {url}: {e}")

if __name__ == "__main__":
    main()
