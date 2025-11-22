import sys
import pandas as pd
from bs4 import BeautifulSoup
import os

def parse_html_tables(html_file, output_prefix):
    """Parse HTML tables and save as CSV files"""
    try:
        with open(html_file, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        soup = BeautifulSoup(html_content, 'html.parser')
        tables = soup.find_all('table')
        
        if not tables:
            print(f"No tables found in {html_file}")
            return 0
        
        csv_files = []
        for idx, table in enumerate(tables):
            # Parse table with pandas
            df = pd.read_html(str(table))[0]
            
            # Generate output filename
            csv_filename = f"{output_prefix}_table_{idx+1}.csv"
            df.to_csv(csv_filename, index=False)
            csv_files.append(csv_filename)
            print(f"Created: {csv_filename} ({len(df)} rows)")
        
        return len(csv_files)
    
    except Exception as e:
        print(f"Error processing {html_file}: {str(e)}")
        return 0

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python table_parser.py <html_file> <output_prefix>")
        sys.exit(1)
    
    html_file = sys.argv[1]
    output_prefix = sys.argv[2]
    
    count = parse_html_tables(html_file, output_prefix)
    print(f"Total tables processed: {count}")
