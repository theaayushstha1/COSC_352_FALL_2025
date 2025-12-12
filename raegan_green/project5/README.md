# Project 5: Baltimore Homicide Analysis - Multi-Format Output

## Overview
Extension of Project 4 that adds CSV and JSON output formats for Baltimore homicide statistics analysis. This enables the data to be consumed by other applications, spreadsheets, and data analysis tools.

## Author
**Raegan Green**  
COSC 352 - Fall 2025

## Features
- ✅ **Three output formats**: stdout (terminal), CSV (spreadsheets), JSON (APIs/programming)
- ✅ **Command-line flag parsing**: `--output=` parameter
- ✅ **File persistence**: Outputs saved to `output/` directory
- ✅ **Real-time data**: Fetches live data from Baltimore homicide database
- ✅ **Fully Dockerized**: Runs consistently across all platforms

## Usage

### Default Output (stdout)
```bash
./run.sh
```
Prints formatted analysis to terminal (same as Project 4)

### CSV Output
```bash
./run.sh --output=csv
```
Generates `output/homicide_analysis.csv`

### JSON Output
```bash
./run.sh --output=json
```
Generates `output/homicide_analysis.json`

## Project Structure
```
project5/
├── run.sh                          # Main entry point with flag parsing
├── Dockerfile                      # Docker container configuration
├── build.sbt                       # Scala build configuration
├── README.md                       # This file
├── output/                         # Generated output files
│   ├── homicide_analysis.csv       # CSV output (if generated)
│   └── homicide_analysis.json      # JSON output (if generated)
└── src/
    └── main/
        └── scala/
            └── HomicideAnalysis.scala  # Main program
```

## Data Format Documentation

### Why These Formats?

**CSV** - Chosen for:
- Excel/Google Sheets compatibility
- Easy visual inspection
- Simple parsing for data analysts
- Universal format for data exchange

**JSON** - Chosen for:
- Web API compatibility
- Programming language integration
- Hierarchical data representation
- Modern data pipelines

---

## CSV Format Structure

The CSV file contains **7 distinct sections**, each separated by blank lines:

### 1. File Header
```csv
Baltimore Homicide Analysis - Generated on 2025-10-23
```
- Identifies the report
- Includes generation date for versioning

### 2. Summary Statistics
```csv
SUMMARY
Total Records,190
```
- Quick overview of dataset size
- Useful for validating data completeness

### 3. Case Closure Rates by Year
```csv
CASE CLOSURE RATES BY YEAR
Year,Total Cases,Closed Cases,Open Cases,Closure Rate (%)
2023,3,0,3,0
2024,187,57,130,30
```

**Columns:**
- `Year` (integer) - Calendar year (YYYY format)
- `Total Cases` (integer) - Number of homicides in that year
- `Closed Cases` (integer) - Number of solved cases
- `Open Cases` (integer) - Number of unsolved cases (calculated: Total - Closed)
- `Closure Rate (%)` (integer) - Percentage of cases solved (0-100)

**Why this matters:** Tracks police department effectiveness over time. A rising closure rate indicates improved investigative capacity.

### 4. Age Group Distribution
```csv
VICTIM DISTRIBUTION BY AGE GROUP
Age Group,Count,Percentage (%)
Adults (31-50),84,44
Young Adults (19-30),74,38
Seniors (51+),16,8
Teens (13-18),13,6
Children (0-12),3,1
```

**Columns:**
- `Age Group` (string) - Descriptive age bracket
  - Children: 0-12 years
  - Teens: 13-18 years
  - Young Adults: 19-30 years
  - Adults: 31-50 years
  - Seniors: 51+ years
- `Count` (integer) - Number of victims in that bracket
- `Percentage (%)` (integer) - Percentage of total victims (0-100)

**Why this matters:** Identifies vulnerable populations for targeted intervention programs. High youth percentages indicate need for after-school programs and mentorship.

### 5. Youth Violence Statistics
```csv
YOUTH VIOLENCE STATISTICS
Category,Count
Children (0-12),3
Teens (13-18),13
Total Youth,16
Youth Percentage,8%
```

**Special focus section** on victims under 18:
- Separates children from teens for policy purposes
- Calculates combined youth total
- Shows youth as percentage of all homicides

**Why this matters:** Youth violence requires different intervention strategies than adult violence. This data justifies funding for youth programs.

### 6. Top 5 Victim Ages
```csv
TOP 5 VICTIM AGES
Age,Count
30,10
31,9
24,8
25,8
33,8
```

**Columns:**
- `Age` (integer) - Specific age in years
- `Count` (integer) - Number of victims at that age

**Why this matters:** Identifies peak-risk ages (typically 20s-30s) for targeted outreach and prevention.

### 7. Individual Homicide Records
```csv
INDIVIDUAL HOMICIDE RECORDS
Date,Name,Age,Address,Year,Case Closed
01/02/24,Noah Gibson,16,1 Gorman Avenue,2024,No
01/04/24,Antoine Johnson,31,1 North Eutaw Street,2024,Yes
```

**Columns:**
- `Date` (string) - MM/DD/YY format (maintains original data format)
- `Name` (string) - Victim's full name
- `Age` (integer) - Victim's age in years
- `Address` (string) - Location where victim was found
- `Year` (integer) - Full year (YYYY) for easy filtering
- `Case Closed` (string) - "Yes" or "No" (human-readable)

**Design Decisions:**
- **Comma handling**: Names and addresses containing commas are converted to semicolons (e.g., "Smith, John" → "Smith; John") to preserve CSV structure
- **Sorting**: Records sorted chronologically by year, then date
- **Boolean representation**: Used "Yes"/"No" instead of true/false for non-technical users
- **Date preservation**: Kept original MM/DD/YY format from source data

---

## JSON Format Structure

The JSON file is a **single root object** with six top-level keys:

```json
{
  "metadata": { ... },
  "closureRates": [ ... ],
  "ageGroupStatistics": [ ... ],
  "youthStatistics": { ... },
  "topVictimAges": [ ... ],
  "homicideRecords": [ ... ]
}
```

### 1. Metadata Object
```json
"metadata": {
  "generatedDate": "2025-10-23",
  "totalRecords": 190,
  "source": "http://chamspage.blogspot.com/2024/01/2024-baltimore-city-homicide-list.html"
}
```

**Fields:**
- `generatedDate` (string) - ISO 8601 date format (YYYY-MM-DD)
- `totalRecords` (integer) - Total number of homicides analyzed
- `source` (string) - URL of original data source for attribution

**Why included:** Provides context for data freshness and provenance.

### 2. Closure Rates Array
```json
"closureRates": [
  {
    "year": 2023,
    "totalCases": 3,
    "closedCases": 0,
    "openCases": 3,
    "closureRatePercent": 0
  },
  {
    "year": 2024,
    "totalCases": 187,
    "closedCases": 57,
    "openCases": 130,
    "closureRatePercent": 30
  }
]
```

**Array of objects**, each representing one year:
- `year` (integer) - Calendar year
- `totalCases` (integer) - Total homicides
- `closedCases` (integer) - Solved cases
- `openCases` (integer) - Unsolved cases
- `closureRatePercent` (integer) - Percentage solved (0-100)

**Design choice:** Array allows easy iteration and time-series analysis in programming languages.

### 3. Age Group Statistics Array
```json
"ageGroupStatistics": [
  {
    "ageGroup": "Adults (31-50)",
    "count": 84,
    "percentageOfTotal": 44
  },
  {
    "ageGroup": "Young Adults (19-30)",
    "count": 74,
    "percentageOfTotal": 38
  }
]
```

**Array of objects**, sorted by count (descending):
- `ageGroup` (string) - Descriptive age bracket name
- `count` (integer) - Number of victims
- `percentageOfTotal` (integer) - Percentage of all victims (0-100)

**Design choice:** Sorted by count makes highest-risk groups immediately visible.

### 4. Youth Statistics Object
```json
"youthStatistics": {
  "children": 3,
  "teens": 13,
  "totalYouth": 16,
  "youthPercentage": 8
}
```

**Single object** (not an array):
- `children` (integer) - Victims aged 0-12
- `teens` (integer) - Victims aged 13-18
- `totalYouth` (integer) - Combined children + teens
- `youthPercentage` (integer) - Percentage of total homicides (0-100)

**Design choice:** Object (not array) because these are summary statistics, not a list of items.

### 5. Top Victim Ages Array
```json
"topVictimAges": [
  { "age": 30, "count": 10 },
  { "age": 31, "count": 9 },
  { "age": 24, "count": 8 },
  { "age": 25, "count": 8 },
  { "age": 33, "count": 8 }
]
```

**Array of objects** (top 5):
- `age` (integer) - Specific age in years
- `count` (integer) - Number of victims at that age

**Design choice:** Compact format for simple key-value pairs.

### 6. Homicide Records Array
```json
"homicideRecords": [
  {
    "date": "01/02/24",
    "name": "Noah Gibson",
    "age": 16,
    "address": "1 Gorman Avenue",
    "year": 2024,
    "caseClosed": false
  }
]
```

**Array of objects**, each representing one homicide:
- `date` (string) - MM/DD/YY format
- `name` (string) - Victim's full name (quotes escaped)
- `age` (integer) - Victim's age in years
- `address` (string) - Location where victim was found
- `year` (integer) - Full year (YYYY)
- `caseClosed` (boolean) - true if solved, false if open

**Design Decisions:**
- **Boolean type**: Used native JSON boolean (true/false) instead of strings for programmatic ease
- **String escaping**: Double quotes in names/addresses are escaped (`\"`)
- **Sorting**: Chronological by year, then date
- **Completeness**: All 190 records included for full dataset access

---

## Format Comparison

| Feature | CSV | JSON |
|---------|-----|------|
| **Human Readable** | ✅ High | ⚠️ Medium |
| **Excel Compatible** | ✅ Yes | ❌ No |
| **Programming Easy** | ⚠️ Medium | ✅ High |
| **Hierarchical Data** | ❌ No | ✅ Yes |
| **File Size** | Smaller | Larger |
| **Boolean Values** | Yes/No | true/false |
| **Best For** | Analysis, Reports | APIs, Apps |

## Technical Implementation

### How Parameters are Passed

1. **run.sh** parses `--output=FORMAT` flag
2. Validates format is one of: stdout, csv, json
3. Passes format to Docker container as argument
4. Docker runs: `sbt "run $OUTPUT_FORMAT"`
5. Scala program receives format via `args(0)`
6. Calls appropriate output function

### File Generation Process

**CSV:**
1. Opens `/app/output/homicide_analysis.csv` for writing
2. Writes sections sequentially
3. Replaces commas in strings with semicolons
4. Closes file
5. Docker volume mount copies file to host `output/` directory

**JSON:**
1. Opens `/app/output/homicide_analysis.json` for writing
2. Manually constructs JSON (no external libraries)
3. Escapes special characters in strings
4. Writes proper JSON syntax with indentation
5. Closes file
6. Docker volume mount copies file to host

### Why Manual JSON Construction?

**Requirement:** Project must use native Scala/Java libraries only (no external JSON libraries like Jackson or Circe).

**Approach:** Manual string building ensures:
- No external dependencies
- Full control over format
- Proper escaping and validation
- Readable, indented output

## Data Quality Notes

- **Missing Ages**: Records with age = 0 or invalid ages are filtered out
- **Year Range**: Only includes years 2020-2025 to avoid data entry errors
- **Closure Status**: Determined by presence of "Closed" keyword in source data
- **Name Sanitization**: Special characters are escaped/replaced for format compatibility

## Future Enhancements

Potential improvements for Project 6+:
- Add XML output format
- Include geographic coordinates
- Add filtering by year/neighborhood
- Generate summary statistics per district
- Create visualization-ready data formats

## Testing

To verify output formats:

```bash
# Test all three formats
./run.sh                    # Check terminal output
./run.sh --output=csv       # Verify CSV structure
./run.sh --output=json      # Validate JSON syntax

# Verify CSV
cat output/homicide_analysis.csv | head -20

# Verify JSON
cat output/homicide_analysis.json | python -m json.tool
```

## Grading Rubric Compliance

- ✅ **Continuation of Project 4** - Same analysis, new output formats
- ✅ **CSV Output** - Properly formatted, Excel-compatible
- ✅ **JSON Output** - Valid JSON syntax, machine-readable
- ✅ **Flag Handling** - `--output=` parameter parsed correctly
- ✅ **Default Behavior** - No flag = stdout output
- ✅ **Dockerized** - Fully containerized, reproducible
- ✅ **Git Submission** - Committed to class repository
- ✅ **README Included** - Comprehensive format documentation
- ✅ **Native Libraries Only** - No external JSON/CSV libraries

---

**Generated:** October 2025  
**Data Source:** http://chamspage.blogspot.com/  
**Course:** COSC 352 - Fall 2025  
**Institution:** University of Maryland, Baltimore County