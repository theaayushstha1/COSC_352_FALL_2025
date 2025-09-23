import sys
import urllib.request

# ---------------- Helper Functions ----------------

def load_html(source):
    """Load HTML content from a file or URL."""
    if source.startswith("http://") or source.startswith("https://"):
        try:
            # Add a User-Agent header to mimic a browser request
            req = urllib.request.Request(
                source,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36'
                }
            )
            with urllib.request.urlopen(req) as response:
                return response.read().decode("utf-8", errors="ignore")
        except Exception as e:
            print(f"Error loading URL: {e}")
            return None
    else:
        try:
            with open(source, "r", encoding="utf-8") as f:
                return f.read()
        except:
            return None


def remove_tags(text):
    """Remove HTML tags using only basic string ops."""
    result, inside = "", False
    for c in text:
        if c == "<":
            inside = True
        elif c == ">":
            inside = False
        elif not inside:
            result += c
    return result


def clean_text(text):
    """Strip whitespace and replace common HTML entities."""
    if not text:
        return ""
    text = (text.replace("&amp;", "&").replace("&lt;", "<")
                .replace("&gt;", ">").replace("&quot;", '"')
                .replace("&nbsp;", " ").replace("&#39;", "'"))
    return " ".join(text.split())


def find_all_tables(html):
    """Return list of <table>...</table> strings."""
    tables, start = [], 0
    lower = html.lower()
    while True:
        tstart = lower.find("<table", start)
        if tstart == -1:
            break
        tend = lower.find("</table>", tstart)
        if tend == -1:
            break
        tables.append(html[tstart:tend + 8])
        start = tend + 8
    return tables


def extract_rows(table_html):
    """Return list of <tr>...</tr> strings from a table."""
    rows, start = [], 0
    lower = table_html.lower()
    while True:
        rstart = lower.find("<tr", start)
        if rstart == -1:
            break
        rend = lower.find("</tr>", rstart)
        if rend == -1:
            break
        rows.append(table_html[rstart:rend + 5])
        start = rend + 5
    return rows


def extract_cells(row_html):
    """Extract text from <td> and <th> cells in a row."""
    cells, start = [], 0
    lower = row_html.lower()
    while True:
        td, th = lower.find("<td", start), lower.find("<th", start)
        if td == -1 and th == -1:
            break
        if th == -1 or (td != -1 and td < th):
            tag, pos = "td", td
        else:
            tag, pos = "th", th
        tag_end = row_html.find(">", pos)
        close = lower.find(f"</{tag}>", tag_end)
        if close == -1:
            break
        content = row_html[tag_end+1:close]
        cells.append(clean_text(remove_tags(content)))
        start = close + len(tag) + 3
    return cells


def escape_csv(field):
    """Escape a value for CSV output."""
    if any(c in field for c in [",", '"', "\n", "\r"]):
        return '"' + field.replace('"', '""') + '"'
    return field


def write_csv(filename, rows):
    """Write rows to a CSV file."""
    with open(filename, "w", encoding="utf-8") as f:
        for row in rows:
            f.write(",".join(escape_csv(c) for c in row) + "\n")


# ---------------- Main Program ----------------

def main(source):
    html = load_html(source)
    if not html:
        print(f"Error: could not load '{source}'")
        sys.exit(1)

    tables = find_all_tables(html)
    if not tables:
        print("No tables found.")
        sys.exit(0)

    print(f"Found {len(tables)} table(s). Extracting...")

    for i, t in enumerate(tables):
        rows = [extract_cells(r) for r in extract_rows(t)]
        rows = [r for r in rows if r]
        if not rows:
            continue
        # make a clean filename
        outname = f"table_{i+1}.csv"
        write_csv(outname, rows)
        print(f"  Saved {outname} ({len(rows)} rows, {len(rows[0])} cols)")

    print("Done.")

# Example usage within Colab (replace with your desired URL or filename)
# main("https://en.wikipedia.org/wiki/Python_(programming_language)")

main('https://en.wikipedia.org/wiki/Comparison_of_programming_languages')