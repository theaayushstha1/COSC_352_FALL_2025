# This script extracts HTML tables from a file and writes them as CSVs to the output directory.
# Usage: python king.py input.html --out output_dir
import sys
import os
import pandas as pd
from bs4 import BeautifulSoup

if len(sys.argv) < 3:
    print("Usage: python king.py input.html --out output_dir")
    sys.exit(1)

input_file = sys.argv[1]
out_dir = sys.argv[3] if len(sys.argv) > 3 and sys.argv[2] == "--out" else "out"
os.makedirs(out_dir, exist_ok=True)

with open(input_file, "r", encoding="utf-8") as f:
    soup = BeautifulSoup(f, "html.parser")

tables = soup.find_all("table")
count = 0
for idx, table in enumerate(tables):
    try:
        df = pd.read_html(str(table))[0]
        base = os.path.splitext(os.path.basename(input_file))[0]
        csv_name = f"{base}_table_{idx+1}.csv"
        df.to_csv(os.path.join(out_dir, csv_name), index=False)
        count += 1
    except Exception as e:
        print(f"Warning: Could not parse table {idx+1} in {input_file}: {e}")
if count == 0:
    print(f"No tables were successfully extracted from {input_file}.")
else:
    print(f"Extracted {count} tables from {input_file} to {out_dir}")
