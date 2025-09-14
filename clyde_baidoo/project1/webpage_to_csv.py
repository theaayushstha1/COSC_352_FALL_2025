import urllib.request
from html.parser import HTMLParser
import csv

class TableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_row = False
        self.in_cell = False
        self.tables = []
        self.current_table = []
        self.current_row = []
        self.current_cell = ''
    
    def handle_starttag(self, tag, attrs):
        tag = tag.lower()
        if tag == 'table':
            self.in_table = True
            self.current_table = []
        elif tag == 'tr' and self.in_table:
            self.in_row = True
            self.current_row = []
        elif tag in ('td', 'th') and self.in_row:
            self.in_cell = True
            self.current_cell = ''
    
    def handle_endtag(self, tag):
        tag = tag.lower()
        if tag == 'table' and self.in_table:
            self.in_table = False
            self.tables.append(self.current_table)
        elif tag == 'tr' and self.in_row:
            self.in_row = False
            self.current_table.append(self.current_row)
        elif tag in ('td', 'th') and self.in_cell:
            self.in_cell = False
            self.current_row.append(self.current_cell.strip())
    
    def handle_data(self, data):
        if self.in_cell:
            self.current_cell += data

def read_from_webpage(url):
    req = urllib.request.Request(
        url,
        headers={'User-Agent': 'Mozilla/5.0'}  # Pretend to be a browser
    )
    with urllib.request.urlopen(req) as response:
        html = response.read().decode('utf-8')
    return html

def read_to_csv(html):
    parser = TableParser()
    parser.feed(html)
    
    for idx, table in enumerate(parser.tables):
        filename = f'table_{idx + 1}.csv'
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            for row in table:
                writer.writerow(row)
        print(f"Saved {filename}")

def main():
    url = input(str("Please enter url: "))
    html = read_from_webpage(url)
    read_to_csv(html)

if __name__ == "__main__":
    main()
