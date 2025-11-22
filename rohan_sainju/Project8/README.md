# Project 8: Functional Programming Analysis of Baltimore Homicides

## Author
Rohan Sainju

## Language
Haskell

## Analyses Performed

1. **Homicides Per Year**: Aggregates total homicides by year and displays trends over time
2. **Top 10 Neighborhoods**: Identifies the neighborhoods with the highest homicide counts

## How to Run

### Using Docker (Recommended)
```bash
docker build -t project8 .
docker run project8
```

### Local Development (if Haskell installed)
```bash
cabal update
cabal build
cabal run project8
```

## Key Functional Programming Concepts Used

- **Immutable data structures**: All homicide records are immutable
- **Pure functions**: All analysis logic in `Analysis.hs` is pure (no side effects)
- **Map/Filter/Fold**: Used `map` for transformations and `Map.fromListWith` for aggregation
- **Pattern matching**: Used in CSV parsing
- **Type safety**: Strong typing with custom `Homicide` data type

## Findings

After analyzing 1,695 homicide records from the Baltimore dataset:

### Analysis 1: Homicides Per Year
- **Peak year**: 2022 with 353 homicides
- **Trend**: Generally high from 2020-2022 (~350 per year), then declining
- 2023 saw a decrease to 279 homicides
- 2024 had 224 homicides (continuing downward trend)
- 2025 data is partial (147 so far)

### Analysis 2: Top Address Blocks
- **Most affected location**: 2800 Edmondson Avenue with 7 homicides
- Several locations had 5-6 incidents each
- Top 10 addresses account for a small fraction of total homicides, suggesting incidents are widely distributed across the city
- Notable hotspots include North Montford Avenue, Fairlawn Avenue, and Park Heights Avenue