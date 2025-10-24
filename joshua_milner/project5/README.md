# Baltimore Homicide Analysis System (Now Supports Multi-Format Outputs)

## Overview
This project analyzes Baltimore City homicide statistics to provide actionable insights for law enforcement resource allocation and case investigation strategies.

## New Features
- **Multiple output formats**: stdout (terminal), CSV, JSON
- **Command-line flag support**: `--output=<format>`
- **Structured data models**: Consistent data representation across formats
- **File output**: Results saved to `output/` directory

## Data Source
- **URL**: https://chamspage.blogspot.com/
- **Content**: Comprehensive Baltimore homicide records including date, time, victim demographics, location, case disposition, and weapon type

## Analysis Questions

### Question 1: Seasonal Homicide Patterns
**Purpose**: Identify months with highest homicide rates to optimize police staffing and patrol schedules.

**Method**: Group homicides by month and calculate frequency distribution.

**Value**: Enables predictive resource allocation during high-crime periods.

### Question 2: Weapon-Specific Clearance Rates
**Purpose**: Determine which weapon types present the greatest investigation challenges.

**Method**: Calculate case clearance rates (closed/total) for each weapon category.

**Value**: Helps prioritize detective training and forensic resource investment.

## Requirements
- Docker
- Bash shell (Linux/Mac) or Git Bash (Windows)

## Installation & Execution

### Quick Start
```bash
cd project4
./run.sh
```

That's it and The script will:
1. Check if Docker is installed and running
2. Build the Docker image if it doesn't exist
3. Run the analysis
4. Display results

## Output Formats

### CSV Format
```bash
./run.sh --output=csv
```
Creates `output/analysis_results.csv` with:
- Metadata section (date, total records)
- Question 1: Monthly homicide data in tabular format
- Question 2: Weapon type analysis with clearance rates
- Key insights for each question

**Use case**: Import into Excel, Google Sheets, or databases for further analysis.

### JSON Format
```bash
./run.sh --output=json
```
Creates `output/analysis_results.json` with:
- Hierarchical structure
- Full analysis results
- Machine-readable format

**Use case**: API integration, web dashboards, automated reporting systems.

### Terminal Output (Default)
```bash
./run.sh
```
Displays formatted analysis directly in terminal.

### Manual Docker Commands

**Build the image:**
```bash
docker build -t baltimore-homicide-analysis .
```

**Run the analysis:**
```bash
docker run --rm baltimore-homicide-analysis
```

## Project Structure
```
project4/
├── Dockerfile                          # Container configuration
├── run.sh                             # Automated execution script
├── src/
│   └── main/
│       └── scala/
│           └── BaltimoreHomicideAnalysis.scala  # Main analysis program
└── README.md                          # This file
```

## Technical Details

### Language & Runtime
- **Language**: Scala 2.13
- **Runtime**: JVM (Java Virtual Machine)
- **Libraries**: Native Scala standard library only

### Docker Configuration
- **Base Image**: hseeberger/scala-sbt (or OpenJDK + Scala)
- **Compilation**: Uses `scalac` to compile Scala source
- **Execution**: Runs compiled bytecode via `scala` command

### Data Processing Approach
1. **Fetch**: HTTP request to source URL
2. **Parse**: Extract HTML table data
3. **Transform**: Convert to structured case classes
4. **Analyze**: Apply functional transformations (map, filter, groupBy)
5. **Report**: Generate formatted output

[Joshua Milner]

- Project 4 -