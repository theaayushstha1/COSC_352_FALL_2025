import sys
import urllib.request

class HTMLTableExtractor:
    """Extract tables from HTML sources and convert to CSV format."""

    def __init__(self):
        self.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
        self.html_entities = {
            '&amp;': '&', '&lt;': '<', '&gt;': '>',
            '&quot;': '"', '&nbsp;': ' ', '&#39;': "'"
        }

    def fetch_content(self, source):
        """Retrieve HTML content from URL or local file."""
        if self._is_url(source):
            return self._download_from_url(source)
        return self._read_from_file(source)

    def _is_url(self, source):
        return source.lower().startswith(('http://', 'https://'))

    def _download_from_url(self, url):
        """Download HTML content from a web URL."""
        try:
            request = urllib.request.Request(url, headers={'User-Agent': self.user_agent})
            with urllib.request.urlopen(request) as response:
                return response.read().decode('utf-8', errors='ignore')
        except Exception as error:
            print(f"Failed to fetch URL: {error}")
            return None

    def _read_from_file(self, filepath):
        """Read HTML content from local file."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception:
            return None

    def parse_tables(self, html_content):
        """Locate and extract all table elements from HTML."""
        table_elements = []
        html_lower = html_content.lower()
        search_pos = 0

        while True:
            table_start = html_lower.find('<table', search_pos)
            if table_start == -1:
                break

            table_end = html_lower.find('</table>', table_start)
            if table_end == -1:
                break

            full_table = html_content[table_start:table_end + len('</table>')]
            table_elements.append(full_table)
            search_pos = table_end + len('</table>')

        return table_elements

    def extract_table_data(self, table_html):
        """Convert table HTML into structured row data."""
        row_elements = self._find_table_rows(table_html)
        structured_data = []

        for row_html in row_elements:
            cell_data = self._extract_cell_contents(row_html)
            if cell_data:  # Skip empty rows
                structured_data.append(cell_data)

        return structured_data

    def _find_table_rows(self, table_html):
        """Extract all row elements from table HTML."""
        rows = []
        html_lower = table_html.lower()
        search_pos = 0

        while True:
            row_start = html_lower.find('<tr', search_pos)
            if row_start == -1:
                break

            row_end = html_lower.find('</tr>', row_start)
            if row_end == -1:
                break

            row_content = table_html[row_start:row_end + len('</tr>')]
            rows.append(row_content)
            search_pos = row_end + len('</tr>')

        return rows

    def _extract_cell_contents(self, row_html):
        """Extract text content from table cells (td/th elements)."""
        cells = []
        html_lower = row_html.lower()
        search_pos = 0

        while True:
            td_pos = html_lower.find('<td', search_pos)
            th_pos = html_lower.find('<th', search_pos)

            if td_pos == -1 and th_pos == -1:
                break

            # Determine which cell type comes first
            if th_pos == -1 or (td_pos != -1 and td_pos < th_pos):
                cell_tag, cell_pos = 'td', td_pos
            else:
                cell_tag, cell_pos = 'th', th_pos

            # Find cell boundaries
            opening_end = row_html.find('>', cell_pos)
            closing_start = html_lower.find('</' + cell_tag + '>', opening_end)

            if closing_start == -1:
                break

            # Extract and clean cell content
            raw_content = row_html[opening_end + 1:closing_start]
            clean_content = self._sanitize_text(self._strip_html_tags(raw_content))
            cells.append(clean_content)

            search_pos = closing_start + len('</' + cell_tag + '>')

        return cells

    def _strip_html_tags(self, text):
        """Remove HTML markup from text content."""
        cleaned = ""
        inside_tag = False

        for char in text:
            if char == '<':
                inside_tag = True
            elif char == '>':
                inside_tag = False
            elif not inside_tag:
                cleaned += char

        return cleaned

    def _sanitize_text(self, text):
        """Clean text by handling entities and whitespace."""
        if not text:
            return ""

        # Replace HTML entities
        for entity, replacement in self.html_entities.items():
            text = text.replace(entity, replacement)

        # Normalize whitespace
        return ' '.join(text.split())

    def export_to_csv(self, table_data, filename):
        """Write table data to CSV file with proper escaping."""
        csv_rows = []
        for row in table_data:
            escaped_cells = [self._escape_csv_field(cell) for cell in row]
            csv_rows.append(','.join(escaped_cells))

        try:
            with open(filename, 'w', encoding='utf-8') as file:
                file.write('\n'.join(csv_rows) + '\n')
            return True
        except Exception as e:
            print(f"Error writing CSV file: {e}")
            return False

    def _escape_csv_field(self, field):
        """Apply CSV escaping rules to field content."""
        special_chars = [',', '"', '\n', '\r']

        if any(char in field for char in special_chars):
            return '"' + field.replace('"', '""') + '"'
        return field

    def process_source(self, source):
        """Main processing pipeline: fetch -> parse -> extract -> save."""
        print(f"Processing: {source}")

        # Step 1: Get HTML content
        html_content = self.fetch_content(source)
        if not html_content:
            print(f"Error: Unable to load content from '{source}'")
            return False

        # Step 2: Find all tables
        tables = self.parse_tables(html_content)
        if not tables:
            print("No tables detected in the content.")
            return True

        print(f"Discovered {len(tables)} table(s). Processing...")

        # Step 3: Process each table
        tables_processed = 0
        for index, table_html in enumerate(tables, 1):
            table_data = self.extract_table_data(table_html)

            if not table_data:
                continue

            # Step 4: Save to CSV
            output_filename = f"extracted_table_{index}.csv"
            if self.export_to_csv(table_data, output_filename):
                row_count = len(table_data)
                col_count = len(table_data[0]) if table_data else 0
                print(f"  → {output_filename} saved ({row_count} rows, {col_count} columns)")
                tables_processed += 1

        print(f"Extraction complete. {tables_processed} table(s) processed.")
        return True


def run_extraction(source_path):
    """Entry point for table extraction process."""
    extractor = HTMLTableExtractor()
    success = extractor.process_source(source_path)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    # Command line usage - check if URL/file provided as argument
    if len(sys.argv) > 1:
        run_extraction(sys.argv[1])
    else:
        # Default example if no arguments provided
        print("No source provided. Running with example URL...")
        run_extraction("https://en.wikipedia.org/wiki/Comparison_of_programming_languages")
        print("\nUsage: python script.py <URL_or_file_path>")
        print("Example: python script.py https://example.com/page-with-tables.html")
