# Project 8 — OCaml Functional Analytics on Baltimore Homicides

## Dataset
We use `baltimore_homicides_combined.csv` from the class repository.

## Analyses
1. **Homicides per year** — counts incidents by year and prints as `year,count`.
2. **Top 5 address blocks by incidence** — ranks street-level locations by incident count and prints as `address,count`.

## Functional Design
- Immutable record type `homicide`.
- Pure functions for parsing and analysis.
- Uses `map`, `filter_map`, `fold_left`, recursion, and pattern matching.
- All I/O confined to `main` for reading the CSV and printing results.

## How to Run (Docker)
1. Place the CSV at `data/baltimore_homicides_combined.csv`.
2. Build:
   ```bash
   docker build -t project8-analytics .
