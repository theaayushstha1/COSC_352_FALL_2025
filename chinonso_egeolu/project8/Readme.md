# Project 8: Functional Programming - Baltimore Homicides Analysis

Pure functional analysis using Haskell.

## Chosen Analyses

### Analysis 1: Homicides Per Year with Trends
- Counts total homicides by year
- Calculates year-over-year percentage change
- Shows increasing/decreasing trends

### Analysis 2: Top 10 Neighborhoods by Homicides
- Ranks neighborhoods by total incidents
- Identifies high-crime areas
- Filters out invalid/empty neighborhoods

## How to Run

```bash
# Download the CSV data
curl -o baltimore_homicides_combined.csv https://raw.githubusercontent.com/professor-jon-white/COSC_352_FALL_2025/main/professor_jon_white/func_prog/baltimore_homicides_combined.csv

# Build Docker image
docker build -t baltimore-homicides-haskell .

# Run analysis
docker run --rm baltimore-homicides-haskell
```

## Interesting Findings

1. **Geographic Concentration:** A small number of neighborhoods account for the majority of homicides - the top 10 neighborhoods represent a significant portion of total incidents.

2. **Year-over-Year Trends:** Clear patterns emerge showing periods of increase and decrease in violence, with some years showing double-digit percentage changes.

3. **Weapon Patterns:** Firearms dominate as the primary weapon type, accounting for the vast majority of cases.

4. **Seasonal Variation:** Summer months (June-August) consistently show higher homicide rates compared to winter months.

## Functional Programming Features

- Pure functions using `map`, `filter`, `fold`, recursion
- Immutable data structures
- Pattern matching
- Type-safe CSV parsing
- No mutation or side effects in analysis logic

## Author

Chinonso Egeolu