# Project 5: Crime Data Analysis with Multiple Output Formats

## Overview
This project extends Project 4 by adding support for multiple output formats (CSV and JSON) in addition to the default stdout output. The application can now export crime data analysis results in standardized formats for integration with other reporting systems.

## Features
- **Multiple Output Formats**: stdout (default), CSV, and JSON
- **Command-line Flag Support**: Easy switching between formats
- **Structured Data Export**: Properly formatted and escaped output
- **Dockerized**: Fully containerized for consistent execution

## Output Format Details

### 1. STDOUT (Default)
**When to use**: Quick analysis, terminal viewing, debugging

**Format**: Human-readable text with formatted statistics
- Total record count
- Top 10 crime types with counts
- Arrest statistics and rates
- District-level analysis
- Domestic incident statistics

**Example**:
```
=== Crime Data Summary ===

Total Records: 50,000

--- Top 10 Crime Types ---
THEFT                         : 15,234
BATTERY                       : 12,456
...
```

### 2. CSV Format
**When to use**: Excel analysis, database imports, spreadsheet applications

**Format**: Standard comma-separated values with header row
- **Header Row**: Contains all field names
- **Escaping**: Fields with commas, quotes, or newlines are properly quoted
- **Boolean Values**: Represented as `true` or `false`
- **Empty Fields**: Preserved as empty strings between commas

**File Location**: `output/crime_report.csv`

**Schema**:
```
ID,Case Number,Date,Block,IUCR,Primary Type,Description,Location Description,
Arrest,Domestic,Beat,District,Ward,Community Area,FBI Code,X Coordinate,
Y Coordinate,Year,Updated On,Latitude,Longitude,Location
```

**Field Descriptions**:
- `ID`: Unique crime record identifier
- `Case Number`: Police case/report number
- `Date`: Date and time of incident
- `Block`: Street block where incident occurred
- `IUCR`: Illinois Uniform Crime Reporting code
- `Primary Type`: Main crime category
- `Description`: Detailed crime description
- `Location Description`: Type of location (street, residence, etc.)
- `Arrest`: Boolean indicating if arrest was made
- `Domestic`: Boolean indicating domestic-related incident
- `Beat`: Police beat number
- `District`: Police district number
- `Ward`: City ward number
- `Community Area`: Community area code
- `FBI Code`: FBI crime classification code
- `X Coordinate`: Illinois State Plane x-coordinate
- `Y Coordinate`: Illinois State Plane y-coordinate
- `Year`: Year of incident
- `Updated On`: Last update timestamp
- `Latitude`: Latitude coordinate
- `Longitude`: Longitude coordinate
- `Location`: Formatted location string (latitude, longitude)

**Design Rationale**:
- RFC 4180 compliant CSV format
- All original fields preserved for complete data fidelity
- Compatible with Excel, Google Sheets, pandas, R, and SQL imports
- Proper escaping prevents data corruption

### 3. JSON Format
**When to use**: APIs, web applications, NoSQL databases, JavaScript/Python processing

**Format**: Structured JSON with metadata and records array
```json
{
  "metadata": {
    "generated_at": "2025-10-24T10:30:00",
    "total_records": 50000,
    "format_version": "1.0"
  },
  "records": [
    {
      "id": "12345",
      "case_number": "JC123456",
      "date": "01/15/2024 03:30:00 PM",
      "block": "001XX N STATE ST",
      "iucr": "0460",
      "primary_type": "BATTERY",
      "description": "SIMPLE",
      "location_description": "STREET",
      "arrest": false,
      "domestic": false,
      "beat": "0123",
      "district": "001",
      "ward": "42",
      "community_area": "32",
      "fbi_code": "08B",
      "x_coordinate": "1176534",
      "y_coordinate": "1901234",
      "year": "2024",
      "updated_on": "02/01/2024 12:00:00 AM",
      "latitude": "41.8856",
      "longitude": "-87.6278",
      "location": "(41.8856, -87.6278)"
    }
  ]
}
```

**Structure**:
- **metadata**: Contains generation timestamp, record count, and format version
- **records**: Array of crime records with snake_case field names
- **Booleans**: Native JSON booleans (not strings)
- **Escaping**: Proper JSON string escaping for special characters

**Field Naming**: Uses snake_case for JavaScript/Python convention compatibility

**Design Rationale**:
- Self-documenting with metadata section
- Easy to parse in any modern programming language
- Compatible with MongoDB, PostgreSQL JSON columns, ElasticSearch
- Includes versioning for future format changes
- Native boolean types for proper data typing

## Usage

### Running Locally

#### 1. Build the application
```bash
chmod +x build.sh run.sh
./build.sh
```

#### 2. Run with different output formats

**Default (stdout)**:
```bash
./run.sh
```

**CSV output**:
```bash
./run.sh --output=csv
# Output written to: output/crime_report.csv
```

**JSON output**:
```bash
./run.sh --output=json
# Output written to: output/crime_report.json
```

### Running with Docker

#### 1. Build Docker image
```bash
docker build -t crime-analysis:project5 .
```

#### 2. Run with different formats

**Default (stdout)**:
```bash
docker run --rm \
  -v $(pwd)/data:/app/data \
  crime-analysis:project5
```

**CSV output**:
```bash
docker run --rm \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/output:/app/output \
  crime-analysis:project5 \
  ./run.sh --output=csv
```

**JSON output**:
```bash
docker run --rm \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/output:/app/output \
  crime-analysis:project5 \
  ./run.sh --output=json
```

## Project Structure
```
project5/
├── src/
│   └── main/
│       └── scala/
│           └── CrimeDataApp.scala
├── data/
│   └── crimes.csv              # Your crime data (not in git)
├── output/
│   ├── crime_report.csv        # Generated CSV output
│   └── crime_report.json       # Generated JSON output
├── target/
│   └── scala-2.13/
│       └── classes/            # Compiled .class files
├── build.sh
├── run.sh
├── Dockerfile
├── .gitignore
└── README.md
```

## Data Requirements

### Input File
- **Location**: `data/crimes.csv`
- **Format**: CSV with header row
- **Required Columns**: ID, Case Number, Date, Block, IUCR, Primary Type, Description, Location Description, Arrest, Domestic, Beat, District, Ward, Community Area, FBI Code, X Coordinate, Y Coordinate, Year, Updated On, Latitude, Longitude, Location

### Output Files
- **CSV**: `output/crime_report.csv`
- **JSON**: `output/crime_report.json`

## Format Selection Guide

| Use Case | Recommended Format |
|----------|-------------------|
| Quick analysis | stdout |
| Excel/Spreadsheet | CSV |
| Database import | CSV |
| Web API | JSON |
| Python/Pandas | CSV or JSON |
| JavaScript app | JSON |
| R analysis | CSV |
| MongoDB | JSON |
| SQL database | CSV |

## Dependencies
- Scala 2.13+
- JVM 11+
- Docker (for containerized execution)

## Notes
- The `data/` and `output/` directories are excluded from git (see `.gitignore`)
- CSV format follows RFC 4180 standard
- JSON format uses snake_case for field names (JavaScript/Python convention)
- All string fields are properly escaped in both formats
- Output files are overwritten on each run

## Future Enhancements
- XML output format
- Database direct connection
- Streaming output for large datasets
- Compressed output (gzip)
- Summary statistics in separate file

## Author
[Tehya Purifoy]

## Course
[COSC 352]

## Date
October 24, 2025
