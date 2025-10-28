# Project 5 – Multi-Format Output (Scala)

## Overview
This project extends Project 4 by adding output support for multiple data formats.  
By default, the program prints results to **stdout**, but when the `--output` flag is provided, it writes formatted files to the `output/` directory in either **CSV** or **JSON**.

---

## How to Run
From the `project5` directory:

```bash
# Default (prints to console)
./run.sh

# Output to CSV file (output/results.csv)
./run.sh --output=csv

# Output to JSON file (output/results.json)
./run.sh --output=json
