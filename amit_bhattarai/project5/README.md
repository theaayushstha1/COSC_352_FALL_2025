# Project 5 — Scala + Docker: Multi-format Output (2020–2025)

**Author:** Amit Bhattarai

## Overview
Continuation of Project 4.  
This version adds support for exporting homicide data into structured **CSV** and **JSON** formats.

## Run Instructions

| Command | Description |
|----------|--------------|
| `./run.sh` | Default — prints to stdout |
| `./run.sh --output=csv` | Writes `output.csv` in CSV format |
| `./run.sh --output=json` | Writes `output.json` in JSON format |

### Output Fields
| Field | Meaning |
|--------|----------|
| `year` | Year (2020–2025) |
| `under18` | Victims aged 18 or younger |
| `total` | Total homicide victims |

**Notes**
- Uses native Scala/Java libraries only (no external JSON/CSV libs).  
- Dockerized for reproducible builds.  
- Based on Project 4's logic for consistent data.

