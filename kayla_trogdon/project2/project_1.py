import csv
import requests
from html.parser import HTMLParser
from urllib.parse import urljoin

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

def save_to_csv(table_data, filename):
    """
    Save the extracted table data to a CSV file.
    """
    try:
        with open(filename, 'w', newline='', encoding='utf-8') as csv_file:
            writer = csv.writer(csv_file)
            for row in table_data:
                writer.writerow(row)
        
        print(f"CSV file '{filename}' created successfully!")
        print(f"Extracted {len(table_data)} rows")
        return True
        
    except Exception as e:
        print(f"Error saving to CSV: {e}")
        return False

def main():
    # Wikipedia URL for programming languages comparison
    url = "https://en.wikipedia.org/wiki/Comparison_of_programming_languages"
    
    # Extract data from all tables
    all_table_data = fetch_and_extract_all_tables(url)
    
    if all_table_data:
        print(f"\nSuccessfully extracted data from {len(all_table_data)} tables")
        
        # Loop through each table's data and save it to a unique CSV file
        for i, table in enumerate(all_table_data):
            filename = f'comparison_table_{i+1}.csv'
            print(f"\nProcessing table {i+1}...")
            if save_to_csv(table, filename):
                print(f"✅ Table {i+1} data successfully exported to '{filename}'")
            else:
                print(f"❌ Failed to save data for table {i+1}")
    else:
        print("\n❌ Failed to extract any table data")

if __name__ == "__main__":
    main()