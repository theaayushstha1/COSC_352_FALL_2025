# Project 3 - Batch Table Extractor

## Description
Bash script that processes multiple webpages and extracts HTML tables to CSV files using the Docker container from Project 2.

## Files
- run_table_extractor.sh - Main bash script

## Usage
./run_table_extractor.sh "url1,url2,url3"

## Example
./run_table_extractor.sh "https://en.wikipedia.org/wiki/Comparison_of_programming_languages,https://en.wikipedia.org/wiki/List_of_countries_by_population"

## Output
- Creates timestamped directory with CSV files
- Files named by domain
- Generates zip file of all results

## Requirements
- Docker
- Project 2 Docker image (auto-builds if missing)
