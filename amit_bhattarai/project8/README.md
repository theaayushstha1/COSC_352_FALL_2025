# Project 8 – Functional Programming (Clojure)
**COSC 352 — Fall 2025**  
**Author: Amit Bhattarai**

## Overview
This project analyzes the Baltimore Homicides dataset using **pure functional programming** in Clojure. A custom `Homicide` record type is used to model each row of the CSV, and all analysis logic is implemented using immutable data, recursion, map, and reduce, with **no I/O inside the analysis functions**.

## Analyses Implemented
### 1. Homicides Per Year  
Uses `reduce` to count homicides for each year.  
**Results:**  
2020–2025 show a downward trend (348 → 147).

### 2. Top 5 Address Blocks  
Counts homicides by the “Address Block Found” field. Missing or blank values are normalized to **"Unknown Address"**.  
**Results:**  
Unknown Address (86), Edmondson Ave, Montford Ave, Fairlawn Ave, Park Heights Ave.

### Additional Functional Requirement  
A recursive function (`count-recursive`) is used to compute the total homicide count (1695), demonstrating explicit recursion as required.

## Functional Programming Features
- **Record type:** `Homicide`  
- **Pure functions:** all analysis logic  
- **map:** parsing rows  
- **reduce:** aggregations  
- **recursion:** total count  
- **pattern matching:** address cleanup via `case`  
- **immutability:** default Clojure data  

## How to Run
### Local:
```bash
clj -M:run
Docker:
docker build -t project8 .
docker run project8
Interesting Findings
Homicides decline each year from 2020–2025.
Many entries have missing addresses, shown as "Unknown Address".
Several specific address blocks repeat often, suggesting hotspots.
