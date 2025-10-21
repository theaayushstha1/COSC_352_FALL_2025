from html.parser import HTMLParser
from urllib.request import urlopen, Request
from urllib.error import URLError, HTTPError 
import argparse 
import csv
import os
import sys
import io


def cleanup_text(s: str): 
    return " ".join(s.split()).strip()


class TableParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.tables = []
        self.in_table = False
        self.in_tr = False
        self.in_cell = False
        self.cell_tag = None
        self.cell_text_parts = []
        self.current_table_rows = []
        self.pending_rowspans = []
        self.row_cells = []
        self.cell_rowspan = 1
        self.cell_colspan = 1

    def check_width(self, width):
        if len(self.pending_rowspans) < width:
            self.pending_rowspans.extend([0] * (width - len(self.pending_rowspans)))

    def allocate_next_free_col_index(self):
        col = 0
        while True:
            self.check_width(col + 1)
            if self.pending_rowspans[col] == 0 and (col >= len(self.row_cells)):
                return col
            col += 1 

    def place_cell_with_spans(self, text, rowspan, colspan):
        col_index = 0 
        curr_row = []
        current_width = max(len(self.row_cells), len(self.pending_rowspans))
        
        for _ in range(current_width):
            if len(curr_row) < len(self.row_cells):
                curr_row.append(self.row_cells[_])
            else:
                curr_row.append(None)
        col = 0

        while True:
            self.check_width(col + 1)
            if col >= len(curr_row):
                curr_row.extend([None] * (col - len(curr_row) + 1))
            if self.pending_rowspans[col] == 0 and curr_row[col] is None:
                col_index = col
                break
            col += 1

        req_width = col_index + colspan
        if len(curr_row) < req_width:
            curr_row.extend([None] * (req_width - len(curr_row)))
        self.check_width(req_width)

        for c in range(col_index, col_index + colspan):
            curr_row[c] = text

        if rowspan > 1:
            for c in range(col_index, col_index + colspan):
                self.pending_rowspans[c] = max(self.pending_rowspans[c], rowspan - 1)

        self.row_cells = curr_row
    
    def handle_starttag(self, tag, attrs):
        t = tag.lower()
        if t == "table":
            self.in_table = True
            self.current_table_rows = []
            self.pending_rowspans = []
        elif self.in_table and t == "tr":
            self.in_tr = True
            self.row_cells = []
            if self.pending_rowspans:
                self.pending_rowspans = [max(0, x - 1) for x in self.pending_rowspans]
        elif self.in_tr and t in ("td", "th"):
            self.in_cell = True
            self.cell_tag = t
            self.cell_text_parts = []
            attrs_dict = dict((k.lower(), v) for k, v in attrs)

            try:
                self.cell_colspan = int(attrs_dict.get("colspan", "1"))
            except ValueError:
                self.cell_colspan = 1
            try:
                self.cell_rowspan = int(attrs_dict.get("rowspan", "1"))
            except ValueError:
                self.cell_rowspan = 1
        else:
            pass
    def handle_endtag(self, tag):
        t = tag.lower()
        if t == "table" and self.in_table:
            maxw = 0
            for r in self.current_table_rows:
                maxw = max(maxw, len(r))
            for r in self.current_table_rows:
                if len(r) < maxw:
                    r.extend([""] * (maxw - len(r)))

            self.tables.append(self.current_table_rows)
            self.in_table = False
            self.in_tr = False
            self.in_cell = False
            self.current_table_rows = []
            self.pending_rowspans = []
            self.row_cells = []
        
        elif t == "tr" and self.in_tr:
            if self.row_cells:
                row = [("" if v is None else v) for v in self.row_cells]
                self.current_table_rows.append(row)
            else:
                self.current_table_rows.append([])
            
            self.in_tr = False
            self.row_cells = []

        elif t in ("td", "th") and self.in_cell:
            text = cleanup_text("".join(self.cell_text_parts))
            self.place_cell_with_spans(text, self.cell_rowspan, self.cell_colspan)
            self.in_cell = False
            self.cell_tag = None
            self.cell_text_parts = []
            self.cell_colspan = 1
            self.cell_rowspan = 1

    def handle_data(self, data):
        if self.in_cell:
            self.cell_text_parts.append(data)



def read_html_url(url: str):
    req = Request(url, headers={"User-Agent": "Mozilla/5.0 (compatible; table-scraper/1.0)"})
    
    try:
        with urlopen(req) as resp:
            charset = resp.headers.get_content_charset() or "utf-8"
            return resp.read().decode(charset, errors = "replace")
    except (HTTPError, URLError) as e:
        print(f"Error fetching URL: {e}", file=sys.stderr)
        sys.exit(2)


def read_html_file(path: str):
    with io.open(path, "r", encoding="utf-8", errors = "replace") as f:
        return f.read()
    

def write_tables_to_csv(tables, outdir: str):
    os.makedirs(outdir, exist_ok = True)
    count = 0

    for i, table in enumerate(tables, start = 1):
        if not table:
            continue
    
        maxw = max((len(r) for r in table), default = 0)
        normalized = [(r + [" "] * (maxw - len(r))) for r in table]
        path = os.path.join(outdir, f"table_{i}.csv")

        with open(path, "w", newline = "", encoding = "utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(normalized)

        count += 1
        print(f"Wrote {path} ({len(normalized)} rows, {maxw} columns)")

    if count == 0:
        print("No tables were found.", file=sys.stderr)



def main():
    if len(sys.argv) < 2:
        print("Usuage: python table_2_csv.py <url_or_path> [outdir]", file=sys.stderr)
        sys.exit(1)
    
    src = sys.argv[1]
    outdir = sys.argv[2] if len(sys.argv) > 2 else "output"

    if src.startswith(("http://", "https://")):
        html = read_html_url(src)
    else:
        html = read_html_file(src)

    parser = TableParser()
    parser.feed(html)
    write_tables_to_csv(parser.tables, outdir)

if __name__ == "__main__":
    main()