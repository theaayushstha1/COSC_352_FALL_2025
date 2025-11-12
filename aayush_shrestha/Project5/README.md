# Project 5: Baltimore City Homicide Data Analysis - Structured Output Formats

**Author:** Aayush Shrestha  
**Course:** COSC 352 - Fall 2025  
**Institution:** Morgan State University  
**Date:** October 24, 2025

---

## Project Overview

This project extends Project 4 by adding **CSV** and **JSON** output capabilities to the Baltimore City homicide data analysis program. The program can now output results in three formats: **stdout** (default), **CSV**, and **JSON**.

The analysis examines Baltimore City homicide statistics to answer two critical questions:
1. **Violence Interruption Zone Deployment:** Which locations have the highest homicide concentrations?
2. **Age-Targeted Intervention Programs:** Which age groups require focused prevention resources?

---

## Usage

### Running the Program

```bash
# Default output to stdout (terminal)
./run.sh

# Output to CSV file
./run.sh --output=csv

# Output to JSON file
./run.sh --output=json
```

### Prerequisites

- **Docker Desktop** installed and running
- **macOS/Linux/Windows** with bash shell support
- Executable permissions on `run.sh` (use `chmod +x run.sh` if needed)

---

## Output Formats

### 1. Standard Output (stdout) - Default

When no flag is provided, the program prints a formatted analysis report to the terminal with:
- Summary statistics
- Top 10 location hotspots with case counts and closure rates
- Age group analysis with demographic breakdowns
- Recommendations for intervention strategies

**Example:**
```bash
./run.sh
```

### 2. CSV Output

Creates a structured CSV file: `baltimore_homicide_analysis.csv`

**Example:**
```bash
./run.sh --output=csv
```

**File size:** ~3.0KB

**CSV Structure:**

#### Section 1: Metadata
```csv
BALTIMORE CITY HOMICIDE DATA ANALYSIS
Total Homicides,25
Overall Closure Rate,56.00%
Critical Zones Count,1
```

#### Section 2: Location Hotspots Analysis
```csv
Location,Total Cases,Open Cases,Closed Cases,Closure Rate (%),Cameras Present,Avg Victim Age
1200 block n broadway,3,2,1,33.33,2,26
3300 block greenmount ave,2,0,2,100.00,2,34
...
```

#### Section 3: Age Group Analysis
```csv
Age Group,Total Cases,Closed Cases,Open Cases,Closure Rate (%),Cameras Present
Adults (26-40),9,6,3,66.67,5
Middle Age (41-60),6,5,1,83.33,4
...
```

#### Section 4: Raw Homicide Data
Complete dataset with individual records for further analysis.

### 3. JSON Output

Creates a structured JSON file: `baltimore_homicide_analysis.json`

**Example:**
```bash
./run.sh --output=json
```

**File size:** ~9.9KB

**JSON Structure:**

```json
{
  "analysis_metadata": {
    "total_homicides": 25,
    "overall_closure_rate": 56.00,
    "critical_zones_count": 1
  },
  "location_hotspots": [
    {
      "location": "1200 block n broadway",
      "total_cases": 3,
      "open_cases": 2,
      "closed_cases": 1,
      "closure_rate": 33.33,
      "cameras_present": 2,
      "avg_victim_age": 26
    }
  ],
  "age_group_analysis": [
    {
      "age_group": "Adults (26-40)",
      "total_cases": 9,
      "closed_cases": 6,
      "open_cases": 3,
      "closure_rate": 66.67,
      "cameras_present": 5
    }
  ],
  "raw_homicide_data": [
    {
      "number": "1",
      "date_died": "01/05/25",
      "name": "John Smith",
      "age": "17",
      "address": "1200 block N Broadway",
      "camera_present": "camera at intersection",
      "case_status": "Open"
    }
  ]
}
```

---

## Data Format Design Decisions

### Why CSV?

**Best for:**
- Spreadsheet analysis (Excel, Google Sheets)
- Database imports (PostgreSQL, MySQL)
- Statistical software (R, SPSS, SAS)
- Data science workflows (Pandas, NumPy)

**Design choices:**
- **Comma-delimited:** Standard CSV format for universal compatibility
- **Proper escaping:** Strings with commas/quotes are enclosed in quotes
- **Section headers:** Clear text separators for different analysis components
- **Numeric precision:** Percentages formatted to 2 decimal places
- **Sequential organization:** Flows from summary → analysis → raw data

### Why JSON?

**Best for:**
- Web applications and REST APIs
- JavaScript/Node.js applications
- NoSQL databases (MongoDB, CouchDB)
- Data exchange between systems
- Configuration and settings files

**Design choices:**
- **Hierarchical structure:** Nested objects and arrays for logical grouping
- **Snake_case keys:** Consistent naming convention (e.g., `total_cases`)
- **Type safety:** Numbers unquoted, strings quoted
- **Self-documenting:** Key names clearly indicate data content
- **Standard JSON:** Strict RFC 8259 compliance for maximum compatibility

### Common Features

Both formats include:
1. **Metadata section:** High-level summary statistics
2. **Location analysis:** Geographic hotspots with detailed metrics
3. **Age demographics:** Age group breakdowns and patterns
4. **Complete raw data:** Individual homicide records for verification
5. **Calculated fields:** Closure rates, averages, and aggregations

---

## Technical Implementation

### Architecture

- **Language:** Scala 2.13.12
- **Runtime:** OpenJDK 17 (slim)
- **Containerization:** Docker with volume mounting
- **File I/O:** Native Java `PrintWriter` (no external libraries)
- **Argument parsing:** Command-line flag processing in `run.sh` and Scala

### File Organization

```
Project5/
├── BaltimoreHomicideAnalysis.scala    # Main Scala program
├── Dockerfile                          # Container definition
├── run.sh                              # Execution script with argument parsing
├── README.md                           # This file
├── baltimore_homicide_analysis.csv    # Generated CSV output
└── baltimore_homicide_analysis.json   # Generated JSON output
```

### Docker Configuration

**Base Image:** `openjdk:17-slim`  
**Scala Version:** 2.13.12  
**Volume Mount:** `$(pwd):/output` for file persistence  
**ENTRYPOINT:** Allows command-line argument pass-through

### Data Processing Pipeline

```
1. Command-line argument parsing (run.sh)
   ↓
2. Docker container launch with argument
   ↓
3. Scala program receives output format
   ↓
4. Data fetching (live or sample)
   ↓
5. Analysis computation
   ↓
6. Format-specific output generation
   ↓
7. File written to /output (mounted volume)
   ↓
8. Output file available on host machine
```

---

## Key Features

### ✅ Backward Compatibility
- Default behavior unchanged (stdout output)
- Project 4 functionality fully preserved
- No breaking changes to existing workflows

### ✅ Multiple Output Formats
- **3 formats supported:** stdout, CSV, JSON
- **Single codebase:** DRY principle maintained
- **Consistent data:** Same analysis across all formats

### ✅ Production-Ready Code
- **No placeholders:** All features fully implemented
- **Error handling:** Graceful fallback to sample data
- **Data validation:** Type safety and bounds checking
- **Proper escaping:** CSV and JSON special character handling

### ✅ Docker Integration
- **Reproducible builds:** Consistent environment across machines
- **Volume mounting:** Output files persist to host
- **Efficient caching:** Layer optimization for fast rebuilds
- **Argument passing:** ENTRYPOINT enables flag propagation

### ✅ Documentation
- **Comprehensive README:** Complete usage instructions
- **Code comments:** Inline documentation for maintainability
- **Format specifications:** Clear data structure definitions
- **Design rationale:** Explained architectural decisions

---

## Sample Data

The program includes sample data for demonstration when live data is unavailable:
- **25 homicide cases** across various Baltimore locations
- **5 age groups:** Minors, Young Adults, Adults, Middle Age, Seniors
- **Realistic metrics:** Closure rates, camera presence, victim demographics
- **Geographic distribution:** Multiple neighborhood hotspots

---

## Analysis Metrics

### Location Hotspots
- **Total cases per location**
- **Open vs. closed case counts**
- **Closure rate percentage**
- **Camera surveillance presence**
- **Average victim age**

### Age Group Demographics
- **Case counts by age bracket**
- **Closure rates by age group**
- **Open case tracking**
- **Camera coverage statistics**

### Overall Statistics
- **Total homicides analyzed**
- **System-wide closure rate**
- **Critical zone identification (3+ cases)**

---

## Error Handling

- **Live data fetch failures:** Automatic fallback to sample data
- **Missing Docker daemon:** Clear error message with instructions
- **Invalid arguments:** Usage help displayed
- **File write errors:** Exception handling with user notification

---

## Future Enhancements

Potential improvements for subsequent projects:
- **XML output format** support
- **Database export** functionality (PostgreSQL, MySQL)
- **Compressed output** (gzip, bzip2)
- **Streaming output** for large datasets
- **Custom output directory** specification
- **Date range filtering** options
- **Geospatial visualization** export (GeoJSON)

---

## Testing

### Test Cases

```bash
# Test 1: Default behavior
./run.sh
# Expected: Terminal output with formatted report

# Test 2: CSV generation
./run.sh --output=csv
ls -lh baltimore_homicide_analysis.csv
# Expected: 3.0KB CSV file created

# Test 3: JSON generation
./run.sh --output=json
ls -lh baltimore_homicide_analysis.json
# Expected: 9.9KB JSON file created

# Test 4: Invalid argument
./run.sh --output=xml
# Expected: Error message with usage instructions
```

### Verification

```bash
# Verify CSV format
head -30 baltimore_homicide_analysis.csv

# Verify JSON format
cat baltimore_homicide_analysis.json | python -m json.tool

# Check file sizes
ls -lh *.csv *.json
```

---

## Troubleshooting

### Docker not running
```bash
# Start Docker Desktop
open -a Docker

# Wait for Docker to start, then retry
./run.sh
```

### Permission denied on run.sh
```bash
chmod +x run.sh
./run.sh
```

### Files not appearing
```bash
# Verify volume mounting in run.sh
# Ensure line contains: -v "$(pwd):/output"

# Rebuild Docker image
docker rmi baltimore-homicide-analysis
docker build -t baltimore-homicide-analysis .
```

### Scala compilation errors
```bash
# Clean rebuild
docker build --no-cache -t baltimore-homicide-analysis .
```

---

## References

- **Data Source:** chamspage.blogspot.com (Baltimore homicide tracking)
- **Scala Documentation:** https://docs.scala-lang.org/
- **Docker Documentation:** https://docs.docker.com/
- **CSV Specification:** RFC 4180
- **JSON Specification:** RFC 8259

---

## License

This project is submitted as coursework for COSC 352 at Morgan State University.

---

## Acknowledgments

- **Professor Jon White** - Course instruction and project requirements
- **Morgan State University** - Educational support
- **Baltimore City** - Public data availability

---

## Contact

**Aayush Shrestha**  
Morgan State University  
COSC 352 - Fall 2025

---

*Last Updated: October 24, 2025*