# Project 5 - Multi-format Output

This project extends Project 4 by adding support for multiple output formats.

## How to Run

Default (stdout):
./run.sh

CSV format:
./run.sh --output=csv
→ Creates `output.csv`

JSON format:
./run.sh --output=json
→ Creates `output.json`

## Data Format
- **CSV:** Comma-separated, includes header row.
- **JSON:** Array of objects with fields matching homicide record attributes.
- **stdout:** Summary statistics printed directly to console.
