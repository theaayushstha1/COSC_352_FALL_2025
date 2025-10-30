#!/usr/bin/env python3
import sys
import requests
from bs4 import BeautifulSoup
import pandas as pd
import os

def scrape_tables(url, output_file):
    """Scrape HTML tables from a URL and save to CSV"""
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        tables = soup.find_all('table')
        
        if not tables:
            print(f"No tables found on {url}")
            return False
        
        print(f"Found {len(tables)} table(s) on {url}")
        
        all_data = []
        
        for i, table in enumerate(tables):
            try:
                df = pd.read_html(str(table))[0]
                df.insert(0, 'Table_Number', i + 1)
                all_data.append(df)
            except Exception as e:
                print(f"Warning: Could not parse table {i+1}: {e}")
        
        if not all_data:
            print(f"Could not parse any tables from {url}")
            return False
        
        combined_df = pd.concat(all_data, ignore_index=True)
        os.makedirs(os.path.dirname(output_file), exist_ok=True)
        combined_df.to_csv(output_file, index=False)
        print(f"Saved {len(combined_df)} rows to {output_file}")
        
        return True
        
    except Exception as e:
        print(f"Error processing {url}: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python scraper.py <url> <output_file>")
        sys.exit(1)
    
    url = sys.argv[1]
    output_file = sys.argv[2]
    
    success = scrape_tables(url, output_file)
    sys.exit(0 if success else 1)
