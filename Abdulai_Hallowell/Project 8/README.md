# Baltimore Homicides Analyzer (Haskell)

Minimal Haskell app that parses `baltimore_homicides_combined.csv`, converts rows into a `Homicide` record, and reports homicides per year and the top 5 neighborhoods (address clusters). Analysis functions are pure and rely only on map/filter/fold/explicit recursion.

## Project layout
- `app/Main.hs` — loads the CSV, parses rows, prints summaries.
- `src/Types.hs` — `Homicide` record definition.
- `src/CsvParser.hs` — recursive CSV parser and row-to-record conversion.
- `src/Analysis.hs` — pure analysis functions.
- `baltimore-homicides.cabal` — cabal config.
- `Dockerfile` — containerized build/run.

## Build and run (cabal)
```bash
cabal build
cabal run baltimore-homicides
```

## Build and run (Docker)
```bash
docker build -t baltimore-homicides .
docker run --rm baltimore-homicides
```

## CSV expectations
The CSV must have 13 columns (matching the provided file): case number, date died, name, age, address block, notes, victim history, surveillance camera, case closed, source page, year, latitude, longitude. Rows with invalid year/case number are reported as errors and skipped.

## Notes
- Analyses are pure (no I/O, no mutation) and use only map/filter/fold/recursion per requirements.
- The CSV parser handles quoted fields and escaped quotes (`""` inside quoted fields).
