# Project 6: Baltimore Homicide Analysis with GoLang

## Overview
The project analyzes Baltimore City homicide statistics by fetching data from a public website, processing it using Python, and performing statistical analysis using **Go (GoLang)** in a Docker container. This is a port of Project 5, which used Scala for the analysis component.

## How to Run
1) Make the script executable: 
```bash
    chmod +x run.sh
```
2) Run the project: 
```bash
    ./run.sh --output=csv
```
   
   Output options:
   - `./run.sh` - stdout (default)
   - `./run.sh --output=csv` - CSV file output
   - `./run.sh --output=json` - JSON file output

## Project Components

### fetch_csv.py --> Python Script
Fetches and parses homicide data from the webpage
- Parses https://chamspage.blogspot.com/ using HTMLParser in Python 
- Extracts the table data from the HTML, includes all 9 columns
- Saves the data in `chamspage_table1.csv`
- Connected to `requirements.txt` file for the imported Python libraries used

### homicide_analysis.go --> Go Script
Analyzes the CSV data and answers key questions
- Reads `chamspage_table1.csv` and parses the CSV using Go's `encoding/csv` package
- Analyzes the data to answer the two questions:
        
    **Question 1: What address blocks have the most repeated homicides?**
    - Groups homicides by location using Go maps
    - Identifies dangerous hotspots
    - Shows detailed breakdown of top locations
    - **WHY?** → Helps allocate police resources to high risk areas
        
    **Question 2: Which months have the highest homicide rates?**
    - Extracts month from date field using `strings.Split()`
    - Counts homicides in the top months
    - Gives a sample of the victims within the top month
    - **WHY?** → Enables seasonal resource planning and prevention strategies

### go.mod --> Go Module File
Defines the Go module for dependency management
- Specifies module name: `homicide_analysis`
- Specifies Go version: `1.21`
- Required for Go's module system (Go 1.11+)

### Dockerfile 
Creates a containerized environment to run the Go program
- Uses `golang:1.21` as base image
- Copies Go source code and CSV data
- Compiles the Go program using `go build`
- Runs the compiled binary
- Outputs analysis in specified format (stdout/csv/json)

### run.sh --> #!/bin/bash Script
Orchestrates the entire workflow
- Checks if `chamspage_table1.csv` exists
    - If not, runs `fetch_csv.py` to generate it 
- Verifies if CSV was created 
- Checks if Docker image exists 
    - If not, builds the Docker image
- Runs the Go analysis inside the Docker container with the specified output format
