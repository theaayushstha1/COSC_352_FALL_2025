import sys
import urllib.request
import os

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
            with urllib.request.urlopen(req, timeout=30) as response:
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

def scrape_website(source, site_num):
    """Scrape a single website and save its tables."""
    print(f"\n{'='*50}")
    print(f"Site {site_num}: {source}")
    print('='*50)
    
    html = load_html(source)
    if not html:
        print(f"Error: could not load '{source}'")
        return

    tables = find_all_tables(html)
    if not tables:
        print("No tables found.")
        return

    print(f"Found {len(tables)} table(s). Extracting...")


    # Output base directory (use /app/output if set, else current dir)
    output_base = os.environ.get("OUTPUT_DIR", "output")
    site_dir = os.path.join(output_base, f"site_{site_num}")
    os.makedirs(site_dir, exist_ok=True)

    for i, t in enumerate(tables):
        rows = [extract_cells(r) for r in extract_rows(t)]
        rows = [r for r in rows if r]
        if not rows:
            continue
        # Save to site-specific directory
        outname = os.path.join(site_dir, f"table_{i+1}.csv")
        write_csv(outname, rows)
        print(f"  Saved {outname} ({len(rows)} rows, {len(rows[0])} cols)")

    print(f"Site {site_num} complete!")


def main():
    """Main function to scrape all websites."""
    # List of websites to scrape
    websites = [
        "https://pypl.github.io/PYPL.html",
        "https://github.com/quambene/pl-comparison",
        "https://www.reddit.com/r/rust/comments/uq6j2q/programming_language_comparison_cheat_sheet/"
    ]
    
    print("Starting web scraper...")
    print(f"Total websites to scrape: {len(websites)}")
    
    # Scrape each website
    for i, url in enumerate(websites, 1):
        scrape_website(url, i)
    
    print("\n" + "="*50)
    print("All scraping complete!")
    print("="*50)
    print("\nResults saved in:")
    for i in range(1, len(websites) + 1):
        print(f"  - site_{i}/")


if __name__ == "__main__":
    main()
