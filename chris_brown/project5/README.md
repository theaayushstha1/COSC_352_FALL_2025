## Aggregation Strategy for Class Report

### Combining Multiple Student Outputs

#### CSV Aggregation Approach
```bash
# Option 1: Simple concatenation (manual cleanup needed)
cat student1.csv student2.csv student3.csv > combined.csv

# Option 2: Using a script to merge district data
# Extract just the district tables from each CSV
grep -A 20 "District,Total Cases" *.csv > all_districts.csv
```

#### JSON Aggregation Approach
```bash
# Using jq to combine multiple JSON files
jq -s '{students: .}' student*.json > combined.json

# Or extract specific data across all students
jq '.question2.districts[] | select(.clearanceRate < 30)' *.json
```

**Recommendation for Class Aggregation:**
Use **JSON format** for the class report because:
- Easier to merge programmatically
- Maintains data types (numbers stay numbers)
- Can query across all students' data efficiently
- Better for creating visualizations/dashboards

## Installation & Usage

### Prerequisites
- Docker installed and running
- Bash shell (Linux/Mac) or Git Bash (Windows)
- Sufficient disk space (~1GB for Docker image + output files)

### Quick Start Guide

#### Step 1: Navigate to Project Directory
```bash
cd project5
```

#### Step 2: Make run.sh Executable (First Time Only)
```bash
chmod +x run.sh
```

#### Step 3: Run Analysis

**Default Output (stdout):**
```bash
./run.sh
```
This displays the formatted analysis in your terminal with tables and insights.

**CSV Output:**
```bash
./run.sh --output=csv
```
This creates `baltimore_homicide_analysis.csv` in the current directory.

**JSON Output:**
```bash
./run.sh --output=json
```
This creates `baltimore_homicide_analysis.json` in the current directory.

### What Happens During Execution

#### First Run (Image Build)
```
1. Docker checks for existing image
2. If not found, builds image (~2-5 minutes)
   - Downloads Scala/SBT base image
   - Copies source code
   - Compiles Scala program
3. Runs analysis with specified format
4. Outputs result
```

#### Subsequent Runs
```
1. Uses cached Docker image (~5-10 seconds)
2. Runs analysis with specified format
3. Outputs result
```

### Viewing Output Files

**CSV Files:**
```bash
# View in terminal
cat baltimore_homicide_analysis.csv

# Open in Excel/Sheets
# Double-click the file or use 'open' command on Mac
open baltimore_homicide_analysis.csv

# Open in LibreOffice Calc
libreoffice --calc baltimore_homicide_analysis.csv
```

**JSON Files:**
```bash
# View in terminal (raw)
cat baltimore_homicide_analysis.json

# View formatted (if jq is installed)
jq . baltimore_homicide_analysis.json

# Open in text editor
nano baltimore_homicide_analysis.json
# or
code baltimore_homicide_analysis.json  # VS Code
```

### Example Session

```bash
$ cd project5
$ ls
BmoreAnalysis.scala  Dockerfile  README.md  run.sh

$ ./run.sh --output=json
==================================
Baltimore Homicide Analysis
==================================

Docker image found. Using existing image.

Running analysis...

JSON output written to: baltimore_homicide_analysis.json

JSON file created: baltimore_homicide_analysis.json

==================================
Analysis completed successfully!
==================================

$ ls
BmoreAnalysis.scala  
Dockerfile  
README.md  
baltimore_homicide_analysis.json
run.sh

$ jq '.question1.summary.riskMultiplier' baltimore_homicide_analysis.json
1.89
```

## Project Structure
```
project5/
├── BmoreAnalysis.scala                    # Main Scala program with multi-format output
├── Dockerfile                              # Docker configuration
├── run.sh                                  # Execution script with parameter handling
├── README.md                               # This file
└── baltimore_homicide_analysis.{csv|json} # Generated output files (after execution)
```

## Common Use Cases

### For Individual Analysis
```bash
# Get quick overview in terminal
./run.sh

# Generate CSV for Excel analysis
./run.sh --output=csv
# Then open in Excel/Sheets for charts and pivot tables
```

### For Class Aggregation
```bash
# Each student runs:
./run.sh --output=json

# Then submit baltimore_homicide_analysis.json
# Professor can combine all JSON files:
jq -s '.' student*.json > class_combined.json
```

### For Automated Reporting
```bash
# Generate both formats
./run.sh --output=csv
./run.sh --output=json

# CSV for human review
# JSON for automated processing/dashboards
```

## Troubleshooting

### Issue: "Permission denied: ./run.sh"
**Solution:**
```bash
chmod +x run.sh
```

### Issue: Output file not created
**Symptoms:** Script completes but no CSV/JSON file appears

**Solutions:**
1. Check you're in the correct directory:
   ```bash
   pwd  # Should show .../project5
   ```

2. Verify Docker has write permissions:
   ```bash
   # Try with sudo (Linux)
   sudo ./run.sh --output=csv
   ```

3. Check Docker volume mounting:
   ```bash
   # Run manually to debug
   docker run -v "$(pwd):/output" -w /output --rm bmore-analysis scala BmoreAnalysis --output=csv
   ```

### Issue: "Error opening file for writing"
**Cause:** File may be open in another program or permission issue

**Solution:**
```bash
# Close the file in any editor/Excel
# Remove old file and try again
rm baltimore_homicide_analysis.csv
./run.sh --output=csv
```

### Issue: Docker image build fails
**Solution:**
```bash
# Remove old image and rebuild
docker rmi bmore-analysis
./run.sh
```

### Issue: Invalid JSON output
**Cause:** Usually a formatting bug in the code

**Solution:**
```bash
# Validate JSON syntax
jq . baltimore_homicide_analysis.json

# If invalid, check for:
# - Missing commas
# - Trailing commas
# - Unescaped quotes
```

## Verifying Output Correctness

### CSV Validation
```bash
# Check file exists and has content
ls -lh baltimore_homicide_analysis.csv

# Count lines (should be ~30-40)
wc -l baltimore_homicide_analysis.csv

# View first few lines
head -20 baltimore_homicide_analysis.csv

# Check for proper CSV structure
grep "District,Total Cases" baltimore_homicide_analysis.csv
```

### JSON Validation
```bash
# Validate JSON syntax
jq empty baltimore_homicide_analysis.json
# No output = valid JSON

# Check structure
jq 'keys' baltimore_homicide_analysis.json
# Should show: ["metadata", "question1", "question2"]

# Check data completeness
jq '.question2.districts | length' baltimore_homicide_analysis.json
# Should show number of districts (typically 9)
```

## Rebuilding After Code Changes

If you modify the Scala code:

```bash
# Remove old Docker image
docker rmi bmore-analysis

# Run again (will rebuild)
./run.sh --output=json
```

Or force rebuild:
```bash
docker build -t bmore-analysis . --no-cache
./run.sh
```

## Integration with Git

### Recommended .gitignore
```gitignore
# Output files (don't commit these)
*.csv
*.json
baltimore_homicide_analysis.*

# Docker# Baltimore Homicide Analysis - Project 5: Multi-Format Output

## Overview
This project extends Project 4 by adding CSV and JSON output formats to the Baltimore homicide analysis. The program can now output results in three formats: stdout (default), CSV, or JSON, making the data suitable for aggregation, reporting, and further analysis.

## Author
Your Name - Project 5 Submission

## New Features

### Output Format Options
The program now supports three output formats controlled by command-line flags:

1. **stdout (default)** - Human-readable console output with formatted tables and insights
2. **csv** - Comma-separated values format for spreadsheet analysis
3. **json** - JSON format for programmatic consumption and APIs

### Usage

```bash
# Default: Output to stdout (console)
./run.sh

# Output to CSV file
./run.sh --output=csv

# Output to JSON file
./run.sh --output=json
```

## Data Format Design Philosophy

### Why These Formats?

The data formats were designed with **aggregation and interoperability** in mind, considering that multiple students' outputs will be combined for a class-wide report.

#### CSV Format Rationale
- **Spreadsheet Compatible**: Easily imported into Excel, Google Sheets, or pandas
- **Aggregation Ready**: Simple to combine multiple CSV files using standard tools
- **Human Readable**: Can be inspected manually without special tools
- **Hierarchical Structure**: Uses section headers to organize related data

#### JSON Format Rationale
- **Programmatic Access**: Easy to parse in any programming language
- **Structured Data**: Maintains relationships and nested data naturally
- **Type Safety**: Preserves numeric types (no string conversion needed)
- **API Ready**: Can be directly consumed by web services or dashboards
- **Schema Consistency**: Enforces consistent structure across all outputs

## Data Structure Documentation

### CSV Format Structure

The CSV output is organized into logical sections:

```
SECTION 1: Metadata
- Analysis date, total records, data source

SECTION 2: Weekend vs Weekday Analysis (Question 1)
- Summary statistics (counts, percentages, rates)
- Time slot breakdown table

SECTION 3: District Clearance Rates (Question 2)
- Overall statistics
- District-by-district performance table
```

**Key Design Decisions:**
- **Section Headers**: Each major section is clearly labeled for easy parsing
- **Metric-Value Pairs**: Summary statistics use consistent "Metric,Value" format
- **Tabular Data**: Detailed breakdowns use consistent column headers
- **Blank Lines**: Sections separated by blank lines for readability
- **Numeric Precision**: Percentages and rates formatted to 2 decimal places

**Example CSV Structure:**
```csv
BALTIMORE HOMICIDE ANALYSIS
Analysis Date,2025-10-24
Total Records,550

QUESTION 1: WEEKEND VS WEEKDAY PATTERNS
Metric,Value
Total Homicides,550
Weekend Homicides,235
...

Time Period,Weekend Count,Weekday Count,Difference
Late Night (12AM-6AM),85,72,13
...

QUESTION 2: DISTRICT CLEARANCE RATES
District,Total Cases,Closed Cases,Open Cases,Clearance Rate,Above Average
Central,45,23,22,51.11,true
...
```

### JSON Format Structure

The JSON output uses a hierarchical structure with clear namespacing:

```json
{
  "metadata": {
    "analysisDate": "2025-10-24",
    "totalRecords": 550,
    "dataSource": "..."
  },
  "question1": {
    "title": "Weekend vs Weekday Homicide Patterns",
    "focus": "Resource Allocation Analysis",
    "summary": { ... },
    "timeSlotBreakdown": [ ... ]
  },
  "question2": {
    "title": "District-Level Case Clearance Rates",
    "focus": "Performance & Accountability",
    "summary": { ... },
    "districts": [ ... ]
  }
}
```

**Key Design Decisions:**
- **Top-Level Sections**: `metadata`, `question1`, `question2` for clear organization
- **Descriptive Keys**: Self-documenting field names (e.g., `totalRecords` not `tr`)
- **Consistent Naming**: camelCase throughout for JavaScript compatibility
- **Array Structures**: Lists of items (districts, time slots) as proper arrays
- **Boolean Flags**: `aboveAverage` field for easy filtering
- **Nested Objects**: Related data grouped logically (summary vs. details)

**Aggregation Benefits:**
- Multiple JSON files can be merged into a single array
- Easy to filter/query using tools like `jq` or JavaScript
- Can be loaded directly into MongoDB or other NoSQL databases
- Schema is self-describing and consistent

## File Outputs

### Output Files Generated

**CSV Mode:**
- File: `baltimore_homicide_analysis.csv`
- Location: Current directory (project5/)
- Size: ~2-5 KB typical

**JSON Mode:**
- File: `baltimore_homicide_analysis.json`
- Location: Current directory (project5/)
- Size: ~3-6 KB typical

### Output File Locations

Files are written to the **current working directory** where `run.sh` is executed. This is accomplished using Docker volume mounting:

```bash
docker run -v "$(pwd):/output" -w /output ...
```

This ensures output files appear in your project5 directory alongside the source code.

## Technical Implementation

### Parameter Passing Flow

1. **Shell Script** (`run.sh`) receives `--output=format` parameter
2. **Docker Container** is launched with volume mount for file I/O
3. **Scala Program** receives parameter as command-line argument
4. **Output Logic** selects appropriate formatter based on parameter

```
run.sh --output=csv 
  → docker run ... scala BmoreAnalysis --output=csv
    → BmoreAnalysis.main(Array("--output=csv"))
      → outputCSV() writes file
```

### Code Structure

**Key Components:**
- `case class` definitions for type-safe data structures
- Separate analysis functions return structured data
- Three output formatters: `outputStdout()`, `outputCSV()`, `outputJSON()`
- File I/O using `java.io.PrintWriter`
- Argument parsing using string matching

### Docker Integration

**Dockerfile remains unchanged** - same compilation process

**run.sh enhancements:**
- Parameter parsing and forwarding
- Volume mounting for file output
- Output file verification
- Informative messages

## Aggregation Strategy for Class Report

### Combining Multiple Student Outputs

#### CSV Aggregation Approach
```bash
# Option 1: Simple concatenation (manual cleanup needed)
cat student1.csv student2.csv student3.csv > combined.csv

# Option 2: Using a script to merge district data
# Extract just the district tables from each CSV
grep -A 20 "District,Total Cases" *.csv > all_districts.csv
```

#### JSON Aggregation Approach
```bash
# Using jq to combine multiple JSON files
jq -s '{students: .}' student*.json > combined.json

# Or extract specific data across all students
jq
