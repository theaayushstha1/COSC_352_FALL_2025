#!/usr/bin/env python3
"""
Extract tables from a URL, save them as separate CSV files, and save the HTML.
Usage: python extract_tables.py <URL> [output_prefix]
"""

import sys
import os
import argparse
import pandas as pd
import requests
from urllib.parse import urlparse
from bs4 import BeautifulSoup

def extract_and_save_tables(url, output_prefix=None, output_dir=None):
    """
    Extract all tables from a URL, save them as separate CSV files, and save the HTML.
    
    Args:
        url: The URL to extract tables from
        output_prefix: Optional prefix for output files (default: derive from URL)
        output_dir: Optional directory to save files (default: current directory)
    """
    try:
        # Set up headers to avoid 403 errors
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        
        # Make the request
        print(f"Fetching content from: {url}")
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        # Get the HTML content
        html_content = response.text
        
        # Determine base filename
        if output_prefix:
            base_name = output_prefix
        else:
            # Generate from URL
            parsed_url = urlparse(url)
            page_name = parsed_url.path.split('/')[-1] or 'page'
            base_name = page_name.replace('.html', '').replace('.htm', '').replace('.php', '')
            base_name = base_name.replace('/', '_').replace('\\', '_')
            
            if not base_name or base_name == 'wiki':
                base_name = parsed_url.netloc.replace('.', '_') or 'page'
        
        # Create output directory if specified
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        # Save HTML file
        html_filename = f"{base_name}.html"
        if output_dir:
            html_filepath = os.path.join(output_dir, html_filename)
        else:
            html_filepath = html_filename
        
        with open(html_filepath, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"✓ Saved HTML: {html_filepath}")
        print(f"  Size: {len(html_content):,} bytes\n")
        
        # Read tables from HTML content
        tables = pd.read_html(html_content)
        
        if not tables:
            print("No tables found in the HTML.", file=sys.stderr)
            return
        
        print(f"Found {len(tables)} table(s)\n")
        
        # Save each table
        saved_files = []
        for i, table in enumerate(tables, 1):
            # Clean up the table
            table = table.dropna(how='all', axis=1)
            
            # Generate filename
            csv_filename = f"{base_name}_{i}.csv"
            if output_dir:
                csv_filepath = os.path.join(output_dir, csv_filename)
            else:
                csv_filepath = csv_filename
            
            # Save to CSV
            table.to_csv(csv_filepath, index=False)
            saved_files.append(csv_filepath)
            
            # Print info
            rows, cols = table.shape
            print(f"Table {i}: {csv_filepath}")
            print(f"  Size: {rows} rows × {cols} columns")
            
            # Show column preview
            col_preview = ', '.join(str(col) for col in table.columns[:5])
            if len(table.columns) > 5:
                col_preview += f' ... ({len(table.columns)} total)'
            print(f"  Columns: {col_preview}")
            print()
        
        print(f"✓ Successfully saved {len(saved_files)} CSV file(s) and 1 HTML file")
        
        # Optionally, print some HTML statistics
        soup = BeautifulSoup(html_content, 'html.parser')
        title = soup.find('title')
        if title:
            print(f"\nPage title: {title.string}")
            
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            print(f"Error: Access forbidden (403). The website is blocking automated requests.", file=sys.stderr)
        else:
            print(f"HTTP Error {e.response.status_code}: {e}", file=sys.stderr)
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"Error accessing URL: {e}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: No tables found or unable to parse tables from {url}", file=sys.stderr)
        print(f"Details: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error processing content: {e}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Extract tables from a URL, save as CSV files, and save the HTML',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Examples:
  python extract_tables.py https://en.wikipedia.org/wiki/List_of_countries_by_population
    Creates: List_of_countries_by_population.html
             List_of_countries_by_population_1.csv
             List_of_countries_by_population_2.csv
             ...

  python extract_tables.py https://example.com/data.html --prefix mydata
    Creates: mydata.html
             mydata_1.csv
             mydata_2.csv
             ...

  python extract_tables.py https://example.com/data.html --dir output/
    Creates files in output/ directory
        '''
    )
    
    parser.add_argument('url', help='URL to extract tables from')
    parser.add_argument('--prefix', '-p', help='Prefix for output files (default: derive from URL)')
    parser.add_argument('--dir', '-d', help='Directory to save files (default: current directory)')
    
    args = parser.parse_args()
    
    url = args.url
    
    # Validate and fix URL format
    if not url.startswith(('http://', 'https://')):
        if 'wiki/' in url or url.startswith('ki/'):
            if url.startswith('ki/'):
                url = 'https://en.wikipedia.org/wi' + url
            else:
                url = 'https://en.wikipedia.org/' + url
            print(f"Assuming Wikipedia URL: {url}\n")
        else:
            print("Error: URL must start with http:// or https://", file=sys.stderr)
            sys.exit(1)
    
    extract_and_save_tables(url, args.prefix, args.dir)

if __name__ == "__main__":
    main()