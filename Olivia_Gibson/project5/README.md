# Project 5: Homicide Analysis Output Formats

This project extends Project 4 by supporting structured output formats for downstream reporting.

## Supported Formats

- **stdout** (default): Human-readable console output
- **csv**: Saved to `output.csv`, with columns: Question, Year, Age, History
- **json**: Saved to `output.json`, with each record as a JSON object

## Usage

```bash
./run.sh --output=csv
./run.sh --output=json
./run.sh
