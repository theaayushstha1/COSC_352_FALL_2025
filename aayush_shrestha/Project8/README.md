# Baltimore Homicides Functional Programming Analysis (Haskell)

**Student Name:** Aayush Shrestha

## Data & Setup

This tool analyzes homicides from `baltimore_homicides_combined.csv` using a purely functional Haskell approach.  
It automatically detects the correct columns ("year" and "Notes") for robust analysis, so you never need to hard-code column positions.


## Chosen Analyses

1. **Homicides per Year:**  
   Counts all incidents, grouped and sorted by year.
2. **Weapon-Type Distribution:**  
   Categorizes incidents by weapon keywords in each record’s "Notes" field ("Firearm", "Knife", "Blunt Force", "Unknown", "Other").



## Functional Design

- **Immutable record type** for each homicide
- All analysis (counting, grouping, categorization) performed using pure Haskell functions:
  - `map`, `groupBy`, `sortOn`, higher-order filtering
  - No mutation, I/O, or state inside analysis code
- The main function only handles I/O; analysis is separate/pure
- No external dependencies or cabal required (uses only base libraries)


## How to Run

1. Build the Docker image from your project folder:
docker build -t baltimore_homicide_analysis .


2. Run the container:
docker run --rm baltimore_homicide_analysis



## Interesting Findings

- Firearms are by far the most common weapon in Baltimore homicide incidents.
- The tool reveals yearly trends (peaks and valleys) in homicide rates.
- Classification is robust to field order and unexpected columns due to header detection.

