import sys
import urllib.request
import csv
from pathlib import Path
from html.parser import HTMLParser

#---------------Simple Table Parser ----------------
class TableParser(HTMLParser):
    """Simple HTML table parser that extracts table data."""
    
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_tr = False
        self.in_td = False
        self.current_row = []
        self.all_table_data = []
        self.current_cell_data = []

    def handle_starttag(self, tag, attrs):
        """Called when parser encounters an opening tag."""
        if tag == 'table':
            self.in_table = True
        elif tag == 'tr' and self.in_table:
            self.in_tr = True
            self.current_row = []
        elif tag == 'td' and self.in_table:
            self.in_td = True
            self.current_cell_data = []
            
    def handle_endtag(self, tag):
        """Called when parser encounters a closing tag."""
        if tag == 'table':
            self.in_table = False
        elif tag == 'tr':
            self.in_tr = False
            # Only add rows with actual data (at least 3 cells)
            if self.current_row and len(self.current_row) >= 3:
                # Skip header rows
                if self.current_row[0] != 'No.' and self.current_row[1] != 'Date Died':
                    # Skip completely empty rows
                    if any(cell.strip() for cell in self.current_row[:3]):
                        # Keep exactly 9 columns
                        row_data = self.current_row[:9]
                        # Pad with empty strings if needed
                        while len(row_data) < 9:
                            row_data.append('')
                        self.all_table_data.append(row_data)
            self.current_row = []
        elif tag == 'td':
            self.in_td = False
            cell_text = ' '.join(self.current_cell_data).strip()
            self.current_row.append(cell_text)
            self.current_cell_data = []
                
    def handle_data(self, data):
        """Called when parser encounters text content."""
        if self.in_td:
            cleaned_data = ' '.join(data.strip().split())
            if cleaned_data:
                self.current_cell_data.append(cleaned_data)


# ---------------- Helper Functions ----------------

def load_html(source):
    """Load HTML content from a file or URL."""
    if source.startswith("http://") or source.startswith("https://"):
        try:
            req = urllib.request.Request(
                source,
                headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
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


# ---------------- Main Program ----------------

def main():
    """Main function to scrape all websites and save into info_death.csv."""
    websites = ["https://chamspage.blogspot.com/"]
    
    print("Starting web scraper...")
    print(f"Total websites to scrape: {len(websites)}")
    
    # Output file placed next to this script
    output_file = Path(__file__).resolve().parent / "info_death.csv"

    # Remove existing file so we start fresh
    try:
        if output_file.exists():
            output_file.unlink()
    except Exception as e:
        print(f"Warning: could not remove existing {output_file}: {e}")

    all_data = []
    
    # Scrape each website
    for i, url in enumerate(websites, 1):
        print(f"\n{'='*50}")
        print(f"Site {i}: {url}")
        print('='*50)
        
        html = load_html(url)
        if not html:
            print(f"Error: could not load '{url}'")
            continue

        print("Parsing HTML tables...")
        parser = TableParser()
        parser.feed(html)
        
        print(f"Found {len(parser.all_table_data)} data rows")
        all_data.extend(parser.all_table_data)
        print(f"Site {i} complete!")

    # Write all data to CSV with correct header
    print(f"\nWriting data to CSV...")
    with output_file.open('w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        # Write the correct header
        writer.writerow(['No', 'Date Died', 'Name', 'Age', 'Address Block Found', 
                        'Notes', 'No Violent Criminal History', 'Surveillance Camera', 'Case Closed'])
        # Write all data rows
        writer.writerows(all_data)

    print("\n" + "="*50)
    print("All scraping complete!")
    print("="*50)
    print(f"\nResults saved in: {output_file}")
    print(f"Total rows extracted: {len(all_data)}")


if __name__ == "__main__":
    main()