# Project 5: Crime Data Formatter

## Overview
This project builds on Project 4 by adding support for exporting crime data in standardized formats: CSV and JSON. These formats are widely used in data analysis and reporting workflows, making it easier to integrate with downstream tools.

## Format Decisions

### CSV
- Chosen for compatibility with Excel, Google Sheets, and other tabular data tools.
- Each row represents a single crime record.
- The first row contains headers: `date`, `type`, `location`.
- Values are comma-separated and plain text for easy parsing.

### JSON
- Chosen for structured data exchange, especially in web APIs and applications.
- Each crime record is a JSON object with keys: `date`, `type`, `location`.
- All records are wrapped in a JSON array for consistency.

### stdout
- Retained as the default for quick inspection and debugging.
- Prints each record in a readable format: `date: ..., type: ..., location: ...`.

## Usage

```bash
./run.sh --output=csv   # Writes to output.csv
./run.sh --output=json  # Writes to output.json
./run.sh                # Prints to terminal (stdout)
