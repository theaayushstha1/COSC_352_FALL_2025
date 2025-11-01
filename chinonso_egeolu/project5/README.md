# Project 5: Multi-Format Output

Extends Project 4 to output Baltimore homicide analysis in CSV and JSON formats.

## Usage

```bash
./run.sh                    # Console output (default)
./run.sh --output=csv       # Generate CSV files
./run.sh --output=json      # Generate JSON file
```

## Output Files

**CSV (3 files):**
- `monthly_patterns.csv` - Homicides by month
- `seasonal_patterns.csv` - Homicides by season
- `district_analysis.csv` - District statistics

**JSON (1 file):**
- `homicide_analysis.json` - Complete analysis with all data

## Format Design

**CSV:** Simple tabular format for Excel, Python, R, and BI tools. Separate files for different analysis types.

**JSON:** Single structured file with metadata (date, source, totals) and nested data. Ready for APIs, web apps, and databases.

Both formats use snake_case for compatibility with data tools.

## Technical

- Native Scala only (`java.io.PrintWriter`)
- No external libraries
- Docker volume mount writes files to host
