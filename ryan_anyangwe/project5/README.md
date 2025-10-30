# Project 5: Baltimore City Homicide Analysis - Multiple Output Formats

## Student Information
**Name:** Ryan Anyangwe  
**Course:** COSC 352 Fall 2025  
**Date:** October 2025

## Overview
Project 5 extends Project 4 by adding **CSV** and **JSON** output formats to the Baltimore City homicide analysis. The program now supports three output modes:
- **STDOUT** (default): Human-readable console output
- **CSV**: Machine-readable comma-separated values for spreadsheet analysis
- **JSON**: Structured data format for programmatic consumption and reporting

## How to Run

### Prerequisites
- Docker installed and running
- Git

### Usage

#### 1. Default Output (STDOUT)
```bash
./run.sh
```
Prints human-readable analysis to the console.

#### 2. CSV Output
```bash
./run.sh --output=csv
```
Generates two CSV files:
- `district_analysis.csv`
- `temporal_analysis.csv`

#### 3. JSON Output
```bash
./run.sh --output=json
```
Generates one JSON file:
- `analysis_results.json`

### Installation

```bash
# Clone the repository
git clone https://github.com/B3nterprise/project5.git
cd project5

# Make run.sh executable
chmod +x run.sh

# Run with your preferred output format
./run.sh --output=json
```

## Data Format Design Choices

### CSV Format Rationale

I chose to create **two separate CSV files** rather than one combined file because:

1. **Separation of Concerns**: Each question addresses a different analytical dimension
   - District analysis focuses on geographic/administrative units
   - Temporal analysis focuses on time-based patterns

2. **Easy Spreadsheet Import**: Separate files allow direct import into Excel/Google Sheets without manual splitting

3. **Different Column Structures**: Each analysis has unique metrics that don't naturally combine

#### district_analysis.csv Structure
```csv
District,Total Homicides,Closed Cases,Open Cases,Closure Rate (%),Priority Level
```

**Columns:**
- `District`: Police district name (categorical)
- `Total Homicides`: Count of all homicides in district
- `Closed Cases`: Number of solved cases
- `Open Cases`: Number of unsolved cases
- `Closure Rate (%)`: Percentage of cases closed
- `Priority Level`: Resource allocation priority (CRITICAL/HIGH/STANDARD)

**Design Decisions:**
- Priority level is pre-calculated to enable immediate filtering
- Numeric values are raw numbers (not formatted) for calculations
- Sorted by closure rate (worst first) for quick identification of problem areas

#### temporal_analysis.csv Structure
```csv
Month Number,Month Name,Average Homicides,Percent of Annual Average,Deployment Level
```

**Columns:**
- `Month Number`: 1-12 for easy sorting and joins
- `Month Name`: Human-readable month name
- `Average Homicides`: Mean homicides per month across all years analyzed
- `Percent of Annual Average`: Relative frequency compared to annual average
- `Deployment Level`: Recommended patrol intensity (MAXIMUM/ELEVATED/STANDARD/REDUCED)

**Design Decisions:**
- Both month number and name provided for flexibility
- Averages across multiple years smooth out anomalies
- Deployment level provides actionable recommendation
- Percentages enable easy comparison and visualization

### JSON Format Rationale

I chose a **single comprehensive JSON file** because:

1. **Hierarchical Structure**: JSON naturally represents nested relationships
2. **API-Ready**: Single endpoint format for web services/dashboards
3. **Complete Context**: Metadata and both analyses in one queryable document
4. **Self-Documenting**: Includes question text and summary statistics

#### analysis_results.json Structure

```json
{
  "metadata": {
    "analysis_date": "2025-10-23",
    "total_homicides_analyzed": 1650,
    "years_analyzed": [2019, 2020, 2021, 2022, 2023]
  },
  "question_1": {
    "question": "Which police districts have the worst...",
    "districts": [
      {
        "district": "Eastern",
        "total_homicides": 245,
        "closed_cases": 68,
        "open_cases": 177,
        "closure_rate_percent": 27.8,
        "priority_level": "HIGH"
      }
    ],
    "summary": {
      "critical_districts": 3,
      "total_open_critical_cases": 456,
      "estimated_detectives_needed": 9
    }
  },
  "question_2": {
    "question": "What are the seasonal and monthly patterns...",
    "monthly_patterns": [
      {
        "month_number": 1,
        "month_name": "January",
        "average_homicides": 24.5,
        "percent_of_annual_average": 89.2,
        "deployment_level": "REDUCED"
      }
    ],
    "seasonal_summary": {
      "summer_vs_winter_increase_percent": 42.3,
      "peak_season": "Summer (June-August)",
      "lowest_season": "Winter (December-February)"
    }
  }
}
```

**Design Decisions:**
- **Top-level metadata**: Analysis context for data freshness validation
- **Separate question objects**: Easy to query specific analyses
- **Nested summaries**: Key metrics at both detail and aggregate levels
- **Consistent naming**: snake_case for all keys (JSON convention)
- **Type preservation**: Numbers as numbers (not strings) for mathematical operations
- **Human-readable labels**: Full question text and month names included

### Why These Formats Work for Future Reporting

1. **CSV for Business Analysts**
   - Direct Excel/Tableau import
   - Easy pivot tables and charts
   - Familiar format for non-technical stakeholders

2. **JSON for Developers**
   - Web dashboard integration
   - API responses for real-time queries
   - Database ingestion (MongoDB, PostgreSQL JSONB)
   - Machine learning pipeline input

3. **Interoperability**
   - Both formats use consistent data types
   - Field names match between formats
   - Easy to convert between formats if needed

## Technical Implementation

### Libraries Used
- **Native Scala/Java only** (as required)
- `java.io.PrintWriter`: File writing
- `java.io.File`: File handling
- `scala.util.Try`: Error handling
- No external JSON/CSV libraries

### Output File Generation
Files are written to the **current working directory** where run.sh is executed. The Docker container mounts this directory as a volume to make files accessible on the host.

## File Structure

```
project5/
├── BaltimoreHomicideAnalysis.scala  # Main program with multi-format output
├── Dockerfile                        # Container configuration
├── run.sh                           # Execution script with flag support
├── README.md                        # This file
└── output/ (generated)
    ├── district_analysis.csv        # (if --output=csv)
    ├── temporal_analysis.csv        # (if --output=csv)
    └── analysis_results.json        # (if --output=json)
```

## Testing

```bash
# Test all three modes
./run.sh                    # Should print to console
./run.sh --output=csv       # Should create 2 CSV files
./run.sh --output=json      # Should create 1 JSON file

# Verify CSV files
head -5 district_analysis.csv
head -5 temporal_analysis.csv

# Verify JSON structure
cat analysis_results.json
```

## Grading Compliance

✅ **Git Submission**: Project in class GitHub  
✅ **Docker Containerization**: Fully containerized  
✅ **Working Program**: All three output modes functional  
✅ **Parameter Passing**: Flags passed from run.sh to Scala via Docker  
✅ **Native Libraries**: Only Scala/Java standard library  
✅ **Format Documentation**: Complete README with rationale  
✅ **Default Behavior**: No flag = stdout (backward compatible with Project 4)  

## Contact

For questions or issues:
- GitHub: https://github.com/B3nterprise/project5

---

**Data Format Philosophy**: *"CSV for humans with spreadsheets, JSON for machines with APIs, STDOUT for humans at terminals."*