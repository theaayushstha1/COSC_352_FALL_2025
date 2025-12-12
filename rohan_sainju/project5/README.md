# Project 5: Baltimore Homicide Analysis - Multiple Output Formats

## Overview
This project extends Project 4 by adding CSV and JSON output formats to the Baltimore homicide data analysis. The program can output results in three formats: stdout (default), CSV, or JSON.

## Usage

### Default Output (stdout)
```bash
./run.sh
```
Displays formatted analysis results in the terminal.

### CSV Output
```bash
./run.sh --output=csv
```
Creates `output.csv` with analysis results in CSV format.

### JSON Output
```bash
./run.sh --output=json
```
Creates `output.json` with analysis results in JSON format.

## Data Format Decisions

### CSV Format
The CSV output uses a simple three-column structure:
- **Column 1 (metric)**: Descriptive name of the metric being measured
- **Column 2 (value)**: Numerical value for that metric
- **Column 3 (percentage)**: Percentage value where applicable (empty for metrics without percentages)

**Rationale**: This format is:
- Easy to import into spreadsheet applications (Excel, Google Sheets)
- Simple to parse programmatically
- Human-readable with clear column headers
- Suitable for aggregating data from multiple students' analyses

**Example**:
```csv
metric,value,percentage
victims_under_18_in_2025,0,
closed_cases,8,50
open_cases,8,50
total_cases,16,100
```

### JSON Format
The JSON output uses a nested structure:
- Top level includes an "analysis" field identifying the data source
- "questions" object contains two sub-objects for each analysis question
- Each question has clearly labeled fields with descriptive names

**Rationale**: This format is:
- Self-documenting with clear field names
- Easy to parse in any programming language
- Hierarchical structure groups related data logically
- Extensible for future analyses without breaking compatibility
- Standard format for web APIs and data interchange

**Example**:
```json
{
  "analysis": "Baltimore City Homicide Data",
  "questions": {
    "victims_under_18_in_2025": {
      "count": 0
    },
    "case_status": {
      "closed": 8,
      "closed_percentage": 50,
      "open": 8,
      "open_percentage": 50,
      "total": 16
    }
  }
}
```

## Analysis Questions
1. **How many victims were under 18 years old in 2025?**
   - Counts homicide victims younger than 18 in the year 2025
   
2. **How many homicide cases are open vs closed?**
   - Categorizes all cases by their status (Closed, Open, or Unknown)
   - Provides both raw counts and percentages

## Technical Implementation
- **Language**: Scala 3
- **Container**: Docker (using `hseeberger/scala-sbt:17.0.2_1.6.2_3.1.1` base image)
- **Data Source**: `homicides.csv` containing Baltimore homicide statistics

## Files
- `HomicideAnalysis.scala` - Main program with analysis logic and output formatting
- `run.sh` - Shell script to build Docker image and run analysis
- `Dockerfile` - Container configuration
- `homicides.csv` - Baltimore homicide data
- `README.md` - This file

## Notes for Future Integration
When aggregating data from multiple students in a future project:
- CSV files can be concatenated (skip headers after the first file)
- JSON files can be parsed and merged into a larger structure
- Both formats maintain data integrity and are easily validated
