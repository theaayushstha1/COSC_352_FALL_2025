# Project 6: Baltimore Homicide Analysis (Go Implementation)

## Overview
This is a Go port of the Baltimore Homicide Analysis project originally written in Scala. The application fetches homicide data from Baltimore crime blogs, analyzes the statistics, and outputs results in various formats.

## Quick Start

```bash
# Make run script executable
chmod +x run.sh

# Run analysis (console output)
./run.sh

# Generate JSON output
./run.sh --output=json

# Generate CSV output
./run.sh --output=csv