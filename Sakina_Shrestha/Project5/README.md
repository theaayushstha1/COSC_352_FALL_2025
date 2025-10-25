
# Project 5 — Sakina Shrestha 

## Overview

This project extends Project 4 by adding **CSV and JSON output formats** in addition to the default stdout analytics display. The Scala program fetches Baltimore homicide data from chamspage and can output in three different formats based on command-line flags.


## Questions Answered

The default stdout output provides analytics for two research questions:

### Q1: How do case closure rates differ when a surveillance camera is present versus absent at the intersection?

**Sample Results:**
- WITH camera: count=23 closed=9 rate=39.13% avgAge=35.17
- WITHOUT camera: count=77 closed=25 rate=32.47% avgAge=35.39
- Insight: Presence of cameras corresponds to a 6.66% absolute difference in closure rate.

### Q2: What are closure rates by likely cause inferred from Notes (Shooting vs Stabbing vs Other)?

**Sample Results:**
- Blunt Force: count=1 closed=1 rate=100.00% avgAge=43.0
- Other: count=13 closed=2 rate=15.38% avgAge=44.69
- Shooting: count=77 closed=25 rate=32.47% avgAge=32.83
- Stabbing: count=9 closed=6 rate=66.67% avgAge=42.22
- Insight: Highest closure rate category = Blunt Force at 100.00%; lowest = Other at 15.38%.

*Note: Numbers vary as the data source updates over time.*

## Quickstart

### Prerequisites
- Docker installed
- Terminal/Command line access

### Usage

From this folder (contains `Dockerfile`, `Baltimore.scala`, and `run.sh`):

#### 1. Default Analytics Output (stdout)
```
./run.sh
```
Displays analytics questions and answers in terminal.

#### 2. Generate CSV File
```
./run.sh --output=csv
```
Creates `output.csv` in the current directory with all homicide records.

#### 3. Generate JSON File
```
./run.sh --output=json
```
Creates `output.json` in the current directory with all homicide records.

### Build Docker Image Manually (Optional)
```
docker build -t baltimore .
```
The `run.sh` script automatically builds the image if it doesn't exist.
