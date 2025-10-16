import sys
import os
import csv
import requests
from html.parser import HTMLParser
from urllib.parse import urljoin, urlparse

class WikiTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_table = False
        self.in_th = False
        self.in_td = False
        self.current_row = []
        self.all_table_data = [] # A list to hold data for ALL tables
        self.current_table_data = [] # A list to hold data for the current table being parsed

    def handle_starttag(self, tag, attrs):
        if tag == 'table':
            self.in_table = True
            self.current_table_data = [] # Reset for a new table
        elif tag == 'th' and self.in_table:
            self.in_th = True
        elif tag == 'td' and self.in_table:
            self.in_td = True
            
    def handle_endtag(self, tag):
        if tag == 'table':
            self.in_table = False
            # Append the completed table's data to the main list
            if self.current_table_data:
                self.all_table_data.append(self.current_table_data)
        elif tag == 'th':
            self.in_th = False
        elif tag == 'td':
            self.in_td = False
        elif tag == 'tr' and self.in_table:
            if self.current_row:
                self.current_table_data.append(self.current_row)
                self.current_row = []
                
    def handle_data(self, data):
        if self.in_th or self.in_td:
            cleaned_data = ' '.join(data.strip().split())
            if cleaned_data:
                self.current_row.append(cleaned_data)

def fetch_and_extract_all_tables(url):
    """
    Fetch the Wikipedia page and extract all tables.
    """
    try:
        print("Fetching Wikipedia page...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        print(f"Page fetched successfully! Content length: {len(response.text)} characters")
        
        print("Parsing HTML content and extracting all tables...")
        parser = WikiTableParser()
        parser.feed(response.text)
        
        return parser.all_table_data
        
    except requests.RequestException as e:
        print(f"Error fetching the webpage: {e}")
        return None
    except Exception as e:
        print(f"Error parsing HTML: {e}")
        return None

def get_website_prefix(url):
    """
    Generate a short prefix from the URL for naming CSV files.
    """
    domain = urlparse(url).netloc
    
    # Remove common prefixes and suffixes
    domain = domain.replace('www.', '').replace('.com', '').replace('.org', '').replace('.net', '')
    
    # Handle special cases for cleaner prefixes
    if 'wikipedia' in domain:
        # Extract the page name from Wikipedia URLs
        path_parts = urlparse(url).path.split('/')
        if len(path_parts) > 2 and path_parts[-1]:
            page_name = path_parts[-1]
            # Take first letter of each word, max 3 letters
            words = page_name.replace('_', ' ').split()
            prefix = ''.join(word[0] for word in words[:3] if word)
            return prefix.lower()
        return 'wiki'
    elif 'tiobe' in domain:
        return 'tiobe'
    elif 'github' in domain:
        return 'github'
    else:
        # For other domains, take first 3-5 characters
        return domain.split('.')[0][:5].lower()

def save_to_csv(table_data, filepath):
    import os
    # Print the path for debugging
    print(f"Attempting to save to: {filepath}")
    # Try to create parent directory with permissions
    try:
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
    except Exception as dir_e:
        print(f"Error creating directory: {dir_e}")
        return False
    try:
        with open(filepath, 'w', newline='', encoding='utf-8') as csv_file:
            writer = csv.writer(csv_file)
            for row in table_data:
                writer.writerow(row)
        print(f"CSV file '{filepath}' created successfully!")
        print(f"Extracted {len(table_data)} rows")
        return True
    except Exception as e:
        print(f"Error saving to CSV: {e}")
        return False

def main(url_lst=None):
    # Wikipedia URL for programming languages comparison
    if url_lst is None: 
        print("No URL provided.")
        return
    global_table_counter = 1
    # Get output directory from environment or default
    output_base = os.environ.get("OUTPUT_DIR", "website_tables")
    os.makedirs(output_base, exist_ok=True)

    # Process each URL
    for idx, url in enumerate(url_lst):
        print(f"\n{'='*60}")
        print(f"Processing URL {idx+1}/{len(url_lst)}: {url}")
        print(f"{'='*60}")

        all_table_data = fetch_and_extract_all_tables(url)

        if all_table_data:
            print(f"Successfully extracted data from {len(all_table_data)} tables")

            # Get website prefix for this URL
            website_prefix = get_website_prefix(url)

            # Create site-specific output directory
            site_dir = os.path.join(output_base, f"site_{idx+1}")
            os.makedirs(site_dir, exist_ok=True)

            # Loop through each table's data and save it with website prefix
            for i, table in enumerate(all_table_data):
                filename = os.path.join(site_dir, f'{website_prefix}_table{global_table_counter}.csv')
                print(f"\nProcessing table {i+1}...")
                if save_to_csv(table, filename):
                    print(f"✅ Table {i+1} data successfully exported to '{filename}'")
                    global_table_counter += 1
                else:
                    print(f"❌ Failed to save data for table {i+1}")
        else:
            print(f"No tables found on this page")

    print(f"\n{'='*60}")
    print(f"SUMMARY: Successfully saved {global_table_counter - 1} tables total")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    if len(sys.argv) > 1: 

        url = sys.argv[1]
        main([url])
    elif os.getenv('DEFAULT_URLS'): 
        print("THIS THE HARDCODING PRINTING")
        a_website = "https://en.wikipedia.org/wiki/Programming_languages_used_in_most_popular_websites"
        b_website = "https://www.tiobe.com/tiobe-index/"
        c_website = "https://github.com/quambene/pl-comparison"
        web_lst = [a_website, b_website, c_website]
        main(web_lst)