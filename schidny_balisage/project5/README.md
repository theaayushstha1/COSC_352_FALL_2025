# Project 5: Baltimore Crime Analysis with Multiple Output Formats

## Overview
This project extends Project 4 by adding support for CSV and JSON output formats in addition to the default stdout output. The program analyzes Baltimore Police Department Part 1 Crime Data and generates statistics by neighborhood.

## Usage

### Default Output (stdout)
```bash
./run.sh
```
Prints formatted crime statistics directly to the terminal.

### CSV Output
```bash
./run.sh --output=csv
```
Creates a file `baltimore_crime_stats.csv` with crime statistics.

### JSON Output
```bash
./run.sh --output=json
```
Creates a file `baltimore_crime_stats.json` with crime statistics.

## Output Format Documentation

### CSV Format
The CSV output follows a standard tabular format with the following columns:

**Columns:**
- `neighborhood` - Name of the Baltimore neighborhood (string)
- `total_crimes` - Total number of Part 1 crimes reported (integer)
- `violent_crimes` - Count of violent crimes (assault, robbery, homicide) (integer)
- `property_crimes` - Count of property crimes (burglary, larceny, theft) (integer)
- `average_per_month` - Average crimes per month (decimal, 2 places)

**Format Specifications:**
- Header row included
- Comma-separated values
- Neighborhood names containing commas or quotes are properly escaped with double quotes
- Sorted by total crimes descending (highest crime neighborhoods first)
- UTF-8 encoding

**Example:**
```csv
neighborhood,total_crimes,violent_crimes,property_crimes,average_per_month
Downtown,1250,450,600,104.17
Canton,890,210,520,74.17
Federal Hill,765,180,450,63.75
```

### JSON Format
The JSON output provides a structured format with metadata and an array of crime statistics.

**Structure:**
```json
{
  "metadata": {
    "source": "Baltimore Police Department Part 1 Crime Data",
    "generated_at": "2025-10-24T...",
    "total_neighborhoods": 200
  },
  "crime_statistics": [
    {
      "neighborhood": "Downtown",
      "total_crimes": 1250,
      "violent_crimes": 450,
      "property_crimes": 600,
      "average_per_month": 104.17
    }
  ]
}
```

**Format Specifications:**
- Pretty-printed with 2-space indentation
- Metadata section provides context about data source and generation time
- Statistics array sorted by total crimes descending
- All strings properly escaped
- Numbers are unquoted (native JSON numbers)
- UTF-8 encoding
- Valid JSON that can be parsed by any standard JSON library

## Data Analysis Methodology

### Crime Classification
The program categorizes crimes into two main types:

**Violent Crimes:** Offenses containing keywords:
- ASSAULT
- ROBBERY
- HOMICIDE

**Property Crimes:** Offenses containing keywords:
- BURGLARY
- LARCENY
- THEFT

### Metrics Calculated
1. **Total Crimes** - All Part 1 crimes reported in the neighborhood
2. **Violent Crimes** - Subset of crimes classified as violent
3. **Property Crimes** - Subset of crimes classified as property-related
4. **Average Per Month** - Total crimes divided by 12 (assuming annual data)

## File Structure
```
project5/
├── build.sbt
├── Dockerfile
├── run.sh
├── README.md
└── src/
    └── main/
        └── scala/
            └── BaltimoreAnalysis.scala
```

## Dependencies
- Scala 2.12.15
- Apache Spark 3.2.0
- SBT 1.5.4
- Docker
- Baltimore PD Crime Data (downloaded automatically)
