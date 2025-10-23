import sys
from html.parser import HTMLParser

html_file = sys.argv[1]
output_csv = sys.argv[2]

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

# Read HTML content
with open(html_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Parse tables
parser = TableParser()
parser.feed(content)

# Write each table to a CSV
for i, table in enumerate(parser.tables):
    filename = output_csv.replace('.csv', f'_table{i+1}.csv')
    with open(filename, 'w', encoding='utf-8') as f:
        for row in table:
            f.write(','.join(row) + '\n')
