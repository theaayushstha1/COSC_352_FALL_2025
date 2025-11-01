# Project 5: Baltimore Homicide Analysis - Multi-Format Output

## Overview
This project extends Project 4 by adding CSV and JSON output formats in addition to the default text output. The analysis answers the same two questions about Baltimore homicides but can now export data in formats suitable for aggregation and reporting.

## How to Run

### Default Output (Text to Terminal)
```bash
./run.sh
```

### CSV Output
```bash
./run.sh --output=csv
```
Generates 4 CSV files in the `output/` directory.

### JSON Output
```bash
./run.sh --output=json
```
Generates 1 JSON file in the `output/` directory.

## Data Format Design

### CSV Format
I chose to create **4 separate CSV files** instead of one large file:

1. **district_analysis_[timestamp].csv** - One row per district with clearance rates
2. **camera_analysis_[timestamp].csv** - Two rows comparing camera vs non-camera locations
3. **analysis_summary_[timestamp].csv** - Key metrics in key-value format
4. **homicide_records_[timestamp].csv** - Complete raw data (one row per homicide)

**Why separate files?**
- Each file serves a different analytical purpose
- Easier to import specific data into spreadsheets
- Prevents one massive file that's hard to work with
- Allows combining multiple students' data by file type

**Field naming conventions:**
- Snake_case (e.g., `total_cases`, `clearance_rate`)
- Boolean values as `true`/`false`
- Empty cells for missing data (not "N/A" or "null")
- Percentages as decimal numbers (e.g., 62.2 for 62.2%)

**Example district_analysis.csv:**
```csv
district,total_cases,closed_cases,clearance_rate,performance_indicator
Eastern,45,28,62.2,high
Western,89,18,20.2,low
Central,67,32,47.8,medium
```

### JSON Format
I chose to create **1 comprehensive JSON file** with nested structure:
```json
{
  "analysis_metadata": { ... },
  "question_1_district_analysis": {
    "summary": { ... },
    "districts": [ ... ]
  },
  "question_2_camera_analysis": {
    "summary": { ... },
    "locations": [ ... ]
  },
  "raw_records": [ ... ]
}
```

**Why this structure?**
- Self-documenting (field names match analysis questions)
- Easy to parse programmatically
- Includes both summary stats and raw data
- Suitable for web APIs and dashboards
- Single file is easier to share/upload than multiple CSVs

**Data types:**
- Numbers as actual numbers (not strings)
- Booleans as `true`/`false` (not strings)
- Missing values as `null`

### Timestamps in Filenames
All output files include timestamp: `YYYYMMDD_HHMMSS`

**Why?**
- Multiple runs don't overwrite each other
- Easy to track when analysis was performed
- Files sort chronologically

## Output Files

### CSV Mode Produces:
```
output/
├── district_analysis_20251024_143000.csv
├── camera_analysis_20251024_143000.csv
├── analysis_summary_20251024_143000.csv
└── homicide_records_20251024_143000.csv
```

### JSON Mode Produces:
```
output/
└── baltimore_homicide_analysis_20251024_143000.json
```

## Why These Formats Work for Aggregation

1. **Consistent schema** - All students' outputs will have identical column names
2. **Standard formats** - CSV and JSON are universally supported
3. **Complete data** - Raw records allow instructors to re-analyze with different questions
4. **Metadata included** - Timestamp, data source, years analyzed are embedded
5. **Easy to combine** - Can merge multiple CSV files with simple scripts

### Example: Combining Multiple Students' Data
```bash
# Combine all district analyses
cat output/district_analysis_*.csv | head -1 > combined_districts.csv
cat output/district_analysis_*.csv | grep -v "^district," >> combined_districts.csv
```

Or in Python:
```python
import pandas as pd
import glob

files = glob.glob("*/output/district_analysis_*.csv")
df = pd.concat([pd.read_csv(f) for f in files])
print(df.groupby('district')['clearance_rate'].mean())
```

## Questions Analyzed

1. **District Clearance Rate Analysis** - Which police districts solve the most homicides?
2. **Camera Effectiveness Analysis** - Do surveillance cameras improve case closure rates?

## Prerequisites
- Docker installed
- Bash shell

## First Time Setup
```bash
chmod +x run.sh
mkdir output
```