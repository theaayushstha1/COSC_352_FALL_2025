import sys
import csv
import requests
from html.parser import HTMLParser
from urllib.parse import urlparse

class BlogspotTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_tr = False
        self.in_td = False
        self.current_row = []
        self.all_table_data = []
        self.current_cell_data = []

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.in_table = True
        elif tag == 'tr' and self.in_table:
            self.in_tr = True
            self.current_row = []
        elif tag == 'td' and self.in_table:
            self.in_td = True
            self.current_cell_data = []
            
    def handle_endtag(self, tag):
        if tag == 'table':
            self.in_table = False
        elif tag == 'tr':
            self.in_tr = False
            # Only add rows that have actual data (not empty or just headers)
            if self.current_row and len(self.current_row) >= 3:
                # Skip if it's a header row
                if self.current_row[0] != 'No.' and self.current_row[1] != 'Date Died':
                    # Skip if all cells are empty
                    if any(cell.strip() for cell in self.current_row[:3]):
                        # Keep all 9 columns
                        row_data = self.current_row[:9]
                        # Pad with empty strings if row is shorter than 9 columns
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
        if self.in_td:
            cleaned_data = ' '.join(data.strip().split())
            if cleaned_data:
                self.current_cell_data.append(cleaned_data)

def fetch_and_extract_table(url):
    """
    Fetch the Blogspot page and extract the homicide table.
    """
    try:
        print("Fetching Blogspot page...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        print(f"Page fetched successfully! Content length: {len(response.text)} characters")
        print("Parsing HTML table...")
        
        parser = BlogspotTableParser()
        parser.feed(response.text)
        
        print(f"Found {len(parser.all_table_data)} rows")
        
        return parser.all_table_data
        
    except requests.RequestException as e:
        print(f"Error fetching the webpage: {e}")
        return None
    except Exception as e:
        print(f"Error parsing HTML: {e}")
        import traceback
        traceback.print_exc()
        return None

def get_website_prefix(url):
    """
    Generate a short prefix from the URL for naming CSV files.
    """
    domain = urlparse(url).netloc
    domain = domain.replace('www.', '').replace('.com', '').replace('.org', '').replace('.net', '').replace('.blogspot', '')
    
    if 'blogspot' in urlparse(url).netloc:
        subdomain = urlparse(url).netloc.split('.')[0]
        return subdomain[:8].lower()
    else:
        return domain.split('.')[0][:5].lower()

def save_to_csv(table_data, filepath):
    """
    Save table data to CSV file.
    """
    print(f"Attempting to save to: {filepath}")
    
    try:
        with open(filepath, 'w', newline='', encoding='utf-8') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerow(['No', 'Date Died', 'Name', 'Age', 'Address Block Found', 
                           'Notes', 'No Violent Criminal History', 'Surveillance Camera', 'Case Closed'])
            for row in table_data:
                writer.writerow(row)
        print(f"CSV file '{filepath}' created successfully!")
        print(f"Extracted {len(table_data)} rows with 9 columns")
        return True
    except Exception as e:
        print(f"Error saving to CSV: {e}")
        return False

def main(url_lst=None):
    """
    Main function to extract table from URLs.
    """
    if url_lst is None: 
        print("No URL provided.")
        return

    for idx, url in enumerate(url_lst):
        print(f"\n{'='*60}")
        print(f"Processing URL {idx+1}/{len(url_lst)}: {url}")
        print(f"{'='*60}")

        table_data = fetch_and_extract_table(url)

        if table_data and len(table_data) > 0:
            print(f"Successfully extracted {len(table_data)} rows")

            website_prefix = get_website_prefix(url)
            filename = 'chamspage_table1.csv'
            
            if save_to_csv(table_data, filename):
                print(f"✅ Data successfully exported to '{filename}'")
                
                print(f"\n📊 Preview of first 5 rows:")
                for i, row in enumerate(table_data[:5]):
                    if len(row) >= 6:
                        print(f"  {i+1}. No: {row[0]:>3} | Date: {row[1]:>10} | Name: {row[2][:25]:25} | Age: {row[3]:>3} | Location: {row[4][:30]}")
                    else:
                        print(f"  {i+1}. {row}")
            else:
                print(f"❌ Failed to save data")
        else:
            print(f"No table data found on this page")

    print(f"\n{'='*60}")
    print(f"✅ Data extraction complete!")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    if len(sys.argv) > 1: 
        url = sys.argv[1]
        main([url])
    else:
        print("No arguments provided, using default Blogspot URL...")
        main(["https://chamspage.blogspot.com/"])