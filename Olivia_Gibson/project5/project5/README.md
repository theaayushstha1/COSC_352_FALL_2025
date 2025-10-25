# Project 5: Baltimore Homicide Analysis (2024)

This project analyzes homicide data from Baltimore in 2024 using Scala and Docker. It filters victims based on age and criminal history, and outputs results in multiple formats.

## 🔧 Setup

Make sure you have Docker installed and running. This project is tested using Git Bash on Windows.

## 📂 Data

Input file: `data/homicides.csv`  
Expected format: CSV with columns `year, age, criminalHistory`

## 🚀 Usage

Run the analysis using the provided script:

```bash
./run.sh --output=json   # writes results to output.json
./run.sh --output=csv    # writes results to output.csv
./run.sh                 # prints results to stdout
