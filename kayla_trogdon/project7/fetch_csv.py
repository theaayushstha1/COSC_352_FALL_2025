import sys
import csv
from urllib.request import Request, urlopen
from html.parser import HTMLParser
from urllib.parse import urlparse
import re

# BeautifulSoup for fallback parsing
try:
    from bs4 import BeautifulSoup #NEW: wanting to a smoother route when it comes to reading the 5 URLs
    HAS_BEAUTIFULSOUP = True
except ImportError:
    HAS_BEAUTIFULSOUP = False
    print("⚠️  Warning: BeautifulSoup not installed. Fallback parser unavailable.")

class BlogspotTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_tr = False
        self.in_td = False
        self.in_th = False
        self.current_row = []
        self.all_table_data = []
        self.current_cell_data = []
        self.table_count = 0
        self.current_table_rows = 0

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.in_table = True
            self.table_count += 1
            self.current_table_rows = 0
        elif tag == 'tr' and self.in_table:
            self.in_tr = True
            self.current_row = []
        elif tag in ['td', 'th'] and self.in_table:
            if tag == 'td':
                self.in_td = True
            else:
                self.in_th = True
            self.current_cell_data = []
            
    def handle_endtag(self, tag):
        if tag == 'table':
            self.in_table = False
        elif tag == 'tr':
            self.in_tr = False
            
            if self.current_row and len(self.current_row) >= 2:
                first_col = self.current_row[0].strip()
                second_col = self.current_row[1].strip() if len(self.current_row) > 1 else ''
                
                is_valid = False
                
                # Check if looks like valid data
                if first_col.isdigit() or (first_col.startswith('0') and len(first_col) > 1 and first_col[1:].isdigit()):
                    is_valid = True
                
                if '/' in second_col and len(second_col) <= 12:
                    is_valid = True
                
                if first_col.replace('.', '').isdigit() and len(self.current_row) > 2:
                    if self.current_row[2].strip():
                        is_valid = True
                
                # Skip headers
                if first_col in ['No.', '#', 'No', 'Number'] or second_col in ['Date Died', 'Date']:
                    is_valid = False
                
                # Skip empty
                if not any(cell.strip() for cell in self.current_row[:3]):
                    is_valid = False
                
                if is_valid:
                    row_data = self.current_row[:9]
                    while len(row_data) < 9:
                        row_data.append('')
                    self.all_table_data.append(row_data)
                    self.current_table_rows += 1
            
            self.current_row = []
            
        elif tag == 'td':
            self.in_td = False
            cell_text = ' '.join(self.current_cell_data).strip()
            self.current_row.append(cell_text)
            self.current_cell_data = []
            
        elif tag == 'th':
            self.in_th = False
            cell_text = ' '.join(self.current_cell_data).strip()
            self.current_row.append(cell_text)
            self.current_cell_data = []
                
    def handle_data(self, data):
        if self.in_td or self.in_th:
            cleaned_data = ' '.join(data.strip().split())
            if cleaned_data:
                self.current_cell_data.append(cleaned_data)

def extractYear_URL(url): 
    """
    Extracts the year from the URL
    EX: "http://chamspage.blogspot.com/2021/" -> "2021"
    """
    year_match = re.search(r'/(\d{4})/', url)
    if year_match: 
        return year_match.group(1)
    return "UNKNOWN Year"

def fetch_and_extract_table(url):
    """
    Fetch the Blogspot page and extract the homicide table using native urllib.
    """
    try:
        print("Fetching Blogspot page...")
        
        req = Request(
            url, 
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
            }
        )
        
        response = urlopen(req)
        html_content = response.read().decode('utf-8')
        
        print(f"Page fetched successfully! Content length: {len(html_content)} characters")
        print("Parsing HTML table...")
        
        parser = BlogspotTableParser()
        parser.feed(html_content)
        
        print(f"Found {len(parser.all_table_data)} rows across {parser.table_count} tables")
        
        return parser.all_table_data
        
    except Exception as e:
        print(f"Error fetching/parsing the webpage: {e}")
        import traceback
        traceback.print_exc()
        return None

def fetch_with_beautifulsoup(url):
    """
    Fallback parser using BeautifulSoup for problematic pages.
    """
    if not HAS_BEAUTIFULSOUP:
        print("❌ BeautifulSoup not available. Cannot use fallback parser.")
        return None
    
    try: 
        print("Using BeautifulSoup fallback parser...")
        
        req = Request(
            url, 
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        )
        
        response = urlopen(req)
        html_content = response.read().decode('utf-8')
        
        soup = BeautifulSoup(html_content, 'html.parser')
        all_tables = soup.find_all('table')
        
        print(f"BeautifulSoup found {len(all_tables)} tables")
        
        all_data = []
        for table in all_tables:
            for row in table.find_all('tr'):
                cells = [cell.get_text(strip=True) for cell in row.find_all(['td', 'th'])]
                
                if len(cells) < 3:
                    continue
                    
                first_col = cells[0].strip()
                second_col = cells[1].strip() if len(cells) > 1 else ''
                
                # Skip headers
                if first_col in ['No.', '#', 'No', 'Number'] or second_col in ['Date Died', 'Date']:
                    continue
                
                # Accept if looks like data
                is_valid = False
                if first_col.isdigit() or (first_col.startswith('0') and len(first_col) > 1):
                    is_valid = True
                if '/' in second_col and len(second_col) <= 12:
                    is_valid = True
                
                if is_valid:
                    cells = cells[:9]
                    while len(cells) < 9:
                        cells.append('')
                    all_data.append(cells)
        
        print(f"BeautifulSoup extracted {len(all_data)} rows")
        return all_data
        
    except Exception as e:
        print(f"Error with BeautifulSoup parser: {e}")
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
                           'Notes', 'No Violent Criminal History', 'Surveillance Camera', 'Case Closed', 'Year'])
            for row in table_data:
                writer.writerow(row)
        print(f"CSV file '{filepath}' created successfully!")
        print(f"Extracted {len(table_data)} rows with 10 columns")
        return True
    except Exception as e:
        print(f"Error saving to CSV: {e}")
        return False

def main(url_lst=None):
    """
    Main function to extract table from multiple URLs and combine them.
    """
    if url_lst is None: 
        print("No URL provided.")
        return

    # Store ALL data from all years
    all_combined_data = []

    for idx, url in enumerate(url_lst):
        print(f"\n{'='*60}")
        print(f"Processing URL {idx+1}/{len(url_lst)}: {url}")
        print(f"{'='*60}")

        # Extract year from URL
        year = extractYear_URL(url)
        print(f"Extracting data from year: {year}")

        # Try native parser first
        table_data = fetch_and_extract_table(url)

        # If we got very few rows AND it's a problem year, use BeautifulSoup fallback
        if table_data and len(table_data) < 10 and year in ['2023', '2025']:
            print(f"\n⚠️  WARNING: Only {len(table_data)} rows found with native parser for {year}")
            print(f"🔄 Retrying with BeautifulSoup fallback...")
            bs_data = fetch_with_beautifulsoup(url)
            
            if bs_data and len(bs_data) > len(table_data):
                print(f"✅ BeautifulSoup found {len(bs_data)} rows (much better!)")
                table_data = bs_data
            else:
                print(f"⚠️  BeautifulSoup didn't improve results, using native parser data")

        if table_data and len(table_data) > 0:
            print(f"Successfully extracted {len(table_data)} rows for {year}")

            # Add year column to each row
            for row in table_data: 
                while len(row) < 9:  # Ensure 9 columns before adding 10th
                    row.append('')
                row.append(year)  # Add year as 10th column
                all_combined_data.append(row)
                
            print(f"✅ Added {len(table_data)} rows from {year} to combined dataset")
        else: 
            print(f"❌ No table data found for: {year}")

    # Save all combined data to ONE CSV file
    if all_combined_data: 
        combined_filename = 'baltimore_homicides_2021_2025.csv'

        if save_to_csv(all_combined_data, combined_filename): 
            print(f"\n{'='*60}")
            print(f"✅ SUCCESS! Combined data exported to '{combined_filename}'")
            print(f"Total records across all years: {len(all_combined_data)}")
            print(f"{'='*60}")

            # Show breakdown by year
            print(f"\n📊 Breakdown by Year:")
            year_count = {}
            for row in all_combined_data: 
                year = row[9]  # Year is 10th column (index 9)
                year_count[year] = year_count.get(year, 0) + 1
            
            for year in sorted(year_count.keys()): 
                print(f"  - {year}: {year_count[year]} records")
            
            print(f"\n📋 Preview of first 5 rows:")
            for i, row in enumerate(all_combined_data[:5]):
                if len(row) >= 10: 
                    print(f"  {i+1}. Year: {row[9]} | Date: {row[1]:>10} | Name: {row[2][:25]:25} | Location: {row[4][:30]}")
        else: 
            print(f"❌ Failed to save combined data")
    else:
        print(f"\n❌ No data collected from any URLs")

    print(f"\n{'='*60}")
    print(f"✅ Data extraction complete!")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    print("Using default URLs for Baltimore homicides (2021-2025)...")
    urls = [
        "http://chamspage.blogspot.com/2021/",
        "http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html",
        "http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html",
        "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html",
        "http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html"
    ]
    main(urls)