#!/usr/bin/env python3
"""
Baltimore Homicide Data Scraper
Extracts homicide data from Cham's Baltimore Homicide Tracking Blog
"""

import csv
import time
import re
from pathlib import Path
import requests
from bs4 import BeautifulSoup


def smart_csv_parse(line):
    """
    Intelligently parse a CSV line with complex quoted fields.
    Handles nested quotes and commas within fields.
    """
    fields = []
    current_field = []
    in_quotes = False
    i = 0
    
    while i < len(line):
        char = line[i]
        
        if char == '"':
            # Check if this is an escaped quote (doubled)
            if i + 1 < len(line) and line[i + 1] == '"':
                if in_quotes:
                    current_field.append('"')
                    i += 2  # Skip both quotes
                    continue
                else:
                    current_field.append('"')
                    i += 1
                    continue
            else:
                # Toggle quote state
                in_quotes = not in_quotes
                i += 1
                continue
        
        elif char == ',' and not in_quotes:
            # Field boundary
            fields.append(''.join(current_field).strip())
            current_field = []
            i += 1
            continue
        
        else:
            current_field.append(char)
            i += 1
    
    # Add last field
    if current_field or line.endswith(','):
        fields.append(''.join(current_field).strip())
    
    return fields


def extract_from_text(text, year):
    """
    Extract homicide records from raw text content.
    This is the primary extraction method for blogspot pages.
    """
    records = []
    lines = text.split('\n')
    
    for line_num, line in enumerate(lines, 1):
        line = line.strip()
        
        # Skip empty lines
        if not line or len(line) < 20:
            continue
        
        # Pattern: starts with 1-3 digits, comma, date (MM/DD/YY or MM/DD/YYYY)
        # Example: 001,01/01/21,Name,Age,Address,...
        pattern = r'^(\d{1,3})\s*,\s*(\d{1,2}/\d{1,2}/\d{2,4})\s*,'
        
        if re.match(pattern, line):
            try:
                # Parse the CSV line
                fields = smart_csv_parse(line)
                
                # Need at least: No, Date, Name, Age, Address (5 fields minimum)
                if len(fields) >= 5:
                    # Ensure we have exactly 9 fields (pad if needed)
                    while len(fields) < 9:
                        fields.append('')
                    
                    # Take only first 9 fields
                    fields = fields[:9]
                    
                    # Clean each field
                    cleaned = []
                    for field in fields:
                        # Remove extra whitespace
                        clean = ' '.join(field.split())
                        # Remove leading/trailing quotes if present
                        clean = clean.strip('"\'')
                        # Handle special characters
                        clean = clean.replace('\r', '').replace('\n', ' ')
                        cleaned.append(clean)
                    
                    # Add year as 10th field
                    cleaned.append(str(year))
                    
                    # Validate the record has reasonable data
                    if cleaned[0] and cleaned[1]:  # Must have No and Date
                        records.append(cleaned)
                        
            except Exception as e:
                # Skip problematic lines
                continue
    
    return records


def extract_from_tables(soup, year):
    """
    Extract records from HTML tables (fallback method).
    """
    records = []
    tables = soup.find_all('table')
    
    for table in tables:
        rows = table.find_all('tr')
        
        for row in rows:
            cells = row.find_all(['td', 'th'])
            
            if len(cells) < 5:
                continue
            
            # Extract text from each cell
            row_data = []
            for cell in cells:
                text = cell.get_text(separator=' ', strip=True)
                text = ' '.join(text.split())  # Normalize whitespace
                row_data.append(text)
            
            # Skip if first cell looks like a header
            first_cell = row_data[0].lower()
            if any(x in first_cell for x in ['no.', 'no', '#', 'number']):
                continue
            
            # Check if first cell is a valid homicide number
            clean_num = row_data[0].strip().replace(',', '').replace('.', '')
            if not clean_num.isdigit():
                continue
            
            # Pad or trim to 9 fields
            while len(row_data) < 9:
                row_data.append('')
            row_data = row_data[:9]
            
            # Add year
            row_data.append(str(year))
            records.append(row_data)
    
    return records


def extract_homicide_records(soup, year):
    """
    Main extraction function - tries multiple strategies.
    """
    all_records = []
    
    # Strategy 1: Extract from blog post body (PRIMARY)
    post_containers = soup.find_all(['div', 'article'], 
                                   class_=re.compile(r'post-body|entry-content|blog-post|post-content|entry'))
    
    for container in post_containers:
        text = container.get_text('\n')
        records = extract_from_text(text, year)
        if records:
            all_records.extend(records)
    
    # Strategy 2: If nothing found, try whole page text
    if not all_records:
        full_text = soup.get_text('\n')
        all_records = extract_from_text(full_text, year)
    
    # Strategy 3: Look in HTML tables (fallback)
    if not all_records:
        all_records = extract_from_tables(soup, year)
    
    # Strategy 4: Check pre-formatted blocks
    if not all_records:
        for pre in soup.find_all('pre'):
            text = pre.get_text()
            records = extract_from_text(text, year)
            if records:
                all_records.extend(records)
    
    # Remove duplicates while preserving order
    seen = set()
    unique_records = []
    for record in all_records:
        # Use first 3 fields as unique identifier (No, Date, Name)
        key = tuple(record[:3])
        if key not in seen:
            seen.add(key)
            unique_records.append(record)
    
    return unique_records


def scrape_year(url, year):
    """Scrape homicide data for a specific year."""
    print(f"\n{'='*70}")
    print(f"Scraping year: {year}")
    print(f"URL: {url}")
    print('='*70)
    
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate',
            'Connection': 'keep-alive',
        }
        
        print(f"Fetching page...")
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()
        
        # Detect and set proper encoding
        if response.encoding is None or response.encoding.lower() in ['iso-8859-1', 'windows-1252']:
            response.encoding = 'utf-8'
        
        print(f"✓ Page downloaded ({len(response.content):,} bytes)")
        
        # Parse HTML
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Remove non-content elements
        for element in soup(['script', 'style', 'header', 'footer', 'nav', 'aside', 'iframe']):
            element.decompose()
        
        # Extract records
        print(f"Extracting records...")
        records = extract_homicide_records(soup, year)
        
        if records:
            print(f"✓ Extracted {len(records)} records for {year}")
            
            # Show sample of first and last record
            print(f"\n  First record:")
            print(f"    No: {records[0][0]}")
            print(f"    Date: {records[0][1]}")
            print(f"    Name: {records[0][2][:30]}..." if len(records[0][2]) > 30 else f"    Name: {records[0][2]}")
            print(f"    Age: {records[0][3]}")
            
            if len(records) > 1:
                print(f"\n  Last record:")
                print(f"    No: {records[-1][0]}")
                print(f"    Date: {records[-1][1]}")
                print(f"    Name: {records[-1][2][:30]}..." if len(records[-1][2]) > 30 else f"    Name: {records[-1][2]}")
                print(f"    Age: {records[-1][3]}")
        else:
            print(f"⚠ WARNING: No records found for {year}")
            
            # Save debug information
            debug_dir = Path(__file__).parent
            
            # Save HTML
            html_file = debug_dir / f"debug_{year}.html"
            with open(html_file, 'w', encoding='utf-8') as f:
                f.write(soup.prettify()[:20000])  # First 20K chars
            print(f"  Debug HTML saved: {html_file}")
            
            # Save plain text
            text_file = debug_dir / f"debug_{year}.txt"
            text = soup.get_text()
            with open(text_file, 'w', encoding='utf-8') as f:
                f.write(text[:10000])  # First 10K chars
            print(f"  Debug text saved: {text_file}")
            
            # Check for common patterns in text
            if '001' in text and '01/' in text:
                print(f"  ℹ Data patterns found in text - may need parsing adjustment")
                # Save a section with data
                sample_file = debug_dir / f"debug_{year}_sample.txt"
                # Find where the data starts
                match = re.search(r'\d{3},\d{1,2}/\d{1,2}/\d{2}', text)
                if match:
                    start = max(0, match.start() - 100)
                    end = min(len(text), match.end() + 500)
                    with open(sample_file, 'w', encoding='utf-8') as f:
                        f.write(text[start:end])
                    print(f"  Sample data section saved: {sample_file}")
        
        return records
        
    except requests.exceptions.Timeout:
        print(f"✗ Timeout error for {year} - server took too long to respond")
        return []
    except requests.exceptions.ConnectionError:
        print(f"✗ Connection error for {year} - check internet connection")
        return []
    except requests.exceptions.HTTPError as e:
        print(f"✗ HTTP error for {year}: {e.response.status_code}")
        if e.response.status_code == 404:
            print(f"  Page not found - URL may be incorrect")
        elif e.response.status_code == 403:
            print(f"  Access forbidden - may be blocked")
        return []
    except Exception as e:
        print(f"✗ Unexpected error for {year}: {e}")
        import traceback
        print("\nFull error trace:")
        traceback.print_exc()
        return []


def main():
    """Main function to scrape all years and save to CSV."""
    print("\n" + "="*70)
    print("BALTIMORE HOMICIDE DATA SCRAPER")
    print("="*70)
    
    urls = [
        {'year': 2021, 'url': 'http://chamspage.blogspot.com/2021/'},
        {'year': 2022, 'url': 'http://chamspage.blogspot.com/2022/01/2022-baltimore-city-homicides-list.html'},
        {'year': 2023, 'url': 'http://chamspage.blogspot.com/2023/01/2023-baltimore-city-homicides-list.html'},
        {'year': 2024, 'url': 'http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html'},
        {'year': 2025, 'url': 'http://chamspage.blogspot.com/2025/01/2025-baltimore-city-homicide-list.html'}
    ]
    
    all_data = []
    year_counts = {}
    
    for item in urls:
        print(f"\n{'#'*70}")
        print(f"PROCESSING YEAR {item['year']}")
        print('#'*70)
        
        year_data = scrape_year(item['url'], item['year'])
        
        if year_data:
            all_data.extend(year_data)
            year_counts[item['year']] = len(year_data)
        else:
            year_counts[item['year']] = 0
            print(f"⚠ WARNING: No data scraped for {item['year']}")
        
        # Be polite to the server
        time.sleep(2)
    
    output_file = Path(__file__).resolve().parent / "homicide_data.csv"
    
    if all_data:
        print(f"\n{'='*70}")
        print("WRITING TO CSV")
        print('='*70)
        
        with output_file.open('w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            
            # Write header
            writer.writerow([
                'No', 'DateDied', 'Name', 'Age', 'Address', 
                'Notes', 'NoViolentHistory', 'SurveillanceCamera', 
                'CaseClosed', 'Year'
            ])
            
            # Write all data rows
            writer.writerows(all_data)
        
        print("\n" + "="*70)
        print("✓ SCRAPING COMPLETE!")
        print("="*70)
        print(f"Total records scraped: {len(all_data)}")
        print(f"\nBreakdown by year:")
        for year in sorted(year_counts.keys()):
            count = year_counts[year]
            status = "✓" if count > 0 else "✗"
            print(f"  {status} {year}: {count:4d} records")
        
        print(f"\nOutput file: {output_file}")
        
        # Verify file was written
        if output_file.exists():
            file_size = output_file.stat().st_size
            print(f"File size: {file_size:,} bytes")
            
            # Count lines in file
            with output_file.open('r') as f:
                line_count = sum(1 for _ in f)
            print(f"Total lines in CSV (including header): {line_count}")
            print(f"Data rows: {line_count - 1}")
        
        print("\n✓ Data scraping successful!")
        
    else:
        print("\n" + "="*70)
        print("✗ ERROR: NO DATA SCRAPED FROM ANY YEAR!")
        print("="*70)
        print("\nPossible reasons:")
        print("  1. Network connectivity issues")
        print("  2. Website structure has changed")
        print("  3. Being blocked by the server")
        print("  4. Data format on website is different than expected")
        print("\nCheck the debug_*.txt files created to see what was retrieved.")
        print("\nCreating minimal sample data so app doesn't crash...")
        
        # Create sample data based on the expected format
        sample_data = [
            ['001', '01/01/21', 'Sample Record 1', '35', '1200 North Stricker Street', 
             'Sample shooting victim', 'None', '1 camera', 'Closed', '2021'],
            ['002', '01/02/21', 'Sample Record 2', '28', '2500 Reisterstown Road', 
             'Sample shooting victim', '', '', '', '2021'],
            ['003', '01/03/21', 'Sample Record 3', '42', '300 East 23rd Street', 
             'Sample victim', 'None', '2 cameras', 'Closed', '2021'],
        ]
        
        with output_file.open('w', encoding='utf-8', newline='') as f:
            writer = csv.writer(f)
            writer.writerow([
                'No', 'DateDied', 'Name', 'Age', 'Address', 
                'Notes', 'NoViolentHistory', 'SurveillanceCamera', 
                'CaseClosed', 'Year'
            ])
            writer.writerows(sample_data)
        
        print(f"Sample data created: {output_file}")
        print("\n⚠ WARNING: Dashboard will run with LIMITED SAMPLE DATA only!")


if __name__ == "__main__":
    main()