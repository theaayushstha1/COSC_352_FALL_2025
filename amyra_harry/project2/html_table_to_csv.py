import http.client
import ssl
import csv
from urllib.parse import urlparse
import sys
import os

def fetch_html_from_url(url):
    """Fetch HTML using http.client (supports HTTPS)."""
    parsed = urlparse(url)
    scheme = parsed.scheme or "http"
    host = parsed.hostname
    path = parsed.path or "/"

    if parsed.query:
        path += "?" + parsed.query

    if scheme == "https":
        conn = http.client.HTTPSConnection(host, context=ssl.create_default_context())
    else:
        conn = http.client.HTTPConnection(host)

    headers = {"User-Agent": "Mozilla/5.0"}
    conn.request("GET", path, headers=headers)
    response = conn.getresponse()
    html = response.read().decode("utf-8", errors="ignore")
    conn.close()
    return html


def find_all_tables(html):
    """Find <table>...</table> blocks in HTML (case-insensitive)."""
    tables = []
    pos = 0
    html_lower = html.lower()
    while True:
        start = html_lower.find("<table", pos)
        if start == -1:
            break
        end = html_lower.find("</table>", start)
        if end == -1:
            break
        tables.append(html[start:end+8])
        pos = end + 8
    return tables


def parse_table(table_html):
    """Extract rows and cells from a table (basic parsing)."""
    rows = []
    table_lower = table_html.lower()
    pos = 0
    while True:
        row_start = table_lower.find("<tr", pos)
        if row_start == -1:
            break
        row_end = table_lower.find("</tr>", row_start)
        if row_end == -1:
            break

        row_html = table_html[row_start:row_end]
        row = []

        # Look for <td> and <th>
        cell_pos = 0
        row_lower = row_html.lower()
        while True:
            td_start = row_lower.find("<td", cell_pos)
            th_start = row_lower.find("<th", cell_pos)
            if td_start == -1 and th_start == -1:
                break
            if td_start == -1 or (th_start != -1 and th_start < td_start):
                tag_end = "</th>"
                start = th_start
            else:
                tag_end = "</td>"
                start = td_start

            start = row_lower.find(">", start) + 1
            end = row_lower.find(tag_end, start)
            if end == -1:
                break

            cell_content = row_html[start:end].strip()
            row.append(cell_content)

            cell_pos = end + len(tag_end)
        rows.append(row)

        pos = row_end + 5
    return rows


def safe_filename(url, table_index):
    """Turn URL into a safe file name."""
    parsed = urlparse(url)
    name = parsed.netloc + parsed.path
    if not name:
        name = "output"
    # Replace bad characters with underscores
    name = name.replace("/", "_").replace("?", "_").replace("=", "_").replace("&", "_")
    return f"{name}_table_{table_index}.csv"


def export_to_csv(table_data, filename):
    """Write table rows into a CSV file."""
    with open(filename, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(table_data)


def html_tables_to_csv(url):
    """Fetch HTML, parse tables, and export each one to CSV."""
    print(f"Fetching: {url}")
    html = fetch_html_from_url(url)
    tables = find_all_tables(html)
    print(f"Found {len(tables)} tables")

    if not tables:
        print("No tables found.")
        return

    for i, t in enumerate(tables, 1):
        rows = parse_table(t)
        if rows:
            filename = safe_filename(url, i)
            export_to_csv(rows, filename)
            print(f"Saved {filename}")


if __name__ == "__main__":
    if len(sys.argv) > 1:
        url = sys.argv[1]  # Take URL from command line
    else:
        url = input("Enter a URL (http:// or https://): ").strip()

    html_tables_to_csv(url)
