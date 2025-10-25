# Project 5: Baltimore Homicide Statistics Analysis

## Overview
This project is a continuation of Project 4. It analyzes Baltimore City homicide data for 2025 from the specified blog page. It answers two questions via stdout by default:
1. How many homicides occurred in each month of 2025?
2. What is the closure rate for incidents with and without surveillance cameras in 2025?

Additionally, it supports outputting the parsed homicide data in CSV or JSON formats for use in future reports, via the --output flag.

The analysis is performed using a Scala program that fetches and parses the HTML content, extracts relevant entries for 2025, and computes the required statistics or outputs structured data.

## Requirements
- Docker must be installed and running.
- The project uses only native Scala and Java libraries.

## Files
- `Project5.scala`: The Scala source code for fetching, parsing, analyzing, and outputting the data.
- `Dockerfile`: Defines the Docker image for building and running the Scala program.
- `run.sh`: Shell script to build the Docker image and run the container, passing any arguments (e.g., --output=csv).
- `README.md`: This file.

## How to Run
1. Ensure you are in the project directory.
2. Make `run.sh` executable if necessary: `chmod +x run.sh`.
3. Execute `./run.sh` for default stdout output (question answers).
4. For structured output:
   - `./run.sh --output=csv`: Writes parsed data to `data.csv` in the current directory.
   - `./run.sh --output=json`: Writes parsed data to `data.json` in the current directory.

The script will build the Docker image and run the container, producing either stdout or files as specified.

## Data Format Explanation
When using `--output=csv` or `--output=json`, the program outputs the parsed homicide entries in a structured format instead of the question answers. This was chosen to provide the raw crime data in a standardized, machine-readable way suitable for aggregation into reports, as hinted in the project guidelines. The format captures key structured fields while preserving the full descriptive text for comprehensive analysis.

### CSV Format (data.csv)
- **Headers**: number,date,month,hasCamera,isClosed,description
- **Fields**:
  - `number`: String, the homicide case number (e.g., "001").
  - `date`: String, the date of the incident in MM/DD/25 format.
  - `month`: Integer (1-12), extracted from the date for easy grouping.
  - `hasCamera`: Boolean (true/false), true if the entry mentions surveillance cameras (e.g., "1 camera").
  - `isClosed`: Boolean (true/false), true if the entry indicates the case is "Closed".
  - `description`: String, the full remaining text of the entry, including victim name, age, location, cause, updates, suspects, motives, and other notes. This may contain commas or quotes, which are properly escaped/quoted in the CSV.
- **Why this format?**: It balances structure (for querying/filtering on month, cameras, closure) with flexibility (full description for qualitative insights). CSV is widely supported for import into spreadsheets or data tools like pandas, enabling easy combination with other datasets for city-wide reports. Fields like month/hasCamera/isClosed directly support recomputing the project's question answers.

### JSON Format (data.json)
- **Structure**: An array of objects, where each object represents a homicide entry with the same fields as above:
  ```json
  [
    {
      "number": "001",
      "date": "01/09/25",
      "month": 1,
      "hasCamera": false,
      "isClosed": false,
      "description": "Richie Briggs 36 5900 Dawalt Avenue Shooting victim"
    },
    ...
  ]
