# Baltimore Homicides Functional Analysis

**COSC 352 - Functional Programming Assignment**  
**Student:** Kyndal Maclin

## Overview

This project analyzes Baltimore homicide data using pure functional programming principles in Haskell. The program reads CSV data and performs two distinct analyses on the dataset.

## Chosen Analyses

### 1. Monthly Trend Analysis
Analyzes the distribution of homicides across months in 2020, showing:
- Number of homicides per month
- Percentage distribution
- Temporal patterns throughout the year

### 2. Weapon Type Distribution
Categorizes homicides by weapon type extracted from incident notes:
- Shooting incidents
- Stabbing incidents
- Blunt force trauma
- Other weapon types
- Includes visual bar chart representation

## Technical Implementation

### Functional Programming Features Used

**Pure Functions:**
- All analysis logic uses pure functions with no side effects
- `analyzeByMonth`: Groups homicides by month using pattern matching
- `analyzeByWeaponType`: Categorizes incidents using text pattern matching
- `extractWeaponType`: Parses weapon information from notes field

**Immutable Data:**
- All data structures are immutable
- Custom data types: `Homicide`, `MonthCount`, `WeaponType`

**Higher-Order Functions:**
- `map`: Transform data (extract months, weapon types)
- `filter`: Select relevant data via `mapMaybe`, `catMaybes`
- `fold/reduce`: Implemented through `group` and `sort` for aggregation
- List comprehensions for data processing

**No Mutation or I/O in Analysis:**
- All I/O confined to `main` function
- Analysis functions are pure and testable
- Pattern matching for CSV parsing

## File Structure

```
project8/
├── HomicideAnalyzer.hs              # Main Haskell source code
├── baltimore_homicides_combined.csv  # Dataset (download from GitHub)
├── Dockerfile                        # Container configuration
└── README.md                         # This file
```

## How to Run

### Prerequisites
- Docker installed on your system
- Baltimore homicides CSV file in the project directory

### Step 1: Download the CSV
Download `baltimore_homicides_combined.csv` from:
```
https://github.com/professor-jon-white/COSC_352_FALL_2025/blob/be5df82c2e4aea13f2becf14f11fab1eac549baa/professor_jon_white/func_prog/baltimore_homicides_combined.csv
```

Place it in the same directory as `HomicideAnalyzer.hs`

### Step 2: Build the Docker Image
```bash
docker build -t homicide-analyzer .
```

### Step 3: Run the Analysis
```bash
docker run homicide-analyzer
```

## Expected Output

The program will display:

1. **Monthly Analysis:**
   - Breakdown of homicides by month
   - Percentage of total for each month
   - Total count

2. **Weapon Type Analysis:**
   - Distribution by weapon category
   - Percentage and count for each type
   - Visual bar chart
   - Total count

## Key Findings

Based on the sample data:

### Monthly Patterns
- Homicides show seasonal variation
- Peak months can be identified for resource allocation
- Year-round data provides comprehensive view

### Weapon Type Distribution
- **Shootings** dominate the dataset (majority of incidents)
- **Stabbings** represent second most common method
- Other methods (blunt force, fire, strangulation) are less frequent
- This information is critical for:
  - Law enforcement strategy
  - Public health interventions
  - Gun violence prevention programs

## Functional Programming Principles

This implementation strictly adheres to functional programming requirements:

**Pattern Matching**: Used for CSV parsing and data extraction  
**Type Definitions**: Custom algebraic data types for domain modeling  
**Immutable Data**: No mutable state anywhere in the program  
**Pure Functions**: All analysis logic is referentially transparent  
**Higher-Order Functions**: map, filter, fold operations throughout  
**Recursion**: Implicit in list processing functions  
**No I/O in Logic**: File operations only in main, analysis is pure  

## Language Choice: Haskell

Haskell was chosen because:
- Strong static typing catches errors at compile time
- Lazy evaluation for efficient data processing
- Excellent support for functional programming patterns
- Rich ecosystem for text processing and data analysis
- Pure functional approach enforced by the language

## Author
Kyndal Maclin  
COSC 352 - Fall 2025
