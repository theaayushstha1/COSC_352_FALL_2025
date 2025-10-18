#!/usr/bin/env python3
"""
Extract tables from a URL or local HTML file, save them as separate CSV files, and save the HTML.
Usage: python extract_tables.py <URL_or_file> [options]
"""

import sys
import os
import argparse
import pandas as pd
import requests
from urllib.parse import urlparse, urljoin
from bs4 import BeautifulSoup
from datetime import datetime
from pathlib import Path

def is_url(string):
    """Check if string is a URL."""
    return string.startswith(('http://', 'https://', 'ftp://'))

def is_file(string):
    """Check if string is an existing file."""
    return os.path.isfile(string)

def read_content(source):
    """
    Read content from either a URL or a local file.
    
    Args:
        source: URL string or file path
        
    Returns:
        tuple: (content, source_type, base_url_or_path)
    """
    if is_url(source):
        # Handle URL
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
            'Upgrade-Insecure-Requests': '1'
        }
        
        response = requests.get(source, headers=headers)
        response.raise_for_status()
        return response.text, 'url', source
        
    elif is_file(source):
        # Handle local file
        with open(source, 'r', encoding='utf-8') as f:
            content = f.read()
        return content, 'file', os.path.abspath(source)
        
    else:
        # Try to interpret as Wikipedia path or partial URL
        if 'wiki/' in source or source.startswith('ki/'):
            if source.startswith('ki/'):
                url = 'https://en.wikipedia.org/wi' + source
            else:
                url = 'https://en.wikipedia.org/' + source
            print(f"Assuming Wikipedia URL: {url}\n")
            return read_content(url)
        else:
            raise ValueError(f"'{source}' is neither a valid URL nor an existing file")

def prettify_html(html_content, base_url=None):
    """
    Optionally prettify HTML and fix relative URLs.
    
    Args:
        html_content: Raw HTML content
        base_url: Base URL for resolving relative links (if from URL)
    
    Returns:
        Prettified HTML with fixed URLs
    """
    soup = BeautifulSoup(html_content, 'html.parser')
    
    if base_url:
        # Fix relative URLs in links
        for tag in soup.find_all(['a', 'link']):
            if tag.get('href'):
                tag['href'] = urljoin(base_url, tag['href'])
        
        # Fix relative URLs in images and scripts
        for tag in soup.find_all(['img', 'script']):
            if tag.get('src'):
                tag['src'] = urljoin(base_url, tag['src'])
    
    return soup.prettify()

def get_base_name(source, source_type, output_prefix=None):
    """
    Determine the base name for output files.
    
    Args:
        source: Original source (URL or file path)
        source_type: 'url' or 'file'
        output_prefix: Optional user-specified prefix
        
    Returns:
        Base name for output files
    """
    if output_prefix:
        return output_prefix
    
    if source_type == 'url':
        parsed_url = urlparse(source)
        page_name = parsed_url.path.split('/')[-1] or 'page'
        base_name = page_name.replace('.html', '').replace('.htm', '').replace('.php', '')
        base_name = base_name.replace('/', '_').replace('\\', '_')
        
        if not base_name or base_name == 'wiki':
            domain_parts = parsed_url.netloc.replace('www.', '').split('.')
            base_name = domain_parts[0] if domain_parts else 'page'
    else:  # file
        # Use filename without extension
        base_name = Path(source).stem
    
    return base_name

def extract_and_save_tables(source, output_prefix=None, output_dir=None, 
                           prettify=False, stats=False, save_html=True):
    """
    Extract all tables from a URL or file, save them as separate CSV files, and optionally save the HTML.
    
    Args:
        source: URL or file path to extract tables from
        output_prefix: Optional prefix for output files
        output_dir: Optional directory to save files
        prettify: Whether to prettify the HTML output
        stats: Whether to show detailed statistics
        save_html: Whether to save the HTML file (default True, False if input is local file)
    """
    try:
        # Read content from source
        print(f"Reading content from: {source}")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        html_content, source_type, source_path = read_content(source)
        
        print(f"Source type: {source_type.upper()}")
        if source_type == 'file':
            print(f"File path: {source_path}")
            file_size = os.path.getsize(source)
            print(f"File size: {file_size:,} bytes")
        print()
        
        # Determine base filename
        base_name = get_base_name(source_path, source_type, output_prefix)
        
        # Create output directory if specified
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        # Save HTML file (skip if input is already a local file unless explicitly requested)
        if save_html and not (source_type == 'file' and not output_dir and not output_prefix):
            # Process HTML if prettifying
            if prettify:
                base_url = source_path if source_type == 'url' else None
                html_to_save = prettify_html(html_content, base_url)
            else:
                html_to_save = html_content
            
            # Save HTML file
            html_filename = f"{base_name}.html"
            if output_dir:
                html_filepath = os.path.join(output_dir, html_filename)
            else:
                html_filepath = html_filename
            
            # Check if we're about to overwrite the input file
            if source_type == 'file' and os.path.abspath(html_filepath) == source_path:
                html_filename = f"{base_name}_copy.html"
                html_filepath = os.path.join(output_dir, html_filename) if output_dir else html_filename
                print(f"⚠ Avoiding overwrite of input file, saving as: {html_filename}")
            
            with open(html_filepath, 'w', encoding='utf-8') as f:
                f.write(html_to_save)
            
            print(f"✓ Saved HTML: {html_filepath}")
            print(f"  Size: {len(html_to_save):,} bytes")
        elif source_type == 'file' and not save_html:
            print(f"ℹ Skipping HTML save (input is already a local file)")
        
        # Parse HTML for statistics if requested
        if stats:
            soup = BeautifulSoup(html_content, 'html.parser')
            title = soup.find('title')
            if title:
                print(f"  Title: {title.string}")
            
            # Count various elements
            print(f"  Elements: {len(soup.find_all('table'))} tables, "
                  f"{len(soup.find_all('img'))} images, "
                  f"{len(soup.find_all('a'))} links")
        
        print()
        
        # Read tables from HTML content
        try:
            tables = pd.read_html(html_content)
        except ValueError:
            tables = []
        
        if not tables:
            print("No tables found in the HTML.")
            return
        
        print(f"Found {len(tables)} table(s)\n")
        
        # Save each table
        saved_files = []
        total_rows = 0
        
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
            total_rows += rows
            print(f"Table {i}: {csv_filepath}")
            print(f"  Size: {rows:,} rows × {cols} columns")
            
            # Show column preview
            col_preview = ', '.join(str(col)[:30] for col in table.columns[:5])
            if len(table.columns) > 5:
                col_preview += f' ... ({len(table.columns)} total)'
            print(f"  Columns: {col_preview}")
            
            # Show data types if stats requested
            if stats:
                dtypes = table.dtypes.value_counts()
                dtype_str = ', '.join([f"{dt}: {count}" for dt, count in dtypes.items()])
                print(f"  Types: {dtype_str}")
            
            # Show first few rows if stats requested
            if stats and rows > 0:
                print(f"  First row: {', '.join(str(v)[:20] for v in table.iloc[0].values[:5])}")
            
            print()
        
        # Summary
        print("=" * 50)
        print(f"✓ Successfully processed:")
        print(f"  Source: {source_type.upper()} - {source}")
        if save_html and not (source_type == 'file' and not output_dir and not output_prefix):
            print(f"  Saved: 1 HTML file ({len(html_content):,} bytes)")
        print(f"  Saved: {len(saved_files)} CSV file(s) ({total_rows:,} total rows)")
        
        if output_dir:
            print(f"\nAll files saved to: {os.path.abspath(output_dir)}")
            
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 403:
            print(f"Error: Access forbidden (403). The website is blocking automated requests.", file=sys.stderr)
        else:
            print(f"HTTP Error {e.response.status_code}: {e}", file=sys.stderr)
        sys.exit(1)
    except requests.exceptions.RequestException as e:
        print(f"Error accessing URL: {e}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"Error: File not found - {source}", file=sys.stderr)
        sys.exit(1)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error processing content: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(
        description='Extract tables from a URL or local HTML file, save as CSV files, and optionally save the HTML',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Input can be:
  - Full URL: https://example.com/page.html
  - Local file: /path/to/file.html or file.html
  - Wikipedia shorthand: wiki/Article_name

Output files:
  - HTML file: <prefix>.html (skipped if input is local file)
  - CSV files: <prefix>_1.csv, <prefix>_2.csv, etc.

Examples:
  # From URL
  python extract_tables.py https://en.wikipedia.org/wiki/List_of_countries_by_population
  
  # From local file
  python extract_tables.py downloaded_page.html
  python extract_tables.py /path/to/data.html --prefix mydata
  
  # Save to specific directory
  python extract_tables.py data.html --dir output/
  
  # With options
  python extract_tables.py https://example.com/data.html --prettify --stats
  
  # Force save HTML even from local file
  python extract_tables.py local.html --save-html --dir output/
        '''
    )
    
    parser.add_argument('source', help='URL or local HTML file to extract tables from')
    parser.add_argument('--prefix', '-p', help='Prefix for output files (default: derive from source)')
    parser.add_argument('--dir', '-d', help='Directory to save files (default: current directory)')
    parser.add_argument('--prettify', action='store_true', help='Prettify HTML and fix relative URLs')
    parser.add_argument('--stats', '-s', action='store_true', help='Show detailed statistics')
    parser.add_argument('--save-html', action='store_true', 
                       help='Force save HTML even when input is a local file')
    parser.add_argument('--no-html', action='store_true',
                       help='Do not save HTML file (only extract CSVs)')
    
    args = parser.parse_args()
    
    # Determine whether to save HTML
    save_html = True
    if args.no_html:
        save_html = False
    elif is_file(args.source) and not args.save_html:
        # Don't save HTML by default if input is a file (unless forced)
        save_html = False
    elif args.save_html:
        save_html = True
    
    extract_and_save_tables(
        args.source, 
        args.prefix, 
        args.dir, 
        args.prettify, 
        args.stats,
        save_html
    )

if __name__ == "__main__":
    main()